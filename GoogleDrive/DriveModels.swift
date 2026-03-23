import Foundation

// MARK: - Google Drive API Response Models

struct DriveFile: Codable, Identifiable {
    let id: String
    let name: String
    let mimeType: String
    let size: String?
    let thumbnailLink: String?
    let webViewLink: String?
    let createdTime: Date?
    let modifiedTime: Date?

    var isFolder: Bool { mimeType == "application/vnd.google-apps.folder" }
    var isPDF: Bool { mimeType == "application/pdf" }

    var formattedSize: String {
        guard let size, let bytes = Int64(size) else { return "" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct DriveFileList: Codable {
    let files: [DriveFile]
    let nextPageToken: String?
}

struct DriveUploadResponse: Codable {
    let id: String
    let name: String
    let mimeType: String
    let webViewLink: String?
}

// MARK: - Google OAuth Token Response

struct GoogleTokenResponse: Codable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String?
    let token_type: String
    let scope: String?
}

// MARK: - Google Drive Errors

enum GoogleDriveError: LocalizedError {
    case notAuthenticated
    case tokenRefreshFailed
    case uploadFailed(String)
    case downloadFailed(String)
    case folderCreationFailed
    case networkError(Error)
    case authFlowCancelled

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: "Not connected to Google Drive"
        case .tokenRefreshFailed: "Failed to refresh Google Drive token"
        case .uploadFailed(let msg): "Upload failed: \(msg)"
        case .downloadFailed(let msg): "Download failed: \(msg)"
        case .folderCreationFailed: "Failed to create Drive folder"
        case .networkError(let err): "Network error: \(err.localizedDescription)"
        case .authFlowCancelled: "Google sign-in was cancelled"
        }
    }
}
