//
//  ReceiptListView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct ReceiptListView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject private var receiptVM = ReceiptViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel(dataService: ProductionDataService())

    @State var showSignInView: Bool = false
    @State var user: DBUser = DBUser(id: "", email: "", firstName: "", lastName: "", exp: 0, recentlySelectedCompany: "")
    @State private var showEditView: Bool = false
    @State private var showDetailsView: Bool = false

    @State var startViewingDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State var endViewingDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

    @State var viewBillable = true
    @State var viewNonBillable = true
    @State var viewInvoiced = true
    @State var viewNoneInvoiced = true
    @State var showSummary = false
    @State var showFilerOptions = false
    @State var showAddNew = false
    @State var showSearch = false
    @State var searchTerm: String = ""
    @State var receiptList: [Receipt] = []

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                receiptHeader

                if showSearch {
                    receiptSearchBar
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if receiptList.isEmpty {
                            receiptEmptyState
                                .padding(.top, 48)
                        } else {
                            ForEach(receiptList) { receipt in
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.receipt(receipt: receipt, dataService: dataService)) {
                                        ReceiptCardViewSmall(receipt: receipt)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        masterDataManager.selectedReceipt = receipt
                                    } label: {
                                        ReceiptCardViewSmall(receipt: receipt)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Color.clear.frame(height: UIDevice.isIPhone ? 96 : 24)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                }
                .refreshable {
                    await reloadReceipts()
                }
            }

            if UIDevice.isIPhone {
                receiptActionDock
            }
        }
        .navigationTitle("Receipts")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onChange(of: searchTerm) { _ in
            applyReceiptSearch()
        }
        .task {
            await reloadReceipts()
        }
        .sheet(isPresented: $showAddNew, onDismiss: {
            Task { await reloadReceipts() }
        }) {
            AddNewReceipt(dataService: dataService)
        }
        .toolbar {
            if !UIDevice.isIPhone {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }

                    Button {
                        Task { await reloadReceipts() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }

                    Button {
                        showAddNew.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

extension ReceiptListView {
    var receiptHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.richtext.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 48, height: 48)
                    .background(Color.poolBlue.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Receipts")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(receiptListSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                receiptSummaryMetric(
                    title: "Showing",
                    value: "\(receiptList.count)",
                    tint: .poolBlue
                )

                receiptSummaryMetric(
                    title: "Total",
                    value: receiptTotalDisplay,
                    tint: .poolGreen
                )

                receiptSummaryMetric(
                    title: "Files",
                    value: "\(receiptFileCount)",
                    tint: .orange
                )
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    var receiptSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Search receipts", text: $searchTerm)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchTerm.isEmpty {
                Button {
                    searchTerm = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    var receiptEmptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(searchTerm.isEmpty ? "No receipts found." : "No matching receipts.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(searchTerm.isEmpty ? "Add a receipt to start tracking purchased items." : "Try a different invoice, vendor, tech, or date.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if searchTerm.isEmpty {
                Button {
                    showAddNew.toggle()
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Receipt")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.poolGreen, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var receiptActionDock: some View {
        VStack(spacing: 10) {
            Button {
                Task { await reloadReceipts() }
            } label: {
                mobileDockIcon(
                    systemName: "arrow.clockwise",
                    tint: .orange,
                    isSelected: false
                )
            }
            .buttonStyle(.plain)

            Button {
                showAddNew.toggle()
            } label: {
                mobileDockIcon(
                    systemName: "plus",
                    tint: .poolGreen,
                    isSelected: false
                )
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    showSearch.toggle()
                }
            } label: {
                mobileDockIcon(
                    systemName: "magnifyingglass",
                    tint: .poolBlue,
                    isSelected: showSearch
                )
            }
            .buttonStyle(.plain)
        }
        .padding(7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.trailing, 14)
        .padding(.bottom, 18)
    }

    private func receiptSummaryMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func mobileDockIcon(
        systemName: String,
        tint: Color,
        isSelected: Bool
    ) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : tint)
            .frame(width: 40, height: 40)
            .background(
                isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.13)),
                in: Circle()
            )
    }

    private var receiptListSubtitle: String {
        if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(receiptVM.receiptItems.count) receipts from the last 30 days."
        }

        return "Search results for \"\(searchTerm)\"."
    }

    private var receiptTotalDisplay: String {
        let total = receiptList.reduce(0) { $0 + $1.costAfterTax }
        return total.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private var receiptFileCount: Int {
        receiptList.reduce(0) { $0 + ($1.pdfUrlList?.count ?? 0) }
    }

    @MainActor
    func reloadReceipts() async {
        guard let company = masterDataManager.currentCompany else { return }

        do {
            try await receiptVM.getAllReceipts(companyId: company.id)
            applyReceiptSearch()
        } catch {
            print(error)
        }
    }

    func applyReceiptSearch() {
        if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            receiptList = receiptVM.receiptItems
        } else {
            receiptVM.filterReceipts(filter: searchTerm, purchases: receiptVM.receiptItems)
            receiptList = receiptVM.filteredReceipts
        }
    }
}
