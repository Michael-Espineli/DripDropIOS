import SwiftUI

// Both entry points use the same filtering engine and UI.
struct BillingJobList: View {
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        JobListView(dataService: dataService, initialMode: .billing)
    }
}
