import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "chart.bar.fill") {
                DashboardView()
            }
            Tab("Proposals", systemImage: "doc.text.fill") {
                ProposalListView()
            }
            Tab("Invoices", systemImage: "dollarsign.circle.fill") {
                InvoiceListView()
            }
            Tab("Library", systemImage: "tray.full.fill") {
                LibraryView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tint(Color.mmccAmber)
    }
}
