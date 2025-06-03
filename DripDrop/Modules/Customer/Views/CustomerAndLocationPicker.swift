//
//  CustomerAndLocationPicker.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/12/24.
//



import SwiftUI
@MainActor
final class CustomerAndLocationPickerModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var displayCustomer: [Customer] = []
    @Published private(set) var customers: [Customer] = []
    @Published var searchTerm: String = ""
    @Published private(set) var serviceLocations: [ServiceLocation] = []

    func onLoad(companyId:String) {
        Task{
            do {
                self.customers = try await dataService.getCustomersActiveAndLastName(companyId: companyId, active: true, lastNameHigh: false)

                self.displayCustomer = customers
            } catch {
                print(error)
            }
        }
    }
    func filterCustomerList() {
        //very facncy Search Bar
        if searchTerm != "" {
            var filteredListOfCustomers:[Customer] = []
            
            for customer in customers {
                let phone = customer.phoneNumber ?? "0"
                let replacedPhone1 = phone.replacingOccurrences(of: ".", with: "")
                let replacedPhone2 = replacedPhone1.replacingOccurrences(of: "-", with: "")
                let replacedPhone3 = replacedPhone2.replacingOccurrences(of: " ", with: "")
                let replacedPhone4 = replacedPhone3.replacingOccurrences(of: ".", with: "")
                let replacedPhone5 = replacedPhone4.replacingOccurrences(of: "(", with: "")
                let replacedPhone6 = replacedPhone5.replacingOccurrences(of: ")", with: "")
                
                let address = (customer.billingAddress.streetAddress ) + " " + (customer.billingAddress.city ) + " " + (customer.billingAddress.state ) + " " + (customer.billingAddress.zip )
                let company:String = customer.company ?? "0"
                let fullName = customer.firstName + " " + customer.lastName
                if customer.firstName.lowercased().contains(searchTerm.lowercased()) || customer.lastName.lowercased().contains(searchTerm.lowercased()) || replacedPhone6.lowercased().contains(searchTerm.lowercased()) || customer.email.lowercased().contains(searchTerm.lowercased()) || address.lowercased().contains(searchTerm.lowercased()) || company.lowercased().contains(searchTerm.lowercased()) || fullName.lowercased().contains(searchTerm.lowercased()){
                    filteredListOfCustomers.append(customer)
                }
            }
            self.displayCustomer = filteredListOfCustomers
        } else {
            self.displayCustomer = customers
        }
    }
    func getAllCustomerServiceLocationsById(
        companyId: String,
        customerId:String
    ) async throws {
        self.serviceLocations = try await dataService.getAllCustomerServiceLocationsId(
            companyId: companyId,
            customerId: customerId
        )
  
    }
}
struct CustomerAndLocationPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var VM : CustomerAndLocationPickerModel

    @Binding var customer : Customer
    @Binding var location : ServiceLocation
    
    init(dataService:any ProductionDataServiceProtocol,customer:Binding<Customer>,location:Binding<ServiceLocation>){
        _VM = StateObject(wrappedValue: CustomerAndLocationPickerModel(dataService: dataService))

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
                    customerList
                    searchBar
                } else {
                    HStack{
                        Button(action: {
                            customer.id = ""
                        }, label: {
                            HStack{
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .modifier(DismissButtonModifier())
                        })
                        .padding(8)
                        Spacer()
                    }
                    locationList
                    searchBar
                }
            }
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    VM.onLoad(companyId: company.id)
                }
            } catch {
                print("Error")
                
            }
        }
        .onChange(of: VM.searchTerm, perform: { term in
            VM.filterCustomerList()
        })
        .onChange(of: customer, perform: { customer in
            if customer.id != "" {
                Task{
                    do {
                        if let company = masterDataManager.currentCompany {
                            try await VM.getAllCustomerServiceLocationsById(companyId: company.id, customerId: customer.id)

                            if VM.serviceLocations.count == 1 {
                                location = VM.serviceLocations.first!
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
            text: $VM.searchTerm,
            label: {
                Text("Search...")
            })
        .modifier(SearchTextFieldModifier())
        .padding(8)
    }
    var customerSearchBar: some View {
        HStack{
            TextField(
                text: $customerSearch,
                label: {
                    Text("Customer Search...")
                })
            Button(action: {
                customerSearch = ""
            }, label: {
                Image(systemName: "xmark")
            })
        }
        .textFieldStyle(PlainTextFieldStyle())
        .font(.headline)
        .padding(8)
        .background(Color.white)
        .clipShape(Capsule())
        .foregroundColor(Color.black)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        
        
    }
    var customerList: some View {
        ScrollView{
            ForEach(VM.displayCustomer){ datum in
                
                Button(action: {
                    customer = datum
                }, label: {
                    HStack{
                        if datum.displayAsCompany {
                            Text("\(datum.company ?? "\(datum.firstName) \(datum.lastName)")")
                        } else {
                            Text("\(datum.firstName) \(datum.lastName)")
                        }
                        
                        Spacer()
                    }
                    .modifier(ListButtonModifier())
                })
                .padding(8)
            }
        }
    }
    var locationList: some View {
        ScrollView{
            ForEach(VM.serviceLocations){ datum in
                
                Button(action: {
                    location = datum
                    dismiss()
                }, label: {
                    HStack{
                        Spacer()
                        Text("\(datum.address.streetAddress)")
                        Spacer()
                    }
                    .modifier(ListButtonModifier())
                })
                .padding(8)
            }
        }
        .padding(16)
    }
}
