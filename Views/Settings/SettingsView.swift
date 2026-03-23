import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(QBAuthManager.self) private var authManager
    @Environment(SyncCoordinator.self) private var syncCoordinator
    @Environment(SubscriptionManager.self) private var subscriptionManager: SubscriptionManager?
    @Environment(ProTierService.self) private var proTierService: ProTierService?
    @Query private var profiles: [BusinessProfile]
    @State private var showingProfileEditor = false
    @State private var showingLogoutConfirmation = false
    @State private var showingDisconnectConfirmation = false
    @State private var showingPaywall = false
    @State private var qbConnecting = false
    @State private var qbError: String?
    @State private var driveConnecting = false
    @State private var driveError: String?
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    private var profile: BusinessProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Form {
                if let profile {
                    businessSection(profile)
                    defaultsSection(profile)
                    qbSection(profile)
                    googleDriveSection(profile)
                    subscriptionSection
                }
                appearanceSection
                aboutSection
                logoutSection
            }
            .navigationTitle("Settings")
            .toolbar {
                if profile != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") { showingProfileEditor = true }
                    }
                }
            }
            .sheet(isPresented: $showingProfileEditor) {
                if let profile {
                    BusinessProfileEditorSheet(profile: profile)
                }
            }
            .alert("Reset App?", isPresented: $showingLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset & Log Out", role: .destructive) { resetApp() }
            } message: {
                Text("This will delete all proposals, invoices, customers, and settings. You'll be taken back to the welcome screen.")
            }
        }
    }

    private func businessSection(_ profile: BusinessProfile) -> some View {
        Section("Business") {
            if profile.businessName.isEmpty {
                Button {
                    showingProfileEditor = true
                } label: {
                    Label("Set up your business info", systemImage: "building.2")
                        .foregroundStyle(Color.accentColor)
                }
            } else {
                LabeledContent("Name", value: profile.businessName)
                if !profile.phone.isEmpty {
                    LabeledContent("Phone", value: profile.phone)
                }
                if !profile.email.isEmpty {
                    LabeledContent("Email", value: profile.email)
                }
                if !profile.licenseNumber.isEmpty {
                    LabeledContent("License #", value: profile.licenseNumber)
                }
                if !profile.formattedAddress.isEmpty {
                    LabeledContent("Address", value: profile.formattedAddress)
                }
            }
        }
    }

    private func defaultsSection(_ profile: BusinessProfile) -> some View {
        Section("Proposal Defaults") {
            LabeledContent("Tax Rate", value: "\(profile.defaultTaxRate)%")
            LabeledContent("Markup", value: "\(profile.defaultMarkup)%")
            LabeledContent("Valid Days", value: "\(profile.defaultValidDays)")
            LabeledContent("Payment Terms", value: profile.defaultPaymentTerms.displayName)
            LabeledContent("Jurisdiction", value: profile.defaultPermitJurisdiction.displayName)
        }
    }

    private func qbSection(_ profile: BusinessProfile) -> some View {
        Section("QuickBooks") {
            if profile.qbConnected {
                // Connected state
                Label("Connected", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                if let realmID = profile.qbRealmID {
                    LabeledContent("Company ID", value: realmID)
                        .font(.caption)
                }

                if syncCoordinator.pendingQueueCount > 0 {
                    Label("\(syncCoordinator.pendingQueueCount) pending sync\(syncCoordinator.pendingQueueCount == 1 ? "" : "s")",
                          systemImage: "clock.arrow.circlepath")
                    .foregroundStyle(Color.mmccAmber)
                }

                if syncCoordinator.isSyncing {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Syncing...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    Task {
                        await syncCoordinator.processQueue()
                    }
                } label: {
                    Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                }

                Button(role: .destructive) {
                    showingDisconnectConfirmation = true
                } label: {
                    Label("Disconnect", systemImage: "xmark.circle")
                }
            } else if qbConnecting {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Connecting to QuickBooks...")
                        .foregroundStyle(.secondary)
                }
            } else {
                // Not connected state
                if proTierService?.canSyncToQuickBooks() ?? false {
                    Button {
                        connectToQuickBooks()
                    } label: {
                        Label("Connect to QuickBooks", systemImage: "link.circle.fill")
                            .foregroundStyle(Color.mmccAmber)
                    }

                    Text("Sync proposals, invoices, and payments to your QuickBooks account.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    HStack {
                        Label("Connect to QuickBooks", systemImage: "link.circle.fill")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Pro")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.mmccAmber, in: .capsule)
                    }

                    Text("Upgrade to Pro to sync proposals, invoices, and payments.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = qbError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            if let syncError = syncCoordinator.lastSyncError {
                Label(syncError, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
        .alert("Disconnect QuickBooks?", isPresented: $showingDisconnectConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                authManager.disconnect()
                qbError = nil
            }
        } message: {
            Text("Your data stays in MMCC. Future proposals and invoices won't sync until you reconnect.")
        }
    }

    private func connectToQuickBooks() {
        qbConnecting = true
        qbError = nil

        Task {
            do {
                try await authManager.startOAuthFlow()
                qbError = nil
            } catch let error as QBAuthError {
                if case .authFlowCancelled = error {
                    // User cancelled — don't show error
                } else {
                    qbError = error.localizedDescription
                }
            } catch {
                qbError = error.localizedDescription
            }
            qbConnecting = false
        }
    }

    private func googleDriveSection(_ profile: BusinessProfile) -> some View {
        Section("Google Drive") {
            if profile.googleDriveConnected {
                Label("Connected", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                if profile.googleDriveFolderID != nil {
                    LabeledContent("Folder", value: "MMCC")
                        .font(.caption)
                }

                Button(role: .destructive) {
                    profile.googleDriveConnected = false
                    profile.googleDriveFolderID = nil
                } label: {
                    Label("Disconnect", systemImage: "xmark.circle")
                }
            } else if driveConnecting {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Connecting to Google Drive...")
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    // Google Drive OAuth flow would go here
                    driveConnecting = true
                    // Placeholder — actual implementation uses GoogleDriveAuthManager
                    driveConnecting = false
                } label: {
                    Label("Connect to Google Drive", systemImage: "link.circle.fill")
                        .foregroundStyle(.blue)
                }

                Text("Save proposal and invoice PDFs to Google Drive, and attach files from Drive.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = driveError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    private var subscriptionSection: some View {
        Section("Subscription") {
            if let subscriptionManager, subscriptionManager.isPro {
                // Pro state
                Label("MMCC Pro", systemImage: "crown.fill")
                    .foregroundStyle(Color.mmccAmber)
                if let expiry = subscriptionManager.expirationDate {
                    LabeledContent("Renews", value: expiry.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                }
                Link("Manage Subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                    .font(.caption)
            } else {
                // Free state
                HStack {
                    Text("Free Tier")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(Color.mmccAmber.opacity(0.5))
                }

                if let limitText = proTierService?.proposalLimitText() {
                    Text(limitText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let limitText = proTierService?.invoiceLimitText() {
                    Text(limitText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    showingPaywall = true
                } label: {
                    Label("Upgrade to Pro", systemImage: "crown.fill")
                        .foregroundStyle(Color.mmccAmber)
                }

                Button {
                    Task { await subscriptionManager?.restorePurchases() }
                } label: {
                    Text("Restore Purchases")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Mode", selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0.0")
            LabeledContent("Built for", value: "Marine Contractors")
        }
    }

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showingLogoutConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Label("Log Out & Reset", systemImage: "arrow.uturn.left")
                    Spacer()
                }
            }
        } footer: {
            Text("Returns to the welcome screen and removes all local data.")
        }
    }

    private func resetApp() {
        try? modelContext.delete(model: Payment.self)
        try? modelContext.delete(model: InvoiceLineItem.self)
        try? modelContext.delete(model: InvoiceSection.self)
        try? modelContext.delete(model: Invoice.self)
        try? modelContext.delete(model: ProposalLineItem.self)
        try? modelContext.delete(model: ProposalSection.self)
        try? modelContext.delete(model: Proposal.self)
        try? modelContext.delete(model: TemplateItem.self)
        try? modelContext.delete(model: TemplateSection.self)
        try? modelContext.delete(model: JobTemplate.self)
        try? modelContext.delete(model: Customer.self)
        try? modelContext.delete(model: SyncQueueItem.self)
        try? modelContext.delete(model: SavedItem.self)
        try? modelContext.delete(model: BusinessProfile.self)
        try? modelContext.save()
    }
}

// MARK: - Business Profile Editor

struct BusinessProfileEditorSheet: View {
    @Bindable var profile: BusinessProfile
    @Environment(\.dismiss) private var dismiss

    @State private var businessName: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""
    @State private var licenseNumber: String = ""
    @State private var defaultTaxRate: Decimal = 0
    @State private var defaultMarkup: Decimal = 0
    @State private var defaultValidDays: Int = 30
    @State private var defaultPaymentTerms: PaymentTerms = .thirdThirdThird
    @State private var defaultPermitJurisdiction: PermitJurisdiction = .leeCounty
    @State private var defaultTerms: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Business Info") {
                    TextField("Business Name", text: $businessName)
                        .textContentType(.organizationName)
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("License #", text: $licenseNumber)
                }

                Section("Address") {
                    TextField("Street", text: $street)
                        .textContentType(.streetAddressLine1)
                    TextField("City", text: $city)
                        .textContentType(.addressCity)
                    TextField("State", text: $state)
                        .textContentType(.addressState)
                    TextField("ZIP", text: $zip)
                        .textContentType(.postalCode)
                        .keyboardType(.numberPad)
                }

                Section("Proposal Defaults") {
                    HStack {
                        Text("Tax Rate %")
                        Spacer()
                        TextField("0", value: $defaultTaxRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Markup %")
                        Spacer()
                        TextField("0", value: $defaultMarkup, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Valid Days")
                        Spacer()
                        TextField("30", value: $defaultValidDays, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    Picker("Payment Terms", selection: $defaultPaymentTerms) {
                        ForEach(PaymentTerms.allCases) { terms in
                            Text(terms.displayName).tag(terms)
                        }
                    }
                    Picker("Jurisdiction", selection: $defaultPermitJurisdiction) {
                        ForEach(PermitJurisdiction.allCases) { j in
                            Text(j.displayName).tag(j)
                        }
                    }
                }

                Section("Default Terms") {
                    TextEditor(text: $defaultTerms)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear { loadProfile() }
        }
    }

    private func loadProfile() {
        businessName = profile.businessName
        phone = profile.phone
        email = profile.email
        street = profile.street
        city = profile.city
        state = profile.state
        zip = profile.zip
        licenseNumber = profile.licenseNumber
        defaultTaxRate = profile.defaultTaxRate
        defaultMarkup = profile.defaultMarkup
        defaultValidDays = profile.defaultValidDays
        defaultPaymentTerms = profile.defaultPaymentTerms
        defaultPermitJurisdiction = profile.defaultPermitJurisdiction
        defaultTerms = profile.defaultTerms
    }

    private func save() {
        profile.businessName = businessName.trimmingCharacters(in: .whitespaces)
        profile.phone = phone.trimmingCharacters(in: .whitespaces)
        profile.email = email.trimmingCharacters(in: .whitespaces)
        profile.street = street.trimmingCharacters(in: .whitespaces)
        profile.city = city.trimmingCharacters(in: .whitespaces)
        profile.state = state.trimmingCharacters(in: .whitespaces)
        profile.zip = zip.trimmingCharacters(in: .whitespaces)
        profile.licenseNumber = licenseNumber.trimmingCharacters(in: .whitespaces)
        profile.defaultTaxRate = defaultTaxRate
        profile.defaultMarkup = defaultMarkup
        profile.defaultValidDays = defaultValidDays
        profile.defaultPaymentTerms = defaultPaymentTerms
        profile.defaultPermitJurisdiction = defaultPermitJurisdiction
        profile.defaultTerms = defaultTerms
        dismiss()
    }
}
