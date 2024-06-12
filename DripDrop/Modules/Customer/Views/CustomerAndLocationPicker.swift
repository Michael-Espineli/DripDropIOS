//
//  CustomerAndLocationPicker.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/12/24.
//



import SwiftUI

struct CustomerAndLocationPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var customerVM : CustomerViewModel
    @StateObject var locationVM : ServiceLocationViewModel
    
    @Binding var customer : Customer
    @Binding var location : ServiceLocation
    
    init(dataService:any ProductionDataServiceProtocol,customer:Binding<Customer>,location:Binding<ServiceLocation>){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _locationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))
        self._customer = customer
        self._location = location
        
    }
    
    @State var search:String = ""
    @State var customerSearch:String = ""
    
    @State var customers:[Customer] = []
    @State var locations:[ServiceLocation] = []
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if customer.id == "" {
                    HStack{
                        Spacer()
                        Button(action: {
                            customer.id = ""
                            
                            dismiss()
                        }, label: {
                            Image(systemName: "xmark")
                        })
                        .padding(16)
                    }
                    customerList
                    customerSearchBar
                    
                } else {
                    HStack{
                        Button(action: {
                            customer.id = ""
                        }, label: {
                            HStack{
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        })
                        .padding(16)
                        Spacer()
                    }
                    locationList
                    searchBar
                }
            }
        }
        .task {
            do {
                if let company = masterDataManager.selectedCompany {
                    try await customerVM.filterAndSortSelected(companyId: company.id, filter: .active, sort: .firstNameHigh)
                    customers = customerVM.customers
                }
            } catch {
                print("Error")
                
            }
        }
        .onChange(of: customerSearch, perform: { term in
            if term == "" {
                customers = customerVM.customers
                
            } else {
                
                customerVM.filterCustomerList(filterTerm: term, customers: customerVM.customers)
                customers = customerVM.filteredCustomers
                
            }
        })
        .onChange(of: search, perform: { term in
            if term == "" {
                
                locations = locationVM.serviceLocations
                
                
            } else {
                
                locationVM.filterLocationList(filterTerm: term, locations: locationVM.serviceLocations)
                locations = locationVM.serviceLocationsFiltered
                print("Received \(customers.count) Customers")
                
            }
        })
        .onChange(of: customer, perform: { customer in
            if customer.id != "" {
                Task{
                    do {
                        if let company = masterDataManager.selectedCompany {
                            try await locationVM.getAllCustomerServiceLocationsById(companyId: company.id, customerId: customer.id)
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
            }
        })
    }
}
extension CustomerAndLocationPicker {
    var searchBar: some View {
        TextField(
            text: $search,
            label: {
                Text("Search...")
            })
        .textFieldStyle(PlainTextFieldStyle())
        .font(.headline)
        .padding(8)
        .background(Color.white)
        .clipShape(Capsule())
        .foregroundColor(Color.basicFontText)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        
        
    }
    var customerSearchBar: some View {
        TextField(
            text: $customerSearch,
            label: {
                Text("Customer Search...")
            })
        .textFieldStyle(PlainTextFieldStyle())
        .font(.headline)
        .padding(8)
        .background(Color.white)
        .clipShape(Capsule())
        .foregroundColor(Color.basicFontText)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        
        
    }
    var customerList: some View {
        ScrollView{
            ForEach(customers){ datum in
                
                Button(action: {
                    customer = datum
                    
                }, label: {
                    HStack{
                        Spacer()
                        if datum.displayAsCompany {
                            Text("\(datum.company ?? "\(datum.firstName) \(datum.lastName)")")
                        } else {
                            Text("\(datum.firstName) \(datum.lastName)")
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal,8)
                    .foregroundColor(Color.basicFontText)
                })
                
                Divider()
            }
        }
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
