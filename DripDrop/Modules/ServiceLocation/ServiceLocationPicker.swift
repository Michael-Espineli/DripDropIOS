//
//  ServiceLocationPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/4/24.
//

import SwiftUI

struct ServiceLocationPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var locationVM : ServiceLocationViewModel
    
    @Binding var location : ServiceLocation
    @State var customerId : String

    init(dataService:any ProductionDataServiceProtocol,customerId:String,location:Binding<ServiceLocation>){
        _locationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))
        self._location = location
        _customerId = State(wrappedValue: customerId)
    }
    
    @State var search:String = ""
    @State var customerSearch:String = ""
    
    @State var customers:[Customer] = []
    @State var locations:[ServiceLocation] = []
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{

                    searchBar
                    locationList
                    
                
            }
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await locationVM.getAllCustomerServiceLocationsById(companyId: company.id, customerId: customerId)
                    locations = locationVM.serviceLocations
                    if locations.count == 1 {
                        location = locations.first!
                        dismiss()
                    }
                }
            } catch {
                print(error)
            }
        }
        .onChange(of: search, perform: { term in
            if term == "" {
                
                locations = locationVM.serviceLocations
                
                
            } else {
                
                locationVM.filterLocationList(filterTerm: term, locations: locationVM.serviceLocations)
                locations = locationVM.serviceLocationsFiltered
                print("Received \(customers.count) Customers")
                
            }
        })
    }
}
extension ServiceLocationPicker {
    var searchBar: some View {
        TextField(
            text: $search,
            label: {
                Text("Search...")
            })
        .modifier(SearchTextFieldModifier())
        .padding(8)
    }

    var locationList: some View {
        ScrollView{
            ForEach(locations){ datum in
                
                Button(action: {
                    location = datum
                    dismiss()
                }, label: {
                    HStack{
                        Spacer()
                        Text("\(datum.address.streetAddress)")
                        Spacer()
                    }
                    .padding(.horizontal,8)
                    .foregroundColor(Color.basicFontText)
                })
                
                Divider()
            }
        }
    }
}
