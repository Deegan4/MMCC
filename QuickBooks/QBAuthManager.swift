import AuthenticationServices
import Foundation
import SwiftData

// MARK: - QB Auth Errors

enum QBAuthError: LocalizedError {
    case authFlowCancelled
    case authFlowFailed(String)
    case tokenExchangeFailed(String)
    case refreshFailed(String)
    case refreshTokenExpired
    case notConnected
    case noProfile

    var errorDescription: String? {
        switch self {
        case .authFlowCancelled: "Sign-in was cancelled."
        case let .authFlowFailed(msg): "Sign-in failed: \(msg)"
        case let .tokenExchangeFailed(msg): "Token exchange failed: \(msg)"
        case let .refreshFailed(msg): "Token refresh failed: \(msg)"
        case .refreshTokenExpired: "Your QuickBooks session has expired. Please reconnect."
        case .notConnected: "Not connected to QuickBooks."
        case .noProfile: "No business profile found."
        }
    }
}

// MARK: - Token Response

private struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let realmId: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case realmId
    }
}

// MARK: - QBAuthManager

@Observable
@MainActor
final class QBAuthManager {
    private(set) var isConnected = false
    private(set) var syncStatus: QBSyncStatus = .notConnected
    private(set) var lastError: String?

    private let modelContext: ModelContext

    // Configuration — clientID is public (safe on device), secret lives in Worker
    static let clientID = "YOUR_INTUIT_CLIENT_ID" // TODO: Replace with real client ID
    static let redirectURI = "mmcc://oauth-callback"
    static let workerBaseURL = "https://mmcc-qb.workers.dev" // TODO: Replace with deployed Worker URL
    private let scopes = "com.intuit.quickbooks.accounting"
    private let authBaseURL = "https://appcenter.intuit.com/connect/oauth2"
    private let tokenRefreshBuffer: TimeInterval = 300 // 5 minutes

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Load initial state from BusinessProfile
        if let profile = fetchProfile() {
            isConnected = profile.qbConnected
            syncStatus = profile.qbConnected ? .connected : .notConnected
        }
    }

    // MARK: - OAuth Flow

    func startOAuthFlow() async throws {
        let state = UUID().uuidString
        var components = URLComponents(string: authBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Self.clientID),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "state", value: state),
        ]

        guard let authURL = components.url else {
            throw QBAuthError.authFlowFailed("Could not build authorization URL.")
        }

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callback: .customScheme("mmcc")
            ) { url, error in
                if let error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: QBAuthError.authFlowCancelled)
                    } else {
                        continuation.resume(throwing: QBAuthError.authFlowFailed(error.localizedDescription))
                    }
                    return
                }
                guard let url else {
                    continuation.resume(throwing: QBAuthError.authFlowFailed("No callback URL received."))
                    return
                }
                continuation.resume(returning: url)
            }
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }

        // Parse callback: mmcc://oauth-callback?code=XXX&state=YYY&realmId=ZZZ
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let returnedState = components.queryItems?.first(where: { $0.name == "state" })?.value,
              returnedState == state
        else {
            throw QBAuthError.authFlowFailed("Invalid callback URL.")
        }

        let realmId = components.queryItems?.first(where: { $0.name == "realmId" })?.value

        // Exchange auth code for tokens via Cloudflare Worker
        let tokens = try await exchangeCode(code, realmId: realmId)
        try storeTokens(tokens)

        isConnected = true
        syncStatus = .connected
        lastError = nil
    }

    // MARK: - Token Management

    func validAccessToken() async throws -> String {
        try await refreshTokenIfNeeded()
    }

    func refreshTokenIfNeeded() async throws -> String {
        guard let profile = fetchProfile(), profile.qbConnected else {
            throw QBAuthError.notConnected
        }

        guard let accessToken = profile.qbAccessToken,
              let expiry = profile.qbTokenExpiry
        else {
            throw QBAuthError.notConnected
        }

        // If access token is still valid (with 5-minute buffer), return it
        if expiry.timeIntervalSinceNow > tokenRefreshBuffer {
            return accessToken
        }

        // Access token expired — try to refresh
        guard let refreshToken = profile.qbRefreshToken else {
            throw QBAuthError.refreshTokenExpired
        }

        let tokens = try await refreshTokens(refreshToken)
        try storeTokens(tokens)

        guard let newToken = fetchProfile()?.qbAccessToken else {
            throw QBAuthError.refreshFailed("Token not stored after refresh.")
        }
        return newToken
    }

    func disconnect() {
        guard let profile = fetchProfile() else { return }
        profile.qbConnected = false
        profile.qbAccessToken = nil
        profile.qbRefreshToken = nil
        profile.qbTokenExpiry = nil
        profile.qbRealmID = nil
        try? modelContext.save()

        isConnected = false
        syncStatus = .notConnected
        lastError = nil
    }

    var realmID: String? {
        fetchProfile()?.qbRealmID
    }

    // MARK: - Private Helpers

    private func exchangeCode(_ code: String, realmId: String?) async throws -> TokenResponse {
        let url = URL(string: "\(Self.workerBaseURL)/token/exchange")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: String] = [
            "code": code,
            "redirect_uri": Self.redirectURI,
        ]
        if let realmId { body["realmId"] = realmId }

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw QBAuthError.tokenExchangeFailed(body)
        }

        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func refreshTokens(_ refreshToken: String) async throws -> TokenResponse {
        let url = URL(string: "\(Self.workerBaseURL)/token/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            // If Intuit returns 401, the refresh token itself is expired
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                disconnect()
                throw QBAuthError.refreshTokenExpired
            }
            throw QBAuthError.refreshFailed(body)
        }

        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func storeTokens(_ tokens: TokenResponse) throws {
        guard let profile = fetchProfile() else {
            throw QBAuthError.noProfile
        }
        profile.qbAccessToken = tokens.accessToken
        profile.qbRefreshToken = tokens.refreshToken
        profile.qbTokenExpiry = Date.now.addingTimeInterval(TimeInterval(tokens.expiresIn))
        if let realmId = tokens.realmId {
            profile.qbRealmID = realmId
        }
        profile.qbConnected = true
        try? modelContext.save()
    }

    private func fetchProfile() -> BusinessProfile? {
        let descriptor = FetchDescriptor<BusinessProfile>()
        return try? modelContext.fetch(descriptor).first
    }
}
