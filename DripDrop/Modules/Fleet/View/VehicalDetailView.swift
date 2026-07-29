//
//  FleetDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import SwiftUI

@MainActor
final class VehicalDetailViewModel: ObservableObject {
    private let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published private(set) var routes: [ActiveRoute] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    func onLoad(companyId: String, vehicalId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            routes = try await dataService.getAllActiveRoutesBasedOnVehical(
                companyId: companyId,
                vehicalId: vehicalId,
                count: 5
            )
        } catch {
            errorMessage = "Could not load recent trips."
            print(error)
        }

        isLoading = false
    }

    func loadTrips(
        companyId: String,
        vehicalId: String,
        startDate: Date,
        endDate: Date
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            routes = try await dataService.getActiveRoutesForVehical(
                companyId: companyId,
                vehicalId: vehicalId,
                startDate: startDate,
                endDate: endDate,
                limit: 100
            )
        } catch {
            errorMessage = "Could not load trips for this date range."
            print(error)
        }

        isLoading = false
    }
}

struct VehicalDetailView: View {
    init(dataService: any ProductionDataServiceProtocol, vehicalId: String) {
        _vehicalId = State(initialValue: vehicalId)
        _VM = StateObject(wrappedValue: VehicalDetailViewModel(dataService: dataService))
    }

    @Environment(\.locale) private var locale
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var fleetVM: FleetViewModel
    @EnvironmentObject private var dataService: ProductionDataService

    @StateObject private var VM: VehicalDetailViewModel
    @State private var vehicalId: String
    @State private var showSheet: Bool = false

    private var vehical: Vehical? {
        fleetVM.listOfVehicals.first { $0.id == vehicalId }
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            if let vehical {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        vehicleSummaryCard(vehical)
                        recentTripsSection(vehical)
                        Color.clear.frame(height: 24)
                    }
                    .padding(14)
                }
            } else {
                emptyVehicleState
            }

            Text("")
                .sheet(isPresented: $showSheet) {
                    if let vehical {
                        EditVehicalView(dataService: dataService, vehical: vehical)
                    }
                }
        }
        .navigationTitle(vehical?.nickName.isEmpty == false ? vehical?.nickName ?? "Vehicle" : "Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: vehical?.id) {
            if let currentCompany = masterDataManager.currentCompany, let vehical {
                await VM.onLoad(companyId: currentCompany.id, vehicalId: vehical.id)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showSheet.toggle()
                }
                .disabled(vehical == nil)
            }
        }
    }
}

extension VehicalDetailView {
    func vehicleSummaryCard(_ vehical: Vehical) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: vehicleIconName(for: vehical))
                    .font(.title.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 58, height: 58)
                    .background(Color.poolBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(vehical.nickName.isEmpty ? "Unnamed Vehicle" : vehical.nickName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(vehicleDescription(for: vehical).isEmpty ? vehical.vehicalType.rawValue : vehicleDescription(for: vehical))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    statusBadge(vehical.status)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                detailMetric("Miles", mileageText(vehical.miles), "gauge.with.dots.needle.bottom.50percent")
                detailMetric("Plate", vehical.plate.isEmpty ? "Not set" : vehical.plate, "rectangle.on.rectangle")
            }

            HStack(spacing: 8) {
                detailMetric("Purchased", fullDate(date: vehical.datePurchased), "calendar")
                detailMetric("Type", vehical.vehicalType.rawValue, "car")
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func recentTripsSection(_ vehical: Vehical) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Recent Trip History")
                        .font(.headline.weight(.semibold))

                    Text("Latest active routes tied to this vehicle.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                NavigationLink {
                    VehicleTripHistoryView(dataService: dataService, vehical: vehical)
                } label: {
                    HStack(spacing: 4) {
                        Text("More")
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                    }
                    .font(.caption.weight(.bold))
                }
            }

            if VM.isLoading {
                loadingRow("Loading recent trips...")
            } else if let errorMessage = VM.errorMessage {
                emptyRow("Trips unavailable", errorMessage, "exclamationmark.triangle")
            } else if VM.routes.isEmpty {
                emptyRow("No recent trips", "This vehicle does not have route trip history yet.", "map")
            } else {
                ForEach(VM.routes) { route in
                    NavigationLink {
                        ActiveRouteDetailView(dataService: dataService, route: route)
                    } label: {
                        FleetTripCard(route: route)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var emptyVehicleState: some View {
        VStack(spacing: 10) {
            Image(systemName: "car")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Vehicle not found")
                .font(.headline.weight(.semibold))

            Text("Go back to Fleet and select the vehicle again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
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

    func mileageText(_ miles: Double) -> String {
        Measurement(value: miles, unit: UnitLength.miles)
            .formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))
    }
}

struct VehicleTripHistoryView: View {
    let dataService: any ProductionDataServiceProtocol
    let vehical: Vehical

    @EnvironmentObject private var masterDataManager: MasterDataManager
    @StateObject private var VM: VehicalDetailViewModel
    @State private var startDate: Date
    @State private var endDate: Date

    init(dataService: any ProductionDataServiceProtocol, vehical: Vehical) {
        self.dataService = dataService
        self.vehical = vehical
        _VM = StateObject(wrappedValue: VehicalDetailViewModel(dataService: dataService))
        _startDate = State(initialValue: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
        _endDate = State(initialValue: Date())
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    filtersCard
                    tripResultsCard
                    Color.clear.frame(height: 24)
                }
                .padding(14)
            }
        }
        .navigationTitle("Trip History")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: vehical.id) {
            await loadTrips()
        }
    }

    var filtersCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(vehical.nickName.isEmpty ? "Vehicle Trips" : vehical.nickName)
                    .font(.title3.weight(.bold))

                Text("Pick a date range before loading all trip history.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            DatePicker("Start", selection: $startDate, displayedComponents: .date)
            DatePicker("End", selection: $endDate, displayedComponents: .date)

            Button {
                Task {
                    await loadTrips()
                }
            } label: {
                Label("Load Trips", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(startDate > endDate || VM.isLoading)

            if startDate > endDate {
                Label("Start date must be before the end date.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var tripResultsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("All Trip History")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(VM.routes.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.primary.opacity(0.045), in: Capsule())
            }

            if VM.isLoading {
                loadingRow("Loading trips...")
            } else if let errorMessage = VM.errorMessage {
                emptyRow("Trips unavailable", errorMessage, "exclamationmark.triangle")
            } else if VM.routes.isEmpty {
                emptyRow("No trips in range", "Adjust the date filters and try again.", "calendar.badge.exclamationmark")
            } else {
                ForEach(VM.routes) { route in
                    NavigationLink {
                        ActiveRouteDetailView(dataService: dataService, route: route)
                    } label: {
                        FleetTripCard(route: route)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func loadTrips() async {
        guard startDate <= endDate,
              let company = masterDataManager.currentCompany else { return }

        await VM.loadTrips(
            companyId: company.id,
            vehicalId: vehical.id,
            startDate: startDate,
            endDate: endDate
        )
    }
}

struct FleetTripCard: View {
    @Environment(\.locale) private var locale

    let route: ActiveRoute

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "map.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(statusTint(route.status))
                .frame(width: 42, height: 42)
                .background(statusTint(route.status).opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(route.name.isEmpty ? route.techName : route.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(fullDate(date: route.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    statusBadge(route.status)
                }

                HStack(spacing: 8) {
                    tripMetric("Stops", "\(route.finishedStops)/\(route.totalStops)", "checklist")
                    tripMetric("Miles", tripMileageText, "gauge.with.dots.needle.bottom.50percent")
                    tripMetric("Time", tripTimeText, "clock")
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    var tripTimeText: String {
        if let start = route.startTime, let end = route.endTime {
            return displayMinAsMinAndHour(min: minBetween(start: start, end: end))
        }

        if route.durationMin > 0 {
            return displayMinAsMinAndHour(min: route.durationMin)
        }

        return "Not set"
    }

    func tripMetric(_ title: String, _ value: String, _ systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private func vehicleIconName(for vehical: Vehical) -> String {
    switch vehical.vehicalType {
    case .car:
        return "car.fill"
    case .truck:
        return "box.truck.fill"
    case .van:
        return "bus.fill"
    }
}

private func vehicleDescription(for vehical: Vehical) -> String {
    [
        vehical.color,
        vehical.year,
        vehical.make,
        vehical.model
    ]
    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    .joined(separator: " ")
}

private func statusBadge(_ status: VehicalStatus) -> some View {
    Text(status.rawValue)
        .font(.caption2.weight(.bold))
        .foregroundStyle(status == .active ? .green : .secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background((status == .active ? Color.green : Color.secondary).opacity(0.13), in: Capsule())
}

private func statusBadge(_ status: ActiveRouteStatus) -> some View {
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
