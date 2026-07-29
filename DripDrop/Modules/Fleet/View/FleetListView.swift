//
//  FleetListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import SwiftUI

struct FleetListView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var fleetVM : FleetViewModel

    init(dataService:ProductionDataService){
    }
    @State var showSearch:Bool = false
    @State var searchTerm:String = ""
    @State var showAddVehical:Bool = false
    @State private var showFilters: Bool = false
    @State private var selectedType: VehicalType?
    @State private var selectedStatus: VehicalStatus?

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            list
            Text("")
                .sheet(isPresented: $showAddVehical, onDismiss: {
                    Task{
                        if let company = masterDataManager.currentCompany {
                            do {
                                try await fleetVM.getFleetList(companyId: company.id)
                            } catch {
                                print("Fleet Error")
                                print(error)
                            }
                        }
                    }
                }, content: {
                    AddNewVehical(dataService: dataService)
                })
        }
        .navigationTitle("Fleet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    withAnimation(.snappy) {
                        showSearch.toggle()
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                }

                Button {
                    withAnimation(.snappy) {
                        showFilters.toggle()
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }

                Button {
                    showAddVehical.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear(perform: {
            fleetVM.onLoadVehicalList(companyId: masterDataManager.currentCompany?.id)
        })
        .onDisappear(perform: {
            fleetVM.stop()
        })
//        .task {
//            if let company = masterDataManager.currentCompany {
//                do {
//                    try await fleetVM.getFleetList(companyId: company.id)
//                } catch {
//                    print("Fleet Error")
//                    print(error)
//                }
//            }
//        }
    }
}

struct FleetListView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()

    static var previews: some View {
        FleetListView(dataService: dataService)
    }
}
extension FleetListView {
    var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                fleetHeader

                if showSearch {
                    searchField
                }

                if showFilters {
                    filterControls
                }

                if fleetVM.listOfVehicals.isEmpty {
                    emptyState(
                        title: "No vehicles yet",
                        message: "Add the first vehicle to start tracking fleet mileage and trip history.",
                        buttonTitle: "Add First Vehicle"
                    )
                } else if filteredVehicals.isEmpty {
                    emptyState(
                        title: "No matches",
                        message: "Try a different search, type, or status filter.",
                        buttonTitle: "Clear Filters",
                        action: clearFilters
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredVehicals) { vehical in
                            vehicleRow(vehical)
                        }
                    }
                }

                Color.clear.frame(height: 18)
            }
            .padding(14)
        }
    }

    var filteredVehicals: [Vehical] {
        let needle = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return fleetVM.listOfVehicals
            .filter { vehical in
                let matchesSearch = needle.isEmpty || [
                    vehical.nickName,
                    vehical.vehicalType.rawValue,
                    vehical.year,
                    vehical.make,
                    vehical.model,
                    vehical.color,
                    vehical.plate,
                    vehical.status.rawValue
                ].contains { value in
                    value.lowercased().contains(needle)
                }

                let matchesType = selectedType == nil || vehical.vehicalType == selectedType
                let matchesStatus = selectedStatus == nil || vehical.status == selectedStatus

                return matchesSearch && matchesType && matchesStatus
            }
            .sorted {
                if $0.status != $1.status {
                    return $0.status.rawValue < $1.status.rawValue
                }

                return $0.nickName.localizedCaseInsensitiveCompare($1.nickName) == .orderedAscending
            }
    }

    var fleetHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Fleet")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)

                    Text("Vehicles, mileage, and recent trip history.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showAddVehical.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.semibold))
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Add Vehicle")
            }

            HStack(spacing: 8) {
                summaryPill("Total", "\(fleetVM.listOfVehicals.count)", "car.2.fill")
                summaryPill("Active", "\(fleetVM.listOfVehicals.filter { $0.status == .active }.count)", "checkmark.circle")
                summaryPill("Retired", "\(fleetVM.listOfVehicals.filter { $0.status == .retired }.count)", "archivebox")
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search nickname, plate, make, model", text: $searchTerm)
                .textInputAutocapitalization(.never)

            if !searchTerm.isEmpty {
                Button {
                    searchTerm = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear Search")
            }
        }
        .padding(13)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var filterControls: some View {
        VStack(spacing: 12) {
            Picker("Vehicle Type", selection: $selectedType) {
                Text("All Types").tag(VehicalType?.none)
                ForEach(VehicalType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(VehicalType?.some(type))
                }
            }
            .pickerStyle(.segmented)

            Picker("Status", selection: $selectedStatus) {
                Text("All").tag(VehicalStatus?.none)
                ForEach(VehicalStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(VehicalStatus?.some(status))
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func vehicleRow(_ vehical: Vehical) -> some View {
        Group {
            if UIDevice.isIPhone {
                NavigationLink(value: Route.vehicalDetailView(vehical:vehical,dataService: dataService), label: {
                    VehicleCardView(vehical: vehical)
                })
            } else {
                Button(action: {
                    masterDataManager.selectedCategory = .fleet
                    masterDataManager.selectedVehical = vehical
                }, label: {
                    VehicleCardView(vehical: vehical)
                })
            }
        }
        .buttonStyle(.plain)
    }

    func summaryPill(_ title: String, _ value: String, _ systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.caption.weight(.bold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func emptyState(
        title: String,
        message: String,
        buttonTitle: String,
        action: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "car.2")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 64, height: 64)
                .background(Color.poolBlue.opacity(0.10), in: Circle())

            Text(title)
                .font(.headline.weight(.semibold))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(buttonTitle) {
                if let action {
                    action()
                } else {
                    showAddVehical.toggle()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func clearFilters() {
        searchTerm = ""
        selectedType = nil
        selectedStatus = nil
    }
}
