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
    @State var customer:Customer
    
    init(dataService:any ProductionDataServiceProtocol,customer:Customer){
        _locationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))
        _customer = State(wrappedValue: customer)
    }
    //Variables Received
    //Variables for use
    @State var locations:[ServiceLocation] = []
    @State var selectedLocation:ServiceLocation? = nil
    @State var isLoading:Bool = false
    @State var showAddSheet:Bool = false
    @State var showNewLocationType:Bool = false
    var body: some View {
        ZStack{
            if isLoading {
                ProgressView()
            } else {
                VStack{
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
                            .sheet(isPresented: $showAddSheet, content: {
                                AddServiceLocationView(dataService: dataService, customer: customer)
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
                    if selectedLocation == nil {
                        Text("Please select a location")
                    } else {
                            ServiceLocationDetailView(dataService: dataService, location: selectedLocation!)
                    }
                }
            }
        }
        .task{
            do {
                
                try await locationVM.getAllCustomerServiceLocationsById(companyId:masterDataManager.currentCompany!.id,customerId: customer.id)
                locations = locationVM.serviceLocations
                if locations.count != 0 {
                    selectedLocation = locations.first
                    masterDataManager.selectedServiceLocation = selectedLocation
                } else {
                    selectedLocation = nil
                    masterDataManager.selectedServiceLocation = selectedLocation
                }
                print("Successfully Loaded All Customer Locations")

            } catch{
                print("Error Loading Customer Locations")
                print(error)
            }
        }
        .onChange(of: masterDataManager.selectedCustomer, perform: { cus in
            Task{
                if let customer = cus{
                    
                    isLoading = true
                    do {
                        try await locationVM.getAllCustomerServiceLocationsById(companyId:masterDataManager.currentCompany!.id,customerId: customer.id)
                        locations = locationVM.serviceLocations
                        if locations.count != 0 {
                            selectedLocation = locations.first!
                            masterDataManager.selectedServiceLocation = locations.first!

                        } else {
                            selectedLocation = nil
                            masterDataManager.selectedServiceLocation = selectedLocation
                        }
                        print("Successfully Loaded All Customer Locations")
                    } catch{
                        print("Error Loading Customer Locations")
                        print(error)
                    }
                    isLoading = false
                }
            }
        })
    }
}

