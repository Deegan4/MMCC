import Foundation

// MARK: - QB API Errors

enum QBAPIError: LocalizedError {
    case rateLimited(retryAfter: TimeInterval)
    case serverError(statusCode: Int, body: String)
    case networkUnavailable
    case invalidResponse
    case qbError(code: String, message: String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case let .rateLimited(seconds): "Rate limited. Retry after \(Int(seconds)) seconds."
        case let .serverError(code, body): "Server error (\(code)): \(body)"
        case .networkUnavailable: "No internet connection."
        case .invalidResponse: "Invalid response from QuickBooks."
        case let .qbError(code, message): "QuickBooks error [\(code)]: \(message)"
        case .unauthorized: "Authorization failed."
        }
    }
}

// MARK: - QB Error Response

private struct QBFaultResponse: Codable {
    let Fault: QBFault?

    struct QBFault: Codable {
        let Error: [QBErrorDetail]?
    }

    struct QBErrorDetail: Codable {
        let Message: String?
        let code: String?
    }
}

// MARK: - QBAPIClient

actor QBAPIClient {
    private let authManager: QBAuthManager
    private let session: URLSession
    private let baseURL = "https://quickbooks.api.intuit.com/v3/company"

    init(authManager: QBAuthManager) {
        self.authManager = authManager
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    func get(path: String, realmID: String) async throws -> Data {
        let url = URL(string: "\(baseURL)/\(realmID)/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await executeRequest(request)
    }

    func post(path: String, realmID: String, body: Data) async throws -> Data {
        let url = URL(string: "\(baseURL)/\(realmID)/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = body
        return try await executeRequest(request)
    }

    func query(realmID: String, sql: String) async throws -> Data {
        guard let encoded = sql.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw QBAPIError.invalidResponse
        }
        let url = URL(string: "\(baseURL)/\(realmID)/query?query=\(encoded)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await executeRequest(request)
    }

    // MARK: - Request Execution

    private func executeRequest(_ request: URLRequest, isRetry: Bool = false) async throws -> Data {
        var authedRequest = request
        let token = try await authManager.validAccessToken()
        authedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: authedRequest)
        } catch {
            if (error as NSError).domain == NSURLErrorDomain {
                throw QBAPIError.networkUnavailable
            }
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QBAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200 ... 299:
            return data

        case 401:
            if !isRetry {
                // Force a token refresh and retry once
                _ = try await authManager.refreshTokenIfNeeded()
                return try await executeRequest(request, isRetry: true)
            }
            throw QBAPIError.unauthorized

        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap(TimeInterval.init) ?? 60
            throw QBAPIError.rateLimited(retryAfter: retryAfter)

        case 500 ... 599:
            let body = String(data: data, encoding: .utf8) ?? ""
            throw QBAPIError.serverError(statusCode: httpResponse.statusCode, body: body)

        default:
            // Try to parse Intuit error response
            if let fault = try? JSONDecoder().decode(QBFaultResponse.self, from: data),
               let firstError = fault.Fault?.Error?.first
            {
                throw QBAPIError.qbError(
                    code: firstError.code ?? "unknown",
                    message: firstError.Message ?? "Unknown error"
                )
            }
            let body = String(data: data, encoding: .utf8) ?? ""
            throw QBAPIError.serverError(statusCode: httpResponse.statusCode, body: body)
        }
    }
}
