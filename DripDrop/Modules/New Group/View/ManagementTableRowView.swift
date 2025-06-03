//
//  ManagementTableRowView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/5/24.
//

import SwiftUI
@MainActor
final class ManagementTableCustomerRowViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var serviceLocationList:[ServiceLocation] = []
    func onLoad(companyId:String,customerId:String) async throws {
        self.serviceLocationList = try await dataService.getAllCustomerServiceLocationsId(companyId: companyId, customerId: customerId)
    }
}
struct ManagementTableCustomerRowView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject var VM : ManagementTableCustomerRowViewModel
    @State var customer : Customer
    init(dataService:any ProductionDataServiceProtocol, customer:Customer){
        _VM = StateObject(wrappedValue: ManagementTableCustomerRowViewModel(dataService: dataService))
        _customer = State(wrappedValue: customer)
    }
    var body: some View {
        VStack{
            if !VM.serviceLocationList.isEmpty {
                ForEach(VM.serviceLocationList){ location in
                    HStack{
                        Text("\(customer.firstName) \(customer.lastName)")
                        ManagementTableServiceLocationRowView(dataService: dataService, customer: customer, serviceLocation: location)
                    }
                }
            } else {
                HStack{
                    Text("\(customer.firstName) \(customer.lastName)")
                    Spacer()
                }
            }
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, customerId: customer.id)
                } catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
    ManagementTableCustomerRowView(dataService: MockDataService(),customer: MockDataService.mockCustomer)
}


@MainActor
final class ManagementTableServiceLocationRowViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    func onLoad(companyId:String,customerId:String,serviceLocationId:String) async throws {
    }
}
struct ManagementTableServiceLocationRowView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var VM : ManagementTableServiceLocationRowViewModel
    @State var serviceLocation : ServiceLocation
    @State var customer : Customer
    
    init(dataService:any ProductionDataServiceProtocol,customer:Customer, serviceLocation:ServiceLocation){
        _VM = StateObject(wrappedValue: ManagementTableServiceLocationRowViewModel(dataService: dataService))
        _serviceLocation = State(wrappedValue: serviceLocation)
        _customer = State(wrappedValue: customer)
    }
    var body: some View {
        ZStack{
            row
        }
    }
}
#Preview {
    ManagementTableCustomerRowView(dataService: MockDataService(),customer: MockDataService.mockCustomer)
}

extension ManagementTableServiceLocationRowView {
    var row: some View {
        HStack{
            Text("\(serviceLocation.address.streetAddress)")
            Text("\(serviceLocation.address.city)")
            Text("\(serviceLocation.address.state)")
            Text("\(serviceLocation.address.zip)")
            Spacer()
        }
    }
}
