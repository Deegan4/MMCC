import SwiftUI
import SwiftData

struct CustomerPickerSheet: View {
    let customers: [Customer]
    @Bindable var proposal: Proposal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ProTierService.self) private var proTierService: ProTierService?
    @State private var showingNewCustomer = false
    @State private var newName = ""
    @State private var newPhone = ""
    @State private var newEmail = ""

    var body: some View {
        NavigationStack {
            List {
                if !customers.isEmpty {
                    Section("Existing Customers") {
                        ForEach(customers) { customer in
                            Button {
                                proposal.customer = customer
                                dismiss()
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(customer.name)
                                        .font(.body.bold())
                                        .foregroundStyle(.primary)
                                    if !customer.waterway.isEmpty {
                                        Text(customer.waterway)
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
                        TextField("Name", text: $newName)
                            .textContentType(.name)
                        TextField("Phone", text: $newPhone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                        TextField("Email", text: $newEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        Button("Create & Assign") {
                            let customer = Customer(name: newName)
                            customer.phone = newPhone
                            customer.email = newEmail
                            modelContext.insert(customer)
                            proposal.customer = customer
                            dismiss()
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    } else {
                        UpgradePromptBanner(text: "Customer limit reached (\(proTierService?.tier.customerLimit ?? 10) max)")
                    }
                }
            }
            .navigationTitle("Customer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
