import SwiftUI
import SwiftData
import ContactsUI

struct CustomerPickerSheet: View {
    let customers: [Customer]
    @Bindable var proposal: Proposal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ProTierService.self) private var proTierService: ProTierService?
    @State private var newName = ""
    @State private var newPhone = ""
    @State private var newEmail = ""
    @State private var newAddress = ""
    @State private var showingContactPicker = false
    @State private var searchText = ""

    private var filteredCustomers: [Customer] {
        guard !searchText.isEmpty else { return customers }
        return customers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || $0.phone.localizedCaseInsensitiveContains(searchText)
            || $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !customers.isEmpty {
                    Section("Existing Customers") {
                        ForEach(filteredCustomers) { customer in
                            Button {
                                proposal.customer = customer
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(customer.name)
                                        .font(.body.bold())
                                        .foregroundStyle(.primary)
                                    if !customer.phone.isEmpty {
                                        Text(customer.phone)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if !customer.address.isEmpty {
                                        Text(customer.address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("New Customer") {
                    if proTierService?.canAddCustomer() ?? true {
                        Button {
                            showingContactPicker = true
                        } label: {
                            Label("Import from Contacts", systemImage: "person.crop.circle.badge.plus")
                                .foregroundStyle(Color.mmccAmber)
                        }

                        TextField("Name", text: $newName)
                            .textContentType(.name)
                        TextField("Phone", text: $newPhone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                        TextField("Email", text: $newEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        TextField("Address", text: $newAddress)
                            .textContentType(.fullStreetAddress)

                        Button("Create & Assign") {
                            createAndAssignCustomer()
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    } else {
                        UpgradePromptBanner(text: "Customer limit reached (\(proTierService?.tier.customerLimit ?? 10) max)")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search customers...")
            .navigationTitle("Customer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView { contact in
                    populateFromContact(contact)
                }
                .ignoresSafeArea()
            }
        }
    }

    private func populateFromContact(_ contact: CNContact) {
        let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
        newName = name

        if let phone = contact.phoneNumbers.first?.value {
            newPhone = phone.stringValue
        }

        if let email = contact.emailAddresses.first?.value as String? {
            newEmail = email
        }

        if let postal = contact.postalAddresses.first?.value {
            let formatter = CNPostalAddressFormatter()
            newAddress = formatter.string(from: postal).replacingOccurrences(of: "\n", with: ", ")
        }
    }

    private func createAndAssignCustomer() {
        let customer = Customer(name: newName.trimmingCharacters(in: .whitespaces))
        customer.phone = newPhone.trimmingCharacters(in: .whitespaces)
        customer.email = newEmail.trimmingCharacters(in: .whitespaces)
        customer.address = newAddress.trimmingCharacters(in: .whitespaces)
        modelContext.insert(customer)
        proposal.customer = customer
        dismiss()
    }
}

// MARK: - Invoice Customer Picker

struct InvoiceCustomerPickerSheet: View {
    let customers: [Customer]
    @Bindable var invoice: Invoice
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ProTierService.self) private var proTierService: ProTierService?
    @State private var newName = ""
    @State private var newPhone = ""
    @State private var newEmail = ""
    @State private var newAddress = ""
    @State private var showingContactPicker = false
    @State private var searchText = ""

    private var filteredCustomers: [Customer] {
        guard !searchText.isEmpty else { return customers }
        return customers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || $0.phone.localizedCaseInsensitiveContains(searchText)
            || $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !customers.isEmpty {
                    Section("Existing Customers") {
                        ForEach(filteredCustomers) { customer in
                            Button {
                                invoice.customer = customer
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(customer.name)
                                        .font(.body.bold())
                                        .foregroundStyle(.primary)
                                    if !customer.phone.isEmpty {
                                        Text(customer.phone)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if !customer.address.isEmpty {
                                        Text(customer.address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("New Customer") {
                    if proTierService?.canAddCustomer() ?? true {
                        Button {
                            showingContactPicker = true
                        } label: {
                            Label("Import from Contacts", systemImage: "person.crop.circle.badge.plus")
                                .foregroundStyle(Color.mmccAmber)
                        }

                        TextField("Name", text: $newName)
                            .textContentType(.name)
                        TextField("Phone", text: $newPhone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                        TextField("Email", text: $newEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        TextField("Address", text: $newAddress)
                            .textContentType(.fullStreetAddress)

                        Button("Create & Assign") {
                            let customer = Customer(name: newName.trimmingCharacters(in: .whitespaces))
                            customer.phone = newPhone.trimmingCharacters(in: .whitespaces)
                            customer.email = newEmail.trimmingCharacters(in: .whitespaces)
                            customer.address = newAddress.trimmingCharacters(in: .whitespaces)
                            modelContext.insert(customer)
                            invoice.customer = customer
                            dismiss()
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    } else {
                        UpgradePromptBanner(text: "Customer limit reached (\(proTierService?.tier.customerLimit ?? 10) max)")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search customers...")
            .navigationTitle("Customer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView { contact in
                    let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
                    newName = name
                    if let phone = contact.phoneNumbers.first?.value {
                        newPhone = phone.stringValue
                    }
                    if let email = contact.emailAddresses.first?.value as String? {
                        newEmail = email
                    }
                    if let postal = contact.postalAddresses.first?.value {
                        let formatter = CNPostalAddressFormatter()
                        newAddress = formatter.string(from: postal).replacingOccurrences(of: "\n", with: ", ")
                    }
                }
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - CNContactPickerViewController Wrapper

struct ContactPickerView: UIViewControllerRepresentable {
    let onSelect: (CNContact) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: (CNContact) -> Void

        init(onSelect: @escaping (CNContact) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onSelect(contact)
        }
    }
}
