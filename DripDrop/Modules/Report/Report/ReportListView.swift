//
//  ReportListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/17/24.
//

import SwiftUI

struct ReportListView: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService
    @State private var searchText: String = ""

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    searchField
                    list
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReportListView_Previews: PreviewProvider {
    static var previews: some View {
        ReportListView()
    }
}
extension ReportListView {
    var list: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(ReportType.Category.allCases) { category in
                let reports = filteredReports.filter { $0.category == category }
                if !reports.isEmpty {
                    categorySection(category: category, reports: reports)
                }
            }

            if filteredReports.isEmpty {
                emptyState
            }
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 48, height: 48)
                    .background(Color.poolBlue.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Report Library")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Operations and finance reporting.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Label("\(ReportType.allCases.count) Reports", systemImage: "square.grid.2x2.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.poolBlue.opacity(0.12), in: Capsule())

                Label("3 Categories", systemImage: "folder.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Search reports", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .font(.subheadline)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                })
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        }
    }

    func categorySection(category: ReportType.Category, reports: [ReportType]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.rawValue.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(reports) { report in
                    reportRow(report)
                }
            }
        }
    }

    func reportRow(_ report: ReportType) -> some View {
        Group {
            if UIDevice.isIPhone {
                NavigationLink(value: Route.reports(dataService: dataService)) {
                    ReportCardView(
                        report: report,
                        selected: masterDataManager.selectedReport == report
                    )
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    masterDataManager.selectedReport = report
                })
            } else {
                Button(action: {
                    masterDataManager.selectedReport = report
                }, label: {
                    ReportCardView(
                        report: report,
                        selected: masterDataManager.selectedReport == report
                    )
                })
                .buttonStyle(.plain)
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("No reports match that search.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        }
    }

    var filteredReports: [ReportType] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else {
            return ReportType.allCases
        }

        return ReportType.allCases.filter { report in
            [
                report.title,
                report.source,
                report.category.rawValue
            ]
            .contains { $0.lowercased().contains(term) }
        }
    }
}
