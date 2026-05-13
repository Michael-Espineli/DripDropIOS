//
//  MangeStripeSubscriptionsView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/15/25.
//

import SwiftUI
import Foundation
// import StripePaymentSheet
// import FirebaseFunctions

// MARK: - Mock Models (for UI mockup)
struct MockInvoice: Identifiable, Hashable {
    let id: String
    let created: Date
    let status: String // paid, open, void, etc.
    let paid: Bool
    let amountPaid: Int // cents
    let currency: String // e.g., "usd"
    let hostedInvoiceURL: URL?
}
@MainActor
func openWeb(urlString: String) {
    guard let url = URL(string: urlString) else { return }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
}

@MainActor
final class MangeStripeSubscriptionsViewModel: ObservableObject{
    let dataService: any ProductionDataServiceProtocol
    
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }

    // UI State
    @Published var activeSubscription: CompanySubscription? = nil
    @Published var loading: Bool = true
    @Published var error: String? = nil

    @Published var paymentHistory: [MockInvoice] = []
    @Published var loadingHistory: Bool = false
    @Published var isPortalLoading: Bool = false
    @Published var upcomingInvoice: MockInvoice? = nil


    func load(companyId: String?) {
        Task{
            guard let companyId else {return}
                // Simulate query param success/canceled handling and data fetching
            loading = true
            error = nil
            defer { loading = false }
            
                // Simulate fetching active subscription
            do {
                self.activeSubscription = try await dataService.getCompanySubscription(companyId: companyId)
            } catch {
                self.error = "Failed to fetch subscription details."
                return
            }
            
                // If we have a subscription, load payment history and upcoming invoice
            await loadPaymentHistory()
            await loadUpcomingInvoice()
        }
    }

    private func loadPaymentHistory() async {
        loadingHistory = true
        defer { loadingHistory = false }
        do {
            try await Task.sleep(nanoseconds: 350_000_000)
            //Developer Get Payment History
            // MARK: UISceneSession Lifecycle
        } catch {
            // keep empty, could set an error toast in real impl
        }
    }

    private func loadUpcomingInvoice() async {
        guard let activeSubscription else { return }
        if activeSubscription.name == .free { return }
        do {
            try await Task.sleep(nanoseconds: 250_000_000)
            // Simulate an upcoming invoice next month
            let nextDate = Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date()
            self.upcomingInvoice = MockInvoice(
                id: "upcoming_1",
                created: nextDate,
                status: "open",
                paid: false,
                amountPaid: 1999,
                currency: "usd",
                hostedInvoiceURL: nil
            )
        } catch {
            // Often no upcoming invoice; ignore
        }
    }

    func handleCancelSubscription() async {
        guard var sub = activeSubscription else { return }
        // Simulate confirmation and cancel
        do {
            try await Task.sleep(nanoseconds: 500_000_000)

            self.upcomingInvoice = nil // none after cancel
        } catch { }
    }

    func handleRedirectToPortal() async {
        isPortalLoading = true
        defer { isPortalLoading = false }
        // Simulate a redirect delay
        try? await Task.sleep(nanoseconds: 600_000_000)
        // In a real app, open URL from backend-created portal session
        await openWeb(urlString: "https://dripdrop-poolapp.com/company/settings/subscriptions")
    }

    // Helpers
    func formatCurrency(_ amountCents: Int, currency: String = "usd") -> String {
        let amount = Double(amountCents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.uppercased()
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct MangeStripeSubscriptionsView: View {

    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: MangeStripeSubscriptionsViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager: MasterDataManager

    @EnvironmentObject private var dataService: ProductionDataService
    @StateObject private var VM : MangeStripeSubscriptionsViewModel

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if VM.loading {
                        Text("Loading subscription...")
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    if let error = VM.error {
                        Text(error)
                            .foregroundStyle(.red)
                    }

                    if !VM.loading && VM.error == nil {
                        subscriptionCard

                        if VM.activeSubscription != nil {
                            paymentsSection
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Manage Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: {
            VM.load(companyId: masterDataManager.currentCompany?.id)
        })
    }

    private var subscriptionCard: some View {
        Group {
            if let sub = VM.activeSubscription {
                VStack(alignment: .leading, spacing: 16) {
                    // Grid-like two columns on larger screens using HStack
                    VStack(spacing: 16) {
                        // Left
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Current Plan")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.gray)
                            Text(sub.name.rawValue)
                                .font(.title.weight(.bold))
                                .foregroundStyle(.white)
                            Text(sub.status.replacingOccurrences(of: "_", with: " "))
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.yellow)
                            if sub.status == "pending_cancellation", let cancelAt = sub.currentPeriodEnd {
                                Text("Cancels on \(format(date: cancelAt))")
                                    .font(.footnote)
                                    .foregroundStyle(.yellow)
                            }
                        }
                        Divider()
                        // Right
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Started on:")
                                    .foregroundStyle(.gray)
                                Text(format(date: sub.started))
                                    .foregroundStyle(.white)
                            }
                            HStack {
                                Text("Price:")
                                    .foregroundStyle(.gray)
                                Text("\(VM.formatCurrency(sub.price))/month")
                                    .foregroundStyle(.white)
                            }
                            if let upcoming = VM.upcomingInvoice {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Next billing date:")
                                            .foregroundStyle(.gray)
                                        Text(format(date: upcoming.created))
                                            .foregroundStyle(.white)
                                    }
                                    HStack {
                                        Text("Next charge:")
                                            .foregroundStyle(.gray)
                                        Text(VM.formatCurrency(upcoming.amountPaid, currency: upcoming.currency))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        

                        VStack(spacing: 12) {
                            Button(action: { Task { await VM.handleRedirectToPortal() } }) {
                                Text(VM.isPortalLoading ? "Redirecting..." : "Manage Billing & Invoices")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.poolYellow)
                                    .foregroundStyle(.black)
                                    .font(.headline.weight(.bold))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(VM.isPortalLoading)
////                            Update 4.1
//                            HStack(spacing: 12) {
//                                NavigationLink(value: Route.editCompanySubscription(dataService: dataService)) {
//                                    Text("Change Plan")
//                                        .frame(maxWidth: .infinity)
//                                        .padding()
//                                        .background(Color.blue)
//                                        .foregroundStyle(.white)
//                                        .font(.headline.weight(.bold))
//                                        .clipShape(RoundedRectangle(cornerRadius: 12))
//                                }
//
//                                if sub.status != "pending_cancellation" {
//                                    Button(action: { Task { await VM.handleCancelSubscription() } }) {
//                                        Text("Cancel")
//                                            .frame(maxWidth: .infinity)
//                                            .padding()
//                                            .background(Color.gray)
//                                            .foregroundStyle(.white)
//                                            .font(.headline.weight(.bold))
//                                            .clipShape(RoundedRectangle(cornerRadius: 12))
//                                    }
//                                }
//                            }
//                            .padding(.top, 4)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(20)
                .background(Color(.sRGB, red: 31/255, green: 41/255, blue: 55/255, opacity: 1)) // gray-800
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 6)
            } else {
                VStack(spacing: 12) {
                    Text("No Active Subscription")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("You are currently on the Free plan.")
                        .foregroundStyle(.white.opacity(0.8))
                    NavigationLink(value: Route.editCompanySubscription(dataService: dataService)) {
                        Text("View Plans & Upgrade")
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .font(.headline.weight(.bold))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(.sRGB, red: 31/255, green: 41/255, blue: 55/255, opacity: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 6)
            }
        }
    }

    private var paymentsSection: some View {
        VStack(spacing: 16) {
            Text("Recent Payments")
                .font(.title.weight(.bold))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)

            if VM.loadingHistory {
                Text("Loading payment history...")
                    .foregroundStyle(.white.opacity(0.8))
            } else if VM.paymentHistory.isEmpty {
                VStack {
                    Text("No payment history found.")
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(.sRGB, red: 31/255, green: 41/255, blue: 55/255, opacity: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 0) {
                    ForEach(VM.paymentHistory) { invoice in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(format(date: invoice.created))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                Text(invoice.status.capitalized)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(invoice.paid ? .green : .red)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 6) {
                                Text(VM.formatCurrency(invoice.amountPaid, currency: invoice.currency))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                if let url = invoice.hostedInvoiceURL {
                                    Link("View Invoice", destination: url)
                                        .font(.footnote)
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.clear)
                        .overlay(
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                                .offset(y: 0), alignment: .bottom
                        )
                    }
                }
                .background(Color(.sRGB, red: 31/255, green: 41/255, blue: 55/255, opacity: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers
    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    MangeStripeSubscriptionsView(dataService: MockDataService())
        .environmentObject(ProductionDataService())
}

