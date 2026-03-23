import Foundation

// MARK: - Google Drive API Client
// REST API wrapper for Google Drive v3. No third-party SDK — keeps bundle lean.

@MainActor
final class GoogleDriveClient {
    private let authManager: GoogleDriveAuthManager
    private let baseURL = "https://www.googleapis.com/drive/v3"
    private let uploadURL = "https://www.googleapis.com/upload/drive/v3"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(authManager: GoogleDriveAuthManager) {
        self.authManager = authManager
    }

    // MARK: - Upload PDF

    /// Uploads a PDF to Google Drive. Creates an "MMCC" folder if none exists.
    func uploadPDF(data: Data, name: String, folderID: String? = nil) async throws -> DriveUploadResponse {
        try await authManager.ensureValidToken()
        guard let token = authManager.accessToken else { throw GoogleDriveError.notAuthenticated }

        // Resolve or create folder
        let targetFolderID: String
        if let folderID {
            targetFolderID = folderID
        } else {
            targetFolderID = try await getOrCreateMMCCFolder()
        }

        // Multipart upload: metadata + file content
        let boundary = UUID().uuidString
        var body = Data()

        // Metadata part
        let metadata: [String: Any] = [
            "name": name,
            "mimeType": "application/pdf",
            "parents": [targetFolderID],
        ]
        let metadataJSON = try JSONSerialization.data(withJSONObject: metadata)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataJSON)
        body.append("\r\n".data(using: .utf8)!)

        // File content part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: URL(string: "\(uploadURL)/files?uploadType=multipart&fields=id,name,mimeType,webViewLink")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorBody = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw GoogleDriveError.uploadFailed(errorBody)
        }

        return try decoder.decode(DriveUploadResponse.self, from: responseData)
    }

    // MARK: - List Files

    /// Lists files in a folder (or root if no folderID). Supports search query.
    func listFiles(folderID: String? = nil, query: String? = nil, pageSize: Int = 50) async throws -> DriveFileList {
        try await authManager.ensureValidToken()
        guard let token = authManager.accessToken else { throw GoogleDriveError.notAuthenticated }

        var queryParts: [String] = ["trashed = false"]
        if let folderID {
            queryParts.append("'\(folderID)' in parents")
        }
        if let query, !query.isEmpty {
            queryParts.append("name contains '\(query)'")
        }

        var components = URLComponents(string: "\(baseURL)/files")!
        components.queryItems = [
            URLQueryItem(name: "q", value: queryParts.joined(separator: " and ")),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "fields", value: "files(id,name,mimeType,size,thumbnailLink,webViewLink,createdTime,modifiedTime),nextPageToken"),
            URLQueryItem(name: "orderBy", value: "modifiedTime desc"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleDriveError.downloadFailed("List files failed")
        }

        return try decoder.decode(DriveFileList.self, from: data)
    }

    // MARK: - Download File

    /// Downloads a file's content by ID.
    func downloadFile(fileID: String) async throws -> Data {
        try await authManager.ensureValidToken()
        guard let token = authManager.accessToken else { throw GoogleDriveError.notAuthenticated }

        var request = URLRequest(url: URL(string: "\(baseURL)/files/\(fileID)?alt=media")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleDriveError.downloadFailed("Download failed for file \(fileID)")
        }

        return data
    }

    // MARK: - Create Folder

    /// Creates a folder in Google Drive.
    func createFolder(name: String, parentID: String? = nil) async throws -> DriveFile {
        try await authManager.ensureValidToken()
        guard let token = authManager.accessToken else { throw GoogleDriveError.notAuthenticated }

        var metadata: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder",
        ]
        if let parentID {
            metadata["parents"] = [parentID]
        }

        var request = URLRequest(url: URL(string: "\(baseURL)/files?fields=id,name,mimeType,webViewLink")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: metadata)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleDriveError.folderCreationFailed
        }

        return try decoder.decode(DriveFile.self, from: data)
    }

    // MARK: - Get or Create MMCC Folder

    /// Finds the "MMCC" folder in root, or creates it if missing.
    func getOrCreateMMCCFolder() async throws -> String {
        // Check if we have a saved folder ID
        // (would come from BusinessProfile.googleDriveFolderID)

        // Search for existing MMCC folder
        let list = try await listFiles(query: "MMCC")
        if let mmccFolder = list.files.first(where: { $0.isFolder && $0.name == "MMCC" }) {
            return mmccFolder.id
        }

        // Create new MMCC folder
        let folder = try await createFolder(name: "MMCC")
        return folder.id
    }
}
