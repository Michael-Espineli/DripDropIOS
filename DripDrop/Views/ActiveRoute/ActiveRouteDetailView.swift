//
//  ActiveRouteDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/2/24.
//

import SwiftUI

@MainActor
final class ActiveRouteDetailViewModel: ObservableObject {
    private let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published private(set) var serviceStops: [ServiceStop] = []
    @Published private(set) var logs: [ActiveRouteLog] = []
    @Published private(set) var locations: [ActiveRouteLocation] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    func load(companyId: String, route: ActiveRoute) async {
        isLoading = true
        errorMessage = nil

        do {
            async let fetchedStops = dataService.getServiceStopsByIds(
                companyId: companyId,
                serviceStopIds: route.serviceStopsIds
            )
            async let fetchedLogs = dataService.getActiveRouteLogs(
                companyId: companyId,
                activeRouteId: route.id
            )
            async let fetchedLocations = dataService.getActiveRouteLocations(
                companyId: companyId,
                activeRouteId: route.id
            )

            let results = try await (fetchedStops, fetchedLogs, fetchedLocations)
            serviceStops = orderStops(results.0, route: route)
            logs = results.1
            locations = results.2
        } catch {
            errorMessage = "Could not load all trip details."
            print(error)
        }

        isLoading = false
    }

    private func orderStops(_ stops: [ServiceStop], route: ActiveRoute) -> [ServiceStop] {
        let stopsById = Dictionary(uniqueKeysWithValues: stops.map { ($0.id, $0) })

        let orderedStops = route.serviceStopsIds.compactMap { stopsById[$0] }
        let missingOrderStops = stops.filter { stop in
            !route.serviceStopsIds.contains(stop.id)
        }

        return orderedStops + missingOrderStops
    }
}

struct ActiveRouteDetailView: View {
    let dataService: any ProductionDataServiceProtocol
    let route: ActiveRoute

    @Environment(\.locale) private var locale
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @StateObject private var VM: ActiveRouteDetailViewModel

    init(dataService: any ProductionDataServiceProtocol, route: ActiveRoute) {
        self.dataService = dataService
        self.route = route
        _VM = StateObject(wrappedValue: ActiveRouteDetailViewModel(dataService: dataService))
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    summaryCard
                    serviceStopsCard
                    activityCard
                    Color.clear.frame(height: 24)
                }
                .padding(14)
            }
        }
        .navigationTitle(route.name.isEmpty ? "Trip Details" : route.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: route.id) {
            if let company = masterDataManager.currentCompany {
                await VM.load(companyId: company.id, route: route)
            }
        }
    }
}

extension ActiveRouteDetailView {
    var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "map.fill")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(statusTint(route.status))
                    .frame(width: 58, height: 58)
                    .background(statusTint(route.status).opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(route.name.isEmpty ? route.techName : route.name)
                        .font(.title3.weight(.bold))

                    Text(fullDate(date: route.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    routeStatusBadge(route.status)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                detailMetric("Stops", "\(route.finishedStops)/\(route.totalStops)", "checklist")
                detailMetric("Distance", tripMileageText, "gauge.with.dots.needle.bottom.50percent")
            }

            HStack(spacing: 8) {
                detailMetric("Started", route.startTime.map { time(date: $0) } ?? "Not set", "clock")
                detailMetric("Ended", route.endTime.map { time(date: $0) } ?? "Not set", "clock.badge.checkmark")
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var serviceStopsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Service Stops", "\(VM.serviceStops.count) loaded", "checklist")

            if VM.isLoading {
                loadingRow("Loading service stops...")
            } else if let errorMessage = VM.errorMessage {
                emptyRow("Details unavailable", errorMessage, "exclamationmark.triangle")
            } else if VM.serviceStops.isEmpty {
                emptyRow("No service stops", "This trip does not have service stops attached.", "list.bullet")
            } else {
                ForEach(Array(VM.serviceStops.enumerated()), id: \.element.id) { index, stop in
                    NavigationLink {
                        ServiceStopDetailView3(dataService: dataService, serviceStop: stop)
                    } label: {
                        serviceStopRow(stop, index: index + 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var activityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Trip Activity", "\(VM.logs.count) logs · \(VM.locations.count) GPS points", "waveform.path.ecg")

            HStack(spacing: 8) {
                detailMetric("Logs", "\(VM.logs.count)", "clock.badge")
                detailMetric("GPS", "\(VM.locations.count)", "location")
            }

            if let firstLog = VM.logs.first {
                activityRow(
                    "First Log",
                    detail: timeRangeText(start: firstLog.startTime, end: firstLog.endTime),
                    systemImage: "clock"
                )
            }

            if let latestLocation = VM.locations.last {
                activityRow(
                    "Last Location",
                    detail: fullDateAndTime(date: latestLocation.time),
                    systemImage: "location.fill"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var tripMileageText: String {
        let miles: Double

        if route.distanceMiles > 0 {
            miles = route.distanceMiles
        } else if let start = route.startMilage, let end = route.endMilage {
            miles = max(0, end - start)
        } else {
            miles = 0
        }

        return Measurement(value: miles, unit: UnitLength.miles)
            .formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))
    }

    func sectionTitle(_ title: String, _ subtitle: String, _ systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(Color.primary.opacity(0.045), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    func detailMetric(_ title: String, _ value: String, _ systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func serviceStopRow(_ stop: ServiceStop, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(0.045), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(stop.customerName.isEmpty ? "Service Stop" : stop.customerName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(stop.address.streetAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(stop.operationStatus.rawValue)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(stop.operationStatus == .finished ? .green : .secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func activityRow(_ title: String, detail: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(detail)
                    .font(.caption.weight(.semibold))
            }

            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private func routeStatusBadge(_ status: ActiveRouteStatus) -> some View {
    Text(status.rawValue)
        .font(.caption2.weight(.bold))
        .foregroundStyle(statusTint(status))
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(statusTint(status).opacity(0.13), in: Capsule())
}

private func statusTint(_ status: ActiveRouteStatus) -> Color {
    switch status {
    case .finished:
        return .green
    case .inProgress, .traveling:
        return .blue
    case .onBreak:
        return .orange
    case .didNotStart:
        return .secondary
    }
}

private func loadingRow(_ message: String) -> some View {
    HStack(spacing: 12) {
        ProgressView()
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
        Spacer()
    }
    .padding(12)
    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
}

private func emptyRow(_ title: String, _ message: String, _ systemImage: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: 34, height: 34)
            .background(Color.primary.opacity(0.045), in: Circle())

        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Spacer()
    }
    .padding(12)
    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
}

private func timeRangeText(start: Date, end: Date?) -> String {
    guard let end else {
        return time(date: start)
    }

    return "\(time(date: start)) - \(time(date: end))"
}

struct ActiveRouteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveRouteDetailView(
            dataService: MockDataService(),
            route: ActiveRoute(
                id: "",
                name: "Route Truck 1",
                date: Date(),
                serviceStopsIds: [],
                startTime: Date(),
                endTime: Date(),
                startMilage: 100,
                endMilage: 132,
                techId: "",
                techName: "Technician",
                traineeId: "",
                traineeName: "",
                durationMin: 120,
                distanceMiles: 32,
                status: .finished,
                totalStops: 8,
                finishedStops: 8,
                vehicalId: ""
            )
        )
    }
}
