//
//  JobActualWorkView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//


import SwiftUI

struct JobActualWorkView: View {

    let job: Job
    let jobTasks: [JobTask]
    let serviceStops: [ServiceStop]
    let payLineItems: [TechnicianPayLineItem]
    let dataService: any ProductionDataServiceProtocol

    private var plannedLaborCents: Int {
        jobTasks.reduce(0) { $0 + $1.contractedRate }
    }

    private var plannedMinutes: Int {
        jobTasks.reduce(0) { $0 + $1.estimatedTime }
    }

    private var actualPayrollCents: Int {
        payLineItems.reduce(0) { $0 + $1.totalAmountCents }
    }

    private var calculatedPayrollCents: Int {
        payLineItems
            .filter {
                $0.calculationStatus == .calculated ||
                $0.calculationStatus == .approved ||
                $0.calculationStatus == .paid
            }
            .reduce(0) { $0 + $1.totalAmountCents }
    }

    private var needsReviewCount: Int {
        payLineItems.filter { $0.calculationStatus == .needsReview }.count
    }

    private var finishedStops: [ServiceStop] {
        serviceStops
            .filter { $0.operationStatus == .finished }
            .sorted { $0.serviceDate > $1.serviceDate }
    }

    private var unfinishedStops: [ServiceStop] {
        serviceStops
            .filter { $0.operationStatus != .finished }
            .sorted { $0.serviceDate > $1.serviceDate }
    }

    private var actualMinutes: Int {
        serviceStops.reduce(0) { $0 + $1.duration }
    }

    private var laborDifferenceCents: Int {
        actualPayrollCents - plannedLaborCents
    }

    private var minutesDifference: Int {
        actualMinutes - plannedMinutes
    }

    private var payLineItemsByStopId: [String: [TechnicianPayLineItem]] {
        Dictionary(grouping: payLineItems) { item in
            item.serviceStopId ?? "missing_service_stop"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                headerCard
                comparisonCard
                payrollStatusCard
                finishedStopsCard
                unfinishedStopsCard
                payLineItemsCard

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
        .background(Color.listColor.ignoresSafeArea())
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Actual Work")
                    .font(.title3.weight(.semibold))

                Text("Compare planned job labor against completed service stops and payroll generated from finished work.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                JobActualSummaryChip(
                    title: "Planned",
                    value: JobActualMoneyFormatter.money(plannedLaborCents),
                    systemImage: "doc.text"
                )

                JobActualSummaryChip(
                    title: "Actual",
                    value: JobActualMoneyFormatter.money(actualPayrollCents),
                    systemImage: "dollarsign.circle"
                )

                JobActualSummaryChip(
                    title: "Review",
                    value: "\(needsReviewCount)",
                    systemImage: "exclamationmark.triangle"
                )
            }

            HStack(spacing: 10) {
                JobActualSummaryChip(
                    title: "Finished",
                    value: "\(finishedStops.count)",
                    systemImage: "checkmark.seal"
                )

                JobActualSummaryChip(
                    title: "Open",
                    value: "\(unfinishedStops.count)",
                    systemImage: "circle"
                )

                JobActualSummaryChip(
                    title: "Pay Lines",
                    value: "\(payLineItems.count)",
                    systemImage: "list.bullet.rectangle"
                )
            }
        }
        .jobActualCard()
    }

    private var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Planned vs Actual")
                .font(.headline.weight(.semibold))

            JobActualDetailRow(
                title: "Planned Labor",
                value: JobActualMoneyFormatter.money(plannedLaborCents)
            )

            JobActualDetailRow(
                title: "Actual Payroll",
                value: JobActualMoneyFormatter.money(actualPayrollCents)
            )

            JobActualDetailRow(
                title: "Difference",
                value: JobActualMoneyFormatter.signedMoney(laborDifferenceCents),
                valueIsWarning: laborDifferenceCents > 0
            )

            Divider().opacity(0.2)

            JobActualDetailRow(
                title: "Planned Time",
                value: JobActualTimeFormatter.minutes(plannedMinutes)
            )

            JobActualDetailRow(
                title: "Actual Time",
                value: JobActualTimeFormatter.minutes(actualMinutes)
            )

            JobActualDetailRow(
                title: "Time Difference",
                value: JobActualTimeFormatter.signedMinutes(minutesDifference),
                valueIsWarning: minutesDifference > 0
            )
        }
        .jobActualCard()
    }

    private var payrollStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payroll Status")
                .font(.headline.weight(.semibold))

            JobActualDetailRow(
                title: "Calculated / Approved / Paid",
                value: JobActualMoneyFormatter.money(calculatedPayrollCents)
            )

            JobActualDetailRow(
                title: "Needs Review",
                value: "\(needsReviewCount)"
            )

            if needsReviewCount > 0 {
                Text("Some pay lines need review because a pay type, rate, or calculation rule was missing when payroll was generated.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if payLineItems.isEmpty {
                Text("No payroll line items have been generated for this job yet. Finish a service stop to generate payroll.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .jobActualCard()
    }

    private var finishedStopsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Finished Service Stops", systemImage: "checkmark.seal")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(finishedStops.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if finishedStops.isEmpty {
                JobActualEmptyMiniState(
                    title: "No finished stops yet.",
                    message: "Completed service stops will appear here with their payroll results.",
                    systemImage: "checkmark.seal"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(finishedStops) { stop in
                        NavigationLink(
                            value: Route.serviceStop(
                                serviceStop: stop,
                                dataService: dataService
                            )
                        ) {
                            JobActualServiceStopRow(
                                serviceStop: stop,
                                payLineItems: payLineItemsByStopId[stop.id] ?? []
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .jobActualCard()
    }

    private var unfinishedStopsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Open Service Stops", systemImage: "circle")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(unfinishedStops.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if unfinishedStops.isEmpty {
                JobActualEmptyMiniState(
                    title: "No open stops.",
                    message: "All scheduled stops for this job are finished or no stops have been scheduled.",
                    systemImage: "circle"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(unfinishedStops) { stop in
                        NavigationLink(
                            value: Route.serviceStop(
                                serviceStop: stop,
                                dataService: dataService
                            )
                        ) {
                            JobActualServiceStopRow(
                                serviceStop: stop,
                                payLineItems: payLineItemsByStopId[stop.id] ?? []
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .jobActualCard()
    }

    private var payLineItemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Payroll Line Items", systemImage: "list.bullet.rectangle")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(payLineItems.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if payLineItems.isEmpty {
                JobActualEmptyMiniState(
                    title: "No pay lines yet.",
                    message: "Pay lines are created when completed service stop work is processed by payroll.",
                    systemImage: "list.bullet.rectangle"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(payLineItems) { lineItem in
                        JobActualPayLineRow(lineItem: lineItem)
                    }
                }
            }
        }
        .jobActualCard()
    }
}

// MARK: - Rows

struct JobActualServiceStopRow: View {
    var serviceStop: ServiceStop
    var payLineItems: [TechnicianPayLineItem]

    private var payTotalCents: Int {
        payLineItems.reduce(0) { $0 + $1.totalAmountCents }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: serviceStop.operationStatus == .finished ? "checkmark.seal" : "circle")
                .font(.body.weight(.semibold))
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(serviceStop.internalId)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(JobActualMoneyFormatter.money(payTotalCents))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Text(serviceStop.type.isEmpty ? "Service Stop" : serviceStop.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(JobActualDateFormatter.shortDateTime(serviceStop.serviceDate)) • \(serviceStop.tech.isEmpty ? "Unassigned" : serviceStop.tech)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 8) {
                    Label(serviceStop.operationStatus.rawValue, systemImage: "flag")
                    Label("\(serviceStop.duration) min", systemImage: "clock")
                    Label("\(payLineItems.count) pay lines", systemImage: "list.bullet")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 7)
        }
        .padding(12)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }
}

struct JobActualPayLineRow: View {
    var lineItem: TechnicianPayLineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(lineItem.workTypeName ?? "Missing Pay Type")
                        .font(.subheadline.weight(.semibold))

                    Text(sourceText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(JobActualMoneyFormatter.money(lineItem.totalAmountCents))
                    .font(.subheadline.weight(.semibold))
            }

            HStack {
                Text(lineItem.calculationStatus.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())

                Spacer()

                Text(JobActualDateFormatter.shortDate(lineItem.completedDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Rate: \(JobActualMoneyFormatter.money(lineItem.rateAmountCents))")
                Spacer()
                Text("Qty: \(quantityText)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let notes = lineItem.notes,
               !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var sourceText: String {
        var parts: [String] = []

        parts.append(lineItem.source.rawValue)

        if let serviceStopId = lineItem.serviceStopId {
            parts.append(serviceStopId)
        }

        if let taskId = lineItem.serviceStopTaskId {
            parts.append(taskId)
        }

        return parts.joined(separator: " • ")
    }

    private var quantityText: String {
        switch lineItem.quantityUnit {
        case .minutes:
            return "\(Int(lineItem.quantity)) min"
        case .hours:
            return "\(lineItem.quantity) hr"
        case .each:
            return "\(Int(lineItem.quantity))"
        case .bodyOfWater:
            return "\(Int(lineItem.quantity)) BOW"
        case .serviceLocation:
            return "\(Int(lineItem.quantity)) loc"
        case .percent:
            return "\(lineItem.quantity)%"
        }
    }
}

struct JobActualSummaryChip: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct JobActualDetailRow: View {
    var title: String
    var value: String
    var valueIsWarning: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(valueIsWarning ? .orange : .primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct JobActualEmptyMiniState: View {
    var title: String
    var message: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Formatters

enum JobActualMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }

    static func signedMoney(_ cents: Int) -> String {
        if cents == 0 {
            return "$0.00"
        }

        let prefix = cents > 0 ? "+" : "-"
        return prefix + money(abs(cents))
    }
}

enum JobActualTimeFormatter {
    static func minutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return "\(hours)h \(mins)m"
        }

        return "\(mins)m"
    }

    static func signedMinutes(_ minutes: Int) -> String {
        if minutes == 0 {
            return "0m"
        }

        let prefix = minutes > 0 ? "+" : "-"
        return prefix + Self.minutes(abs(minutes))
    }
}

enum JobActualDateFormatter {
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private extension View {
    func jobActualCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
