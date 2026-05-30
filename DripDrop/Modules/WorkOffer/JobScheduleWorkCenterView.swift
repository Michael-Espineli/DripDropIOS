//
//  JobScheduleWorkCenterView.swift
//  DripDrop
//

import SwiftUI

struct JobScheduleWorkCenterView: View {

    let companyId: String
    let currentUserId: String
    let currentUserName: String

    let job: Job
    let jobTasks: [JobTask]
    let serviceStops: [ServiceStop]
    let workOffers: [WorkOffer]
    let serviceLocation: ServiceLocation?

    let dataService: any ProductionDataServiceProtocol

    let onScheduleServiceStop: () -> Void
    let onGoToOffers: () -> Void
    let onReload: () -> Void

    private var acceptedOffersReadyToSchedule: [WorkOffer] {
        workOffers
            .filter {
                $0.status == .accepted &&
                $0.serviceStopId.isEmpty
            }
            .sorted { $0.acceptedAt ?? $0.createdAt > $1.acceptedAt ?? $1.createdAt }
    }

    private var openOffers: [WorkOffer] {
        workOffers
            .filter { $0.status.isOpen }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var scheduledOffers: [WorkOffer] {
        workOffers
            .filter {
                !$0.serviceStopId.isEmpty ||
                $0.status == .scheduled ||
                $0.status == .inProgress ||
                $0.status == .completed
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var finishedStops: [ServiceStop] {
        serviceStops.filter { $0.operationStatus == .finished }
    }

    private var unfinishedStops: [ServiceStop] {
        serviceStops.filter { $0.operationStatus != .finished }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                headerCard
                quickActionsCard
                acceptedOffersCard
                scheduledStopsCard
                openOffersCard
                scheduledOffersCard

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
        .background(Color.listColor.ignoresSafeArea())
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Work Schedule")
                        .font(.title3.weight(.semibold))

                    Text("Manage scheduled stops, accepted offers, and work that is still waiting on a contractor.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                JobScheduleSummaryChip(
                    title: "Stops",
                    value: "\(serviceStops.count)",
                    systemImage: "calendar"
                )

                JobScheduleSummaryChip(
                    title: "Ready",
                    value: "\(acceptedOffersReadyToSchedule.count)",
                    systemImage: "checkmark.circle"
                )

                JobScheduleSummaryChip(
                    title: "Open",
                    value: "\(openOffers.count)",
                    systemImage: "paperplane"
                )
            }

            HStack(spacing: 10) {
                JobScheduleSummaryChip(
                    title: "Unfinished",
                    value: "\(unfinishedStops.count)",
                    systemImage: "circle"
                )

                JobScheduleSummaryChip(
                    title: "Finished",
                    value: "\(finishedStops.count)",
                    systemImage: "checkmark.seal"
                )

                JobScheduleSummaryChip(
                    title: "Tasks",
                    value: "\(jobTasks.count)",
                    systemImage: "checklist"
                )
            }
        }
        .jobScheduleCard()
    }

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline.weight(.semibold))

            Button {
                onScheduleServiceStop()
            } label: {
                JobScheduleActionRow(
                    title: "Schedule Service Stop",
                    subtitle: "Create a service stop directly and assign work.",
                    systemImage: "calendar.badge.plus"
                )
            }
            .buttonStyle(.plain)

            Button {
                onGoToOffers()
            } label: {
                JobScheduleActionRow(
                    title: "Create / Manage Offers",
                    subtitle: "Offer work to contractors or post to the internal board.",
                    systemImage: "person.crop.circle.badge.plus"
                )
            }
            .buttonStyle(.plain)
        }
        .jobScheduleCard()
    }

    private var acceptedOffersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Accepted Offers Ready To Schedule", systemImage: "checkmark.circle")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(acceptedOffersReadyToSchedule.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if acceptedOffersReadyToSchedule.isEmpty {
                JobScheduleEmptyMiniState(
                    title: "No accepted offers waiting.",
                    message: "Accepted contractor work will appear here before it becomes a scheduled service stop.",
                    systemImage: "checkmark.circle"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(acceptedOffersReadyToSchedule) { offer in
                        NavigationLink {
                            WorkOfferDetailView(
                                companyId: companyId,
                                currentUserId: currentUserId,
                                currentUserName: currentUserName,
                                offer: offer,
                                jobTasks: jobTasks,
                                dataService: dataService,
                                onChanged: onReload
                            )
                        } label: {
                            JobScheduleOfferRow(
                                offer: offer,
                                emphasis: .readyToSchedule
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .jobScheduleCard()
    }

    private var scheduledStopsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Scheduled Service Stops", systemImage: "calendar")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(serviceStops.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if serviceStops.isEmpty {
                JobScheduleEmptyMiniState(
                    title: "No service stops scheduled.",
                    message: "Schedule work directly or create a service stop from an accepted work offer.",
                    systemImage: "calendar.badge.exclamationmark"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(serviceStops.sorted(by: { $0.serviceDate < $1.serviceDate })) { stop in
                        NavigationLink(
                            value: Route.serviceStop(
                                serviceStop: stop,
                                dataService: dataService
                            )
                        ) {
                            JobScheduleServiceStopRow(serviceStop: stop)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .jobScheduleCard()
    }

    private var openOffersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Open Offers", systemImage: "paperplane")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(openOffers.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if openOffers.isEmpty {
                JobScheduleEmptyMiniState(
                    title: "No open offers.",
                    message: "Direct contractor offers and board posts that are still waiting will appear here.",
                    systemImage: "tray"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(openOffers) { offer in
                        NavigationLink {
                            WorkOfferDetailView(
                                companyId: companyId,
                                currentUserId: currentUserId,
                                currentUserName: currentUserName,
                                offer: offer,
                                jobTasks: jobTasks,
                                dataService: dataService,
                                onChanged: onReload
                            )
                        } label: {
                            JobScheduleOfferRow(
                                offer: offer,
                                emphasis: .open
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .jobScheduleCard()
    }

    @ViewBuilder
    private var scheduledOffersCard: some View {
        if !scheduledOffers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Offer History", systemImage: "clock.arrow.circlepath")
                        .font(.headline.weight(.semibold))

                    Spacer()

                    Text("\(scheduledOffers.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }

                VStack(spacing: 10) {
                    ForEach(scheduledOffers) { offer in
                        NavigationLink {
                            WorkOfferDetailView(
                                companyId: companyId,
                                currentUserId: currentUserId,
                                currentUserName: currentUserName,
                                offer: offer,
                                jobTasks: jobTasks,
                                dataService: dataService,
                                onChanged: onReload
                            )
                        } label: {
                            JobScheduleOfferRow(
                                offer: offer,
                                emphasis: .history
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .jobScheduleCard()
        }
    }
}

// MARK: - Components

enum JobScheduleOfferEmphasis {
    case readyToSchedule
    case open
    case history
}

struct JobScheduleOfferRow: View {
    var offer: WorkOffer
    var emphasis: JobScheduleOfferEmphasis

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.body.weight(.semibold))
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(offer.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(offer.status.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label("\(offer.jobTaskIds.count)", systemImage: "checklist")
                    Label("\(offer.estimatedMinutes) min", systemImage: "clock")

                    if offer.offeredAmountCents > 0 {
                        Label(JobScheduleMoneyFormatter.money(offer.offeredAmountCents), systemImage: "dollarsign.circle")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 7)
        }
        .padding(12)
        .background(backgroundOpacity, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }

    private var iconName: String {
        switch emphasis {
        case .readyToSchedule:
            return "calendar.badge.plus"
        case .open:
            return offer.offerType.systemImage
        case .history:
            return "clock.arrow.circlepath"
        }
    }

    private var backgroundOpacity: Color {
        switch emphasis {
        case .readyToSchedule:
            return Color.accentColor.opacity(0.12)
        case .open:
            return Color.primary.opacity(0.05)
        case .history:
            return Color.primary.opacity(0.035)
        }
    }

    private var subtitle: String {
        switch offer.offerType {
        case .directUser:
            if offer.offeredToUserName.isEmpty {
                return "Direct user offer"
            }

            return "Offered to \(offer.offeredToUserName)"

        case .internalBoard:
            return "Board post • \(offer.boardVisibility.title)"

        case .externalCompany:
            return offer.externalCompanyName.isEmpty ? "External company offer" : offer.externalCompanyName
        }
    }
}

struct JobScheduleServiceStopRow: View {
    var serviceStop: ServiceStop

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: serviceStop.typeImage.isEmpty ? "calendar" : serviceStop.typeImage)
                .font(.body.weight(.semibold))
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(serviceStop.internalId)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(serviceStop.operationStatus.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(serviceStop.type.isEmpty ? "Service Stop" : serviceStop.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(JobScheduleDateFormatter.shortDateTime(serviceStop.serviceDate)) • \(serviceStop.tech.isEmpty ? "Unassigned" : serviceStop.tech)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
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

struct JobScheduleActionRow: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 32)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct JobScheduleSummaryChip: View {
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

struct JobScheduleEmptyMiniState: View {
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

enum JobScheduleMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

enum JobScheduleDateFormatter {
    static func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private extension View {
    func jobScheduleCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}