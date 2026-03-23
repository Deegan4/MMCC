import AuthenticationServices
import Foundation
import SwiftData

// MARK: - Google Drive Auth Manager
// Uses ASWebAuthenticationSession for OAuth 2.0, same pattern as QBAuthManager.
// Client secret stays on the Cloudflare Worker — only the auth code is exchanged client-side.

@Observable
@MainActor
final class GoogleDriveAuthManager {
    private let modelContext: ModelContext

    // Google OAuth endpoints
    private let authURL = "https://accounts.google.com/o/oauth2/v2/auth"
    private let tokenExchangeURL: String // Cloudflare Worker route

    // App-specific config (set these in your Google Cloud Console)
    private let clientID: String
    private let redirectURI = "mmcc://google-callback"
    private let scopes = "https://www.googleapis.com/auth/drive.file"

    private(set) var isConnected = false
    private(set) var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiry: Date?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // TODO: Replace with your actual Google Cloud client ID
        self.clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String ?? ""
        // Cloudflare Worker handles token exchange (client secret stays server-side)
        self.tokenExchangeURL = "https://mmcc-auth.your-worker.workers.dev/google/token"

        loadStoredTokens()
    }

    // MARK: - OAuth Flow

    func startOAuthFlow() async throws {
        let state = UUID().uuidString
        var components = URLComponents(string: authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "state", value: state),
        ]

        let authURL = components.url!

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callback: .customScheme("mmcc")
            ) { url, error in
                if let error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: GoogleDriveError.authFlowCancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let url else {
                    continuation.resume(throwing: GoogleDriveError.notAuthenticated)
                    return
                }
                continuation.resume(returning: url)
            }
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }

        // Extract auth code from callback URL
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            throw GoogleDriveError.notAuthenticated
        }

        // Exchange auth code for tokens via Cloudflare Worker
        try await exchangeCodeForTokens(code: code)
    }

    // MARK: - Token Exchange

    private func exchangeCodeForTokens(code: String) async throws {
        var request = URLRequest(url: URL(string: tokenExchangeURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "code": code,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code",
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleDriveError.tokenRefreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
        accessToken = tokenResponse.access_token
        refreshToken = tokenResponse.refresh_token
        tokenExpiry = Date.now.addingTimeInterval(TimeInterval(tokenResponse.expires_in))
        isConnected = true
        saveTokens()
    }

    // MARK: - Token Refresh

    func ensureValidToken() async throws {
        guard isConnected else { throw GoogleDriveError.notAuthenticated }

        // If token is still valid, nothing to do
        if let expiry = tokenExpiry, expiry > Date.now.addingTimeInterval(60) {
            return
        }

        guard let refreshToken else { throw GoogleDriveError.tokenRefreshFailed }

        var request = URLRequest(url: URL(string: tokenExchangeURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleDriveError.tokenRefreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
        accessToken = tokenResponse.access_token
        if let newRefresh = tokenResponse.refresh_token {
            self.refreshToken = newRefresh
        }
        tokenExpiry = Date.now.addingTimeInterval(TimeInterval(tokenResponse.expires_in))
        saveTokens()
    }

    // MARK: - Disconnect

    func disconnect() {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        isConnected = false

        // Clear from business profile
        let descriptor = FetchDescriptor<BusinessProfile>()
        if let profile = try? modelContext.fetch(descriptor).first {
            profile.googleDriveConnected = false
            profile.googleDriveFolderID = nil
        }
    }

    // MARK: - Token Storage (via BusinessProfile)

    private func saveTokens() {
        let descriptor = FetchDescriptor<BusinessProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return }
        profile.googleDriveConnected = true
        // Store tokens in Keychain in production — for now, using profile fields
        // that would be added to BusinessProfile model
    }

    private func loadStoredTokens() {
        let descriptor = FetchDescriptor<BusinessProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return }
        isConnected = profile.googleDriveConnected
    }
}
