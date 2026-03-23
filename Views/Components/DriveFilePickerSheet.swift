import SwiftUI

// MARK: - Google Drive File Picker
// Browse and search Drive files. Select to download and attach.

struct DriveFilePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let driveClient: GoogleDriveClient
    let onFileSelected: (Data, String) -> Void

    @State private var files: [DriveFile] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var downloadingFileID: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && files.isEmpty {
                    ProgressView("Loading files...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") { loadFiles() }
                    }
                    .padding()
                } else if files.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No files found")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(files) { file in
                        Button {
                            downloadAndAttach(file)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: file.isFolder ? "folder.fill" : fileIcon(for: file.mimeType))
                                    .font(.title3)
                                    .foregroundStyle(file.isFolder ? .blue : .orange)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(file.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    HStack(spacing: 8) {
                                        if !file.formattedSize.isEmpty {
                                            Text(file.formattedSize)
                                        }
                                        if let modified = file.modifiedTime {
                                            Text(modified, style: .date)
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if downloadingFileID == file.id {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                            }
                        }
                        .disabled(file.isFolder || downloadingFileID != nil)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Google Drive...")
            .navigationTitle("Google Drive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { loadFiles() }
            .onChange(of: searchText) {
                loadFiles()
            }
        }
    }

    private func loadFiles() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let query = searchText.isEmpty ? nil : searchText
                let result = try await driveClient.listFiles(query: query)
                files = result.files
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func downloadAndAttach(_ file: DriveFile) {
        downloadingFileID = file.id

        Task {
            do {
                let data = try await driveClient.downloadFile(fileID: file.id)
                onFileSelected(data, file.name)
                dismiss()
            } catch {
                errorMessage = "Failed to download: \(error.localizedDescription)"
            }
            downloadingFileID = nil
        }
    }

    private func fileIcon(for mimeType: String) -> String {
        switch mimeType {
        case "application/pdf": "doc.fill"
        case _ where mimeType.hasPrefix("image/"): "photo.fill"
        case _ where mimeType.hasPrefix("video/"): "film.fill"
        default: "doc.fill"
        }
    }
}
