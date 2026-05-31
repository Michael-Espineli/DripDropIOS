//
//  TechnicianPayrollHistoryDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//

import Foundation
import SwiftUI

// MARK: - Technician Payroll History Detail

enum TechnicianPayrollHistoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case current = "Current"
    case scheduled = "Scheduled"
    case expired = "Expired"

    var id: String { rawValue }
}

struct TechnicianPayrollHistoryDetailView: View {

    let companyUser: CompanyUser
    let rates: [TechnicianRate]
    let workTypes: [CompanyWorkType]

    @State private var selectedFilter: TechnicianPayrollHistoryFilter = .all
    @State private var searchText: String = ""

    private var workTypesById: [String: CompanyWorkType] {
        Dictionary(uniqueKeysWithValues: workTypes.map { ($0.id, $0) })
    }

    private var filteredRates: [TechnicianRate] {
        let now = Date()

        let statusFiltered: [TechnicianRate]

        switch selectedFilter {
        case .all:
            statusFiltered = rates

        case .current:
            statusFiltered = rates.filter {
                $0.status == .active &&
                $0.effectiveStartDate <= now &&
                ($0.effectiveEndDate == nil || $0.effectiveEndDate! >= now)
            }

        case .scheduled:
            statusFiltered = rates.filter {
                $0.status == .scheduled || $0.effectiveStartDate > now
            }

        case .expired:
            statusFiltered = rates.filter {
                $0.status == .expired ||
                ($0.effectiveEndDate != nil && $0.effectiveEndDate! < now)
            }
        }

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let searched: [TechnicianRate]

        if trimmedSearch.isEmpty {
            searched = statusFiltered
        } else {
            searched = statusFiltered.filter { rate in
                workTypeName(for: rate).localizedCaseInsensitiveContains(trimmedSearch) ||
                rate.payBasis.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                rate.rateType.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                rate.status.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                (rate.reason ?? "").localizedCaseInsensitiveContains(trimmedSearch)
            }
        }

        return searched.sorted {
            if $0.effectiveStartDate == $1.effectiveStartDate {
                return workTypeName(for: $0) < workTypeName(for: $1)
            }

            return $0.effectiveStartDate > $1.effectiveStartDate
        }
    }

    private var currentRatesCount: Int {
        let now = Date()

        return rates.filter {
            $0.status == .active &&
            $0.effectiveStartDate <= now &&
            ($0.effectiveEndDate == nil || $0.effectiveEndDate! >= now)
        }.count
    }

    private var scheduledRatesCount: Int {
        let now = Date()

        return rates.filter {
            $0.status == .scheduled || $0.effectiveStartDate > now
        }.count
    }

    private var expiredRatesCount: Int {
        let now = Date()

        return rates.filter {
            $0.status == .expired ||
            ($0.effectiveEndDate != nil && $0.effectiveEndDate! < now)
        }.count
    }

    var body: some View {
        List {
            summarySection
            filterSection
            historySection
        }
        .navigationTitle("Rate History")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search work type, basis, or notes")
    }

    private var summarySection: some View {
        Section("Technician") {
            TechnicianPayrollDetailRow(
                title: "Name",
                value: companyUser.payrollDisplayName
            )

            TechnicianPayrollDetailRow(
                title: "Worker Type",
                value: companyUser.workerType.rawValue
            )

            TechnicianPayrollDetailRow(
                title: "Current Rates",
                value: "\(currentRatesCount)"
            )

            TechnicianPayrollDetailRow(
                title: "Scheduled Rates",
                value: "\(scheduledRatesCount)"
            )

            TechnicianPayrollDetailRow(
                title: "Expired Rates",
                value: "\(expiredRatesCount)"
            )
        }
    }

    private var filterSection: some View {
        Section {
            Picker("Rates", selection: $selectedFilter) {
                ForEach(TechnicianPayrollHistoryFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var historySection: some View {
        Section {
            if filteredRates.isEmpty {
                ContentUnavailableView(
                    "No Rate History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("No technician rates match this filter.")
                )
            } else {
                ForEach(filteredRates) { rate in
                    TechnicianPayrollHistoryRateRow(
                        rate: rate,
                        workTypeName: workTypeName(for: rate),
                        workTypeIcon: workTypeIcon(for: rate),
                        previousRate: previousRate(for: rate)
                    )
                }
            }
        } header: {
            Text("Rates")
        } footer: {
            Text("Rate history is created when a technician rate is replaced by a new rate instead of being overwritten.")
        }
    }

    private func workTypeName(for rate: TechnicianRate) -> String {
        if rate.payBasis == .technicianHourly {
            return "Hourly Rate"
        }

        guard let workTypeId = rate.workTypeId else {
            return "No Work Type"
        }

        return workTypesById[workTypeId]?.name ?? "Missing Work Type"
    }

    private func workTypeIcon(for rate: TechnicianRate) -> String {
        if rate.payBasis == .technicianHourly {
            return "clock"
        }

        guard let workTypeId = rate.workTypeId,
              let workType = workTypesById[workTypeId] else {
            return "exclamationmark.triangle"
        }

        return workType.displayIconName
    }

    private func previousRate(for rate: TechnicianRate) -> TechnicianRate? {
        guard let previousRateId = rate.previousRateId else {
            return nil
        }

        return rates.first { $0.id == previousRateId }
    }
}

struct TechnicianPayrollHistoryRateRow: View {
    var rate: TechnicianRate
    var workTypeName: String
    var workTypeIcon: String
    var previousRate: TechnicianRate?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: workTypeIcon)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(workTypeName)
                        .font(.headline)

                    Text("\(rate.payBasis.title) • \(rate.rateType.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(TechnicianPayrollMoneyFormatter.money(rate.amountCents))
                    .font(.headline)
            }

            HStack {
                Text(rate.status.title)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())

                Spacer()

                Text(rateDateRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let previousRate {
                HStack {
                    Text("Previous Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(TechnicianPayrollMoneyFormatter.money(previousRate.amountCents))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if let previousRate {
                let difference = rate.amountCents - previousRate.amountCents

                HStack {
                    Text("Change")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(changeText(difference))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(difference >= 0 ? .green : .red)
                }
            }

            if let reason = rate.reason,
               !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Rate ID: \(rate.id)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
    }

    private var rateDateRangeText: String {
        let start = TechnicianPayrollDateFormatter.shortDate(rate.effectiveStartDate)

        if let end = rate.effectiveEndDate {
            return "\(start) - \(TechnicianPayrollDateFormatter.shortDate(end))"
        }

        return "\(start) - Present"
    }

    private func changeText(_ cents: Int) -> String {
        if cents == 0 {
            return "$0.00"
        }

        let prefix = cents > 0 ? "+" : "-"
        return prefix + TechnicianPayrollMoneyFormatter.money(abs(cents))
    }
}
