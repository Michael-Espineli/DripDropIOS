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
            if isLoading {
                ProgressView()
            } else {
                VStack{
                    if let customer {
                        ScrollView(.horizontal, showsIndicators: false){
                            HStack{
                                Button(action: {
                                    showAddSheet.toggle()
                                }, label: {
                                    Image(systemName: "plus.square.on.square")
                                        .modifier(AddButtonModifier())
                                })
                                .confirmationDialog("Select Type", isPresented: self.$showNewLocationType, actions: {
                                    Button(action: {
                                        
                                    }, label: {
                                        Text("Schedule Estimate")
                                    })
                                    Button(action: {
                                        self.showAddSheet.toggle()
                                    }, label: {
                                        Text("Manually")
                                    })
                                })
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
                                if locations.count == 0 {
                                    Button(action: {
                                        showAddSheet.toggle()
                                    }, label: {
                                        Text("Add First Location")
                                    })
                                } else {
                                    ForEach(locations){ location in
                                        Button(action: {
                                            selectedLocation = nil
                                            selectedLocation = location
                                            masterDataManager.selectedServiceLocation = location
                                        }, label: {
                                            Text(location.address.streetAddress)
                                                .modifier(AddButtonModifier())
                                        })
                                        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                                    }
                                }
                            }
                        }
                    }
                    if selectedLocation == nil {
                        Text("Please select a location")
                    } else {
                            ServiceLocationDetailView(
                                dataService: dataService,
                                location: selectedLocation!,
                                onSave: { updatedLocation in
                                    upsertLocation(updatedLocation, select: true)
                                },
                                onDelete: { deletedLocationId in
                                    removeLocation(deletedLocationId)
                                }
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
