import SwiftUI
import WidgetKit

@main
struct MMCCWidgetBundle: WidgetBundle {
    var body: some Widget {
        MMCCStatsWidget()
        MMCCProposalsWidget()
    }
}
