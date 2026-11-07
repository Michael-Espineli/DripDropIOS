//
//  JobActualWorkView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//


import SwiftUI

struct JobActualWorkView: View {

    let companyId: String
    let currentUserId: String
    let currentUserName: String
    let job: Job
    let jobTasks: [JobTask]
    let serviceStops: [ServiceStop]
    let workOffers: [WorkOffer]
    let serviceLocation: ServiceLocation?
    let payLineItems: [TechnicianPayLineItem]
    let dataService: any ProductionDataServiceProtocol
    let onScheduleServiceStop: () -> Void
    let onEditServiceStop: (ServiceStop) -> Void
    let onDeleteServiceStop: (ServiceStop) -> Void
    let onReload: () -> Void
    var focusedSection = "offers"

    @State private var showPreviousStops = false
    @State private var showPayLines = false
    @State private var didRevealInitialSection = false

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

    private var openStops: [ServiceStop] {
        serviceStops.filter { $0.operationStatus == .notFinished }.sorted { $0.serviceDate < $1.serviceDate }
    }
    private var previousStops: [ServiceStop] {
        serviceStops.filter { $0.operationStatus != .notFinished }.sorted { $0.serviceDate > $1.serviceDate }
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
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    JobWorkOffersView(
                        companyId: companyId, currentUserId: currentUserId, currentUserName: currentUserName,
                        job: job, jobTasks: jobTasks, serviceLocation: serviceLocation, workOffers: workOffers,
                        dataService: dataService, onReload: onReload
                    )
                    .id("offers")
                    serviceStopsCard.id("serviceStops")
                    recordedActualsCard
                    comparisonCard
                }
                .padding(14)
            }
            .onAppear {
                guard !didRevealInitialSection else { return }
                didRevealInitialSection = true
                proxy.scrollTo(focusedSection, anchor: .top)
            }
            .onChange(of: focusedSection) { section in
                withAnimation { proxy.scrollTo(section, anchor: .top) }
            }
        }
        .background(Color.listColor.ignoresSafeArea())
    }

    private var serviceStopsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Label("Service Stops", systemImage: "calendar").font(.headline)
                Text("\(serviceStops.count)").font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Button(action: onScheduleServiceStop) {
                    Label("Schedule", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .frame(minHeight: 32)
                }
                .buttonStyle(WorkspaceOutlinedButtonStyle(tone: .blue))
                .tint(.poolBlue)
            }
            if openStops.isEmpty {
                Text("No open service stops.").font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(openStops) { stop in serviceStopRow(stop) }
            if !previousStops.isEmpty {
                DisclosureGroup("Previous stops (\(previousStops.count))", isExpanded: $showPreviousStops) {
                    VStack(spacing: 10) {
                        ForEach(previousStops) { stop in serviceStopRow(stop) }
                    }
                    .padding(.top, 8)
                }
                .font(.subheadline)
            }
        }
        .technicianPanel()
    }

    private func serviceStopRow(_ stop: ServiceStop) -> some View {
        HStack(spacing: 8) {
            NavigationLink(value: Route.serviceStop(serviceStop: stop, dataService: dataService)) {
                JobActualServiceStopRow(serviceStop: stop, payLineItems: payLineItemsByStopId[stop.id] ?? [])
            }
            .buttonStyle(.plain)
            if stop.operationStatus == .notFinished {
                Button { onEditServiceStop(stop) } label: {
                    Image(systemName: "square.and.pencil")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.poolBlue)
                .accessibilityLabel("Edit service stop \(stop.internalId.isEmpty ? stop.type : stop.internalId)")
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            if stop.operationStatus == .notFinished {
                Button("Edit service stop", systemImage: "pencil") { onEditServiceStop(stop) }
                Button("Delete service stop", systemImage: "trash", role: .destructive) { onDeleteServiceStop(stop) }
            }
        }
    }

    private var recordedActualsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recorded Actuals", systemImage: "dollarsign.circle").font(.headline)
                Spacer()
                Text(JobActualMoneyFormatter.money(actualPayrollCents)).font(.subheadline.weight(.semibold))
            }
            if needsReviewCount > 0 {
                Label("\(needsReviewCount) pay lines need review", systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.orange)
            }
            if payLineItems.isEmpty {
                Text("No recorded payroll.").font(.subheadline).foregroundStyle(.secondary)
            } else {
                DisclosureGroup("Payroll lines (\(payLineItems.count))", isExpanded: $showPayLines) {
                    VStack(spacing: 10) {
                        JobActualDetailRow(title: "Calculated / Approved / Paid", value: JobActualMoneyFormatter.money(calculatedPayrollCents))
                        ForEach(payLineItems) { JobActualPayLineRow(lineItem: $0) }
                    }
                    .padding(.top, 8)
                }
                .font(.subheadline)
            }
        }
        .technicianPanel()
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

}

// MARK: - Rows

struct JobActualServiceStopRow: View {
    var serviceStop: ServiceStop
    var payLineItems: [TechnicianPayLineItem]

    private var payTotalCents: Int {
        payLineItems.reduce(0) { $0 + $1.totalAmountCents }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(serviceStop.internalId.isEmpty ? (serviceStop.type.isEmpty ? "Service Stop" : serviceStop.type) : serviceStop.internalId)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 6)
                Text(serviceStop.operationStatus.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(serviceStop.operationStatus == .finished ? Color.poolGreen : Color.poolBlue)
            }
            if !serviceStop.type.isEmpty && !serviceStop.internalId.isEmpty {
                Text(serviceStop.type).font(.caption).foregroundStyle(.secondary)
            }
            Text("\(JobActualDateFormatter.shortDateTime(serviceStop.serviceDate)) · \(serviceStop.tech.isEmpty ? "Unassigned" : serviceStop.tech)")
                .font(.caption).foregroundStyle(.secondary)
            if !payLineItems.isEmpty {
                Text(JobActualMoneyFormatter.money(payTotalCents))
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
