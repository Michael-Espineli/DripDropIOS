//
//  CustomerStopDataDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/10/24.
//

import SwiftUI
@MainActor
final class CustomerStopDataDetailViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published private(set) var readingTemplates: [SavedReadingsTemplate] = []
    @Published private(set) var dosageTemplates: [SavedDosageTemplate] = []
    @Published private(set) var customer: Customer? = nil
    
    @Published var selectedLocation: ServiceLocation? = nil
    @Published private(set) var locations: [ServiceLocation] = []
    
    @Published var selectedBodyOfWater: BodyOfWater? = nil
    @Published private(set) var bodiesOfWater: [BodyOfWater] = []

    @Published private(set) var currentHistory: [StopData] = []

    
    func onLoad(companyId:String,customerId:String){
        Task{
            do {
                print("On Load")
                self.readingTemplates = try await dataService.getAllReadingTemplates(companyId: companyId)
                print("readingTemplates \(readingTemplates.count)")

                self.dosageTemplates = try await dataService.getAllDosageTemplates(companyId: companyId)
                print("dosageTemplates \(dosageTemplates.count)")

                self.locations = try await dataService.getAllCustomerServiceLocationsId(companyId: companyId, customerId: customerId)
                print("locations \(locations.count)")

                if !locations.isEmpty {
                    self.selectedLocation = locations.first!
                }
            } catch {
                print(error)
            }
        }
    }
    func onChangeOfServiceLocation(companyId:String,customerId:String){
        Task{
            do {
                if let selectedLocation {
                    print("selectedLocation")

                    self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocation(companyId: companyId, serviceLocation: selectedLocation)
                    if !bodiesOfWater.isEmpty {
                        self.selectedBodyOfWater = bodiesOfWater.first!
                    }
                } else {
                    print("not selectedLocation")

                }
            } catch {
                print(error)
            }
        }
    }
    func onChangeOfBodyOfWater(companyId:String,customerId:String){
        Task{
            do {
                if let selectedBodyOfWater {
                    print("selectedBodyOfWater")

                    self.currentHistory = try await dataService.getRecentServiceStopsByBodyOfWater(companyId: companyId, bodyOfWaterId: selectedBodyOfWater.id , amount: 20)
                    print("currentHistory \(currentHistory.count)")
                } else {
                    print("not selectedBodyOfWater")
                }
            } catch {
                print(error)
            }
        }
    }
}
struct CustomerStopDataDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var customerId:String
    @StateObject var VM : CustomerStopDataDetailViewModel
    init(dataService: any ProductionDataServiceProtocol,customerId:String) {
        _VM = StateObject(wrappedValue: CustomerStopDataDetailViewModel(dataService: dataService))
        _customerId = State(wrappedValue: customerId)
    }
    var body: some View {
        ZStack{
            Color.listColor
            VStack{
                form
            }
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(companyId: currentCompany.id, customerId: customerId)
            }
        }
        .onChange(of: VM.selectedLocation, perform: { location in
            if let currentCompany = masterDataManager.currentCompany {
                VM.onChangeOfServiceLocation(companyId: currentCompany.id, customerId: customerId)
            }
        })
        .onChange(of: VM.selectedBodyOfWater, perform: { BOW in
            if let currentCompany = masterDataManager.currentCompany {
                VM.onChangeOfBodyOfWater(companyId: currentCompany.id, customerId: customerId)
            }
        })
    }
}

#Preview {
    CustomerStopDataDetailView(dataService: MockDataService(), customerId: "")
}
extension CustomerStopDataDetailView {
    var form: some View {
        ScrollView{
            locationForm
            BOWForm
            table
        }
    }
    var locationForm: some View {
        VStack{
            Text("Location Form - \(VM.locations.count)")
                .font(.headline)
            if VM.locations.count == 1 {
                HStack{
                    if let selectedLocation = VM.selectedLocation {
                        Text(selectedLocation.address.streetAddress)
                            .font(.headline)
                    }
                    Spacer()
                }
            } else {
                if let selectedLocation = VM.selectedLocation {
                    HStack{
                            Text(selectedLocation.address.streetAddress)
                                .font(.headline)
                        
                        Spacer()
                        Button(action: {
                            VM.selectedLocation = nil
                        }, label: {
                                Text("Pick New")
                                    .modifier(ListButtonModifier())
                        })
                    }
                } else {
                    ForEach(VM.locations){ location in
                        Button(action: {
                            VM.selectedLocation = location
                        }, label: {
                            Text(location.address.streetAddress)
                                .modifier(ListButtonModifier())
                        })
                    }
                }
            }
        }
    }
    var BOWForm: some View {
        VStack{
            Text("BOW Form - \(VM.bodiesOfWater.count)")
                .font(.headline)
            if VM.bodiesOfWater.count == 1 {
                HStack{
                    if let selectedBodyOfWater = VM.selectedBodyOfWater {
                        Text(selectedBodyOfWater.name)
                            .font(.headline)
                    }
                    Spacer()
                }
            } else {
                if let selectedBodyOfWater = VM.selectedBodyOfWater {
                    HStack{
                            Text(selectedBodyOfWater.name)
                                .font(.headline)
                        
                        Spacer()
                        Button(action: {
                            VM.selectedBodyOfWater = nil
                        }, label: {
                                Text("Pick New")
                                    .modifier(ListButtonModifier())
                        })
                    }
                } else {
                    ForEach(VM.bodiesOfWater){ BOW in
                        Button(action: {
                            VM.selectedBodyOfWater = BOW
                        }, label: {
                            Text(BOW.name)
                                .modifier(ListButtonModifier())
                        })
                    }
                }
            }
        }
    }
    var table: some View {
        VStack{
            Text("Table")
                .font(.headline)
            if VM.selectedBodyOfWater != nil {
                if VM.currentHistory.count != 0 {
                    ScrollView(.horizontal,showsIndicators: false){
                        
                        StopDataTableView(
                            stopData: VM.currentHistory,
                            readingTemplates: VM.readingTemplates,
                            dosageTemplates: VM.dosageTemplates
                        )
                    }
                } else {
                    HStack{
                        Spacer()
                        Text("No Current History")
                        Spacer()
                    }
                    .modifier(DismissButtonModifier())
                }
            }
        }
    }
}
