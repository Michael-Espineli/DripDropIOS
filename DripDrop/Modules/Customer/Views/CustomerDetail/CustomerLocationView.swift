//
//  CustomerLocationView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI
import Darwin
struct CustomerLocationView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    //View Models
    @StateObject var locationVM : ServiceLocationViewModel
    @EnvironmentObject var VM : CustomerListViewModel
    private var customer: Customer? {
        VM.customers.first { $0.id == customerId }
    }
    @State var customerId: String
    init(dataService:any ProductionDataServiceProtocol,customerId:String){
        _locationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))
        _customerId = State(wrappedValue: customerId)
    }
    //Variables Received
    //Variables for use
    @State var locations:[ServiceLocation] = []
    @State var selectedLocation:ServiceLocation? = nil
    @State var isLoading:Bool = false
    @State var showAddSheet:Bool = false
    @State var showNewLocationType:Bool = false
    @State private var pendingSelectedLocationId:String? = nil
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                VStack(spacing: 12) {
                    if let customer {
                        locationSelector(customer)
                    } else {
                        unavailableCard(
                            title: "No Customer",
                            message: "Select a customer before adding a service location.",
                            systemImage: "person.crop.circle.badge.questionmark"
                        )
                    }

                    if let selectedLocation {
                        ServiceLocationDetailView(
                            dataService: dataService,
                            location: selectedLocation,
                            onSave: { updatedLocation in
                                upsertLocation(updatedLocation, select: true)
                            },
                            onDelete: { deletedLocationId in
                                removeLocation(deletedLocationId)
                            }
                        )
                    } else {
                        unavailableCard(
                            title: locations.isEmpty ? "No Locations Yet" : "Select a Location",
                            message: locations.isEmpty ? "Add the first service location for this customer." : "Choose a service location above to view details.",
                            systemImage: locations.isEmpty ? "plus.viewfinder" : "mappin.and.ellipse"
                        )
                    }
                }
            }
        }
        .task{
            await refreshLocations()
        }
        .onChange(of: masterDataManager.selectedCustomer, perform: { cus in
            Task{
                if let customer = cus{
                    
                    isLoading = true
                    await refreshLocations(for: customer.id)
                    isLoading = false
                }
            }
        })
    }
}

extension CustomerLocationView {
    private func locationSelector(_ customer: Customer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "house.and.flag.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 34, height: 34)
                    .background(Color.poolBlue.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Service Locations")
                        .font(.headline.weight(.semibold))

                    Text("\(locations.count) \(locations.count == 1 ? "location" : "locations") on file")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showAddSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.poolGreen, in: Circle())
                }
                .buttonStyle(.plain)
            }

            if locations.isEmpty {
                Button {
                    showAddSheet.toggle()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.poolGreen)

                        Text("Add First Location")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.poolGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(locations) { location in
                            locationChip(location)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
        .sheet(isPresented: $showAddSheet, onDismiss: {
            Task {
                await refreshLocations(selecting: pendingSelectedLocationId)
                pendingSelectedLocationId = nil
            }
        }, content: {
            AddServiceLocationView(dataService: dataService, customer: customer) { newLocationId in
                pendingSelectedLocationId = newLocationId
            }
        })
    }

    private func locationChip(_ location: ServiceLocation) -> some View {
        let isSelected = selectedLocation?.id == location.id

        return Button {
            selectedLocation = location
            masterDataManager.selectedServiceLocation = location
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "mappin.circle.fill" : "mappin.circle")
                    .font(.caption.weight(.semibold))

                VStack(alignment: .leading, spacing: 1) {
                    Text(locationTitle(location))
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)

                    Text(locationDetail(location))
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.primary.opacity(0.035)),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func unavailableCard(title: String, message: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    private func locationTitle(_ location: ServiceLocation) -> String {
        let nickname = location.nickName.trimmingCharacters(in: .whitespacesAndNewlines)
        let street = location.address.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        if !nickname.isEmpty {
            return nickname
        }

        return street.isEmpty ? "Unnamed Location" : street
    }

    private func locationDetail(_ location: ServiceLocation) -> String {
        let detail = [
            location.address.city,
            location.address.state,
            location.address.zip
        ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return detail.isEmpty ? "No address details" : detail
    }

    @MainActor
    private func refreshLocations(for refreshedCustomerId:String? = nil, selecting preferredLocationId:String? = nil) async {
        guard let companyId = masterDataManager.currentCompany?.id else { return }
        let resolvedCustomerId = refreshedCustomerId ?? customerId

        do {
            try await locationVM.getAllCustomerServiceLocationsById(companyId: companyId, customerId: resolvedCustomerId)
            locations = locationVM.serviceLocations

            let selected = locations.first { $0.id == preferredLocationId }
                ?? locations.first { $0.id == selectedLocation?.id }
                ?? locations.first

            selectedLocation = selected
            masterDataManager.selectedServiceLocation = selected

            print("")
            print("[CustomerLocationView][refreshLocations] locationVM.serviceLocations Count: \(locationVM.serviceLocations.count)")
            print("Successfully Loaded All Customer Locations")
        } catch {
            print("")
            print("[CustomerLocationView][refreshLocations] Error: \(error)")
        }
    }

    private func upsertLocation(_ location:ServiceLocation, select:Bool) {
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index] = location
        } else {
            locations.append(location)
        }

        if select {
            selectedLocation = location
            masterDataManager.selectedServiceLocation = location
        }
    }

    private func removeLocation(_ locationId:String) {
        locations.removeAll { $0.id == locationId }
        let nextLocation = locations.first
        selectedLocation = nextLocation
        masterDataManager.selectedServiceLocation = nextLocation
    }
}
