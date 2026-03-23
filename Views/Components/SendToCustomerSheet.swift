import SwiftUI
import MessageUI

// MARK: - Send to Customer Sheet

/// Pre-filled send flow for proposals and invoices.
/// Shows email/iMessage options with the customer's info already populated.
struct SendToCustomerSheet: View {
    let documentType: DocumentType
    let documentNumber: String
    let documentTitle: String
    let customerName: String
    let customerEmail: String
    let customerPhone: String
    let grandTotal: Decimal
    let pdfData: Data
    let businessName: String

    @Environment(\.dismiss) private var dismiss
    @State private var showingMail = false
    @State private var showingMessage = false
    @State private var showingShareSheet = false
    @State private var didSendMail = false
    @State private var didSendMessage = false

    enum DocumentType: String {
        case proposal = "Proposal"
        case invoice = "Invoice"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Document summary
                VStack(spacing: 8) {
                    Image(systemName: documentType == .proposal ? "doc.text.fill" : "dollarsign.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.mmccAmber)

                    Text("\(documentType.rawValue) \(documentNumber)")
                        .font(.headline)

                    if !documentTitle.isEmpty {
                        Text(documentTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(grandTotal.formatted(.currency(code: "USD")))
                        .font(.title2.bold())
                        .monospacedDigit()
                }
                .padding(.top, 12)

                // Recipient
                if !customerName.isEmpty {
                    VStack(spacing: 4) {
                        Text("Sending to")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(customerName)
                            .font(.body.bold())
                    }
                }

                // Send options
                VStack(spacing: 12) {
                    if !customerEmail.isEmpty && MFMailComposeViewController.canSendMail() {
                        Button {
                            showingMail = true
                        } label: {
                            Label("Email PDF", systemImage: "envelope.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.mmccAmber)
                        .controlSize(.large)
                    }

                    if !customerPhone.isEmpty && MFMessageComposeViewController.canSendText() {
                        Button {
                            showingMessage = true
                        } label: {
                            Label("iMessage", systemImage: "message.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    // Fallback: always show generic share
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Other…", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal)

                // Warning if no contact info
                if customerEmail.isEmpty && customerPhone.isEmpty {
                    Label("No email or phone on file for this customer.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Send \(documentType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingMail) {
                MailComposerView(
                    toRecipients: [customerEmail],
                    subject: emailSubject,
                    body: emailBody,
                    attachmentData: pdfData,
                    attachmentMimeType: "application/pdf",
                    attachmentFileName: pdfFileName,
                    didSend: $didSendMail
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingMessage) {
                MessageComposerView(
                    recipients: [customerPhone],
                    body: messageBody,
                    attachmentData: pdfData,
                    attachmentFileName: pdfFileName,
                    didSend: $didSendMessage
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [pdfData])
            }
            .onChange(of: didSendMail) {
                if didSendMail { dismiss() }
            }
            .onChange(of: didSendMessage) {
                if didSendMessage { dismiss() }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Message Composition

    private var pdfFileName: String {
        "\(documentNumber) \(documentTitle.isEmpty ? documentType.rawValue : documentTitle).pdf"
    }

    private var emailSubject: String {
        "\(documentType.rawValue) \(documentNumber) from \(businessName)"
    }

    private var emailBody: String {
        """
        Hi \(customerName.components(separatedBy: " ").first ?? ""),

        Please find attached \(documentType.rawValue.lowercased()) \(documentNumber) for \(grandTotal.formatted(.currency(code: "USD"))).

        \(documentTitle.isEmpty ? "" : "Project: \(documentTitle)\n")
        Let me know if you have any questions.

        Thank you,
        \(businessName)
        """
    }

    private var messageBody: String {
        "Hi \(customerName.components(separatedBy: " ").first ?? "")! Here's your \(documentType.rawValue.lowercased()) \(documentNumber) for \(grandTotal.formatted(.currency(code: "USD"))) from \(businessName)."
    }
}

// MARK: - Mail Composer (UIViewControllerRepresentable)

struct MailComposerView: UIViewControllerRepresentable {
    let toRecipients: [String]
    let subject: String
    let body: String
    let attachmentData: Data
    let attachmentMimeType: String
    let attachmentFileName: String
    @Binding var didSend: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(toRecipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.addAttachmentData(attachmentData, mimeType: attachmentMimeType, fileName: attachmentFileName)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        let parent: MailComposerView
        init(_ parent: MailComposerView) { self.parent = parent }

        @MainActor
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if result == .sent {
                parent.didSend = true
            }
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Message Composer (UIViewControllerRepresentable)

struct MessageComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let attachmentData: Data?
    let attachmentFileName: String
    @Binding var didSend: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.messageComposeDelegate = context.coordinator
        vc.recipients = recipients
        vc.body = body
        if let data = attachmentData {
            vc.addAttachmentData(data, typeIdentifier: "com.adobe.pdf", filename: attachmentFileName)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    final class Coordinator: NSObject, @preconcurrency MFMessageComposeViewControllerDelegate {
        let parent: MessageComposerView
        init(_ parent: MessageComposerView) { self.parent = parent }

        @MainActor
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            if result == .sent {
                parent.didSend = true
            }
            controller.dismiss(animated: true)
        }
    }
}
