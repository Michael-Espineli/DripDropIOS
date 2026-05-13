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
    @Published var showLocationPicker: Bool = false
    @Published var showBOWPicker: Bool = false

    @Published private(set) var readingTemplates: [SavedReadingsTemplate] = []
    @Published private(set) var dosageTemplates: [SavedDosageTemplate] = []
    @Published private(set) var customer: Customer? = nil
    
    @Published var selectedLocation: ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0),
        gateCode: "",
        mainContact: Contact(
            id: "",
            name: "",
            phoneNumber: "",
            email: ""
        ),
        bodiesOfWaterId: [],
        rateType: "",
        laborType: "",
        chemicalCost: "",
        laborCost: "",
        rate: "",
        customerId: "",
        customerName: "",
        isActive: true
    )
    @Published private(set) var locations: [ServiceLocation] = []
    
    @Published var selectedBodyOfWater: BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        lastFilled: Date(),
        isActive: true
    )
    @Published private(set) var bodiesOfWater: [BodyOfWater] = []

    @Published private(set) var currentHistory: [StopData] = []

    
    func onLoad(companyId:String,customerId:String){
        Task{
            do {
                print("[CustomerStopDataDetailViewModel][onLoad] On Load")
                self.readingTemplates = try await dataService.getAllReadingTemplates(companyId: companyId)
                print("[CustomerStopDataDetailViewModel][onLoad] readingTemplates \(readingTemplates.count)")

                self.dosageTemplates = try await dataService.getAllDosageTemplates(companyId: companyId)
                print("[CustomerStopDataDetailViewModel][onLoad] dosageTemplates \(dosageTemplates.count)")

                self.locations = try await dataService.getAllCustomerServiceLocationsId(companyId: companyId, customerId: customerId)
                print("[CustomerStopDataDetailViewModel][onLoad] locations \(locations.count)")

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
                print("[CustomerStopDataDetailViewModel][onChangeOfServiceLocation] selectedLocation \(selectedLocation.id)")
                if selectedLocation.id.isEmpty {
                    self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocation(companyId: companyId, serviceLocation: selectedLocation)
                    if !bodiesOfWater.isEmpty {
                        self.selectedBodyOfWater = bodiesOfWater.first!
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    func onChangeOfBodyOfWater(companyId:String,customerId:String){
        Task{
            do {
                print("[CustomerStopDataDetailViewModel][onChangeOfServiceLocation] selectedBodyOfWater: \(selectedBodyOfWater.id)")
                if selectedBodyOfWater.id != "" {
                    self.currentHistory = try await dataService.getRecentServiceStopsByBodyOfWater(companyId: companyId, bodyOfWaterId: selectedBodyOfWater.id , amount: 20)
                }
            } catch {
                print(error)
            }
        }
    }
    func loadTestData(companyId:String,customerId:String) {
        Task {
            do {
                print("")
                print("[CustomerStopDataViewModel][loadTestData] Trying to upload test data")

                let increment = 1...10
                var count = 0
                let dosageTemplates = try await dataService.getAllDosageTemplates(companyId: companyId)
                let readingTemplate = try await dataService.getAllReadingTemplates(companyId: companyId)
                var stopData:[StopData] = []
                if selectedLocation.id != "" && selectedBodyOfWater.id != "" {
                    for number in increment {
                        print("[CustomerStopDataViewModel][loadTestData] Number: \(number)")
                        var readings:[Reading] = []
                        var dosages:[Dosage] = []
                        for readingTemplate in readingTemplates {
                            readings.append(
                                Reading(
                                    id: UUID().uuidString,
                                    templateId: readingTemplate.id,
                                    universalTemplateId: readingTemplate.readingsTemplateId,
                                    dosageType: readingTemplate.chemType,
                                    name: readingTemplate.name,
                                    amount: String(Int.random(in: 1...10)),
                                    UOM: readingTemplate.UOM,
                                    bodyOfWaterId: selectedBodyOfWater.id
                                )
                            )
                        }
                        
                        for dosageTemplate in dosageTemplates {
                            dosages.append(
                                Dosage(
                                    id: UUID().uuidString,
                                    templateId: dosageTemplate.id,
                                    universalTemplateId: dosageTemplate.dosageTemplateId,
                                    name: dosageTemplate.name,
                                    amount: String(Int.random(in: 1...10)),
                                    UOM: dosageTemplate.UOM,
                                    rate: dosageTemplate.rate,
                                    linkedItem: nil,
                                    bodyOfWaterId: selectedBodyOfWater.id
                                )
                            )
                        }
                        
                        let newDate = Calendar.current.date(byAdding: DateComponents(month: 0, day: -count), to: Date())!
                        stopData.append(
                            StopData(
                                id: UUID().uuidString,
                                date: newDate,
                                serviceStopId: "comp_ss_" + UUID().uuidString,
                                readings: readings,
                                dosages: dosages,
                                observation: [
                                    "Clear"
                                ],
                                bodyOfWaterId: selectedBodyOfWater.id,
                                customerId: customerId,
                                serviceLocationId: selectedLocation.id,
                                userId: "",
                                equipmentMeasurements: []
                            )
                        )
                        count += 7
                    }
                }
                for data in stopData {
                    try await dataService.uploadStopData(companyId: companyId, stopData: data)
                    print("[CustomerStopDataViewModel][loadTestData] Uploaded: \(fullDate(date: data.date))")
                }
            } catch {
                print("[CustomerStopDataDetailViewModel][loadTestData] Error: \(error)")
            }
        }
    }
}
struct CustomerStopDataDetailView: View {
    init(dataService: any ProductionDataServiceProtocol,customerId:String) {
        _VM = StateObject(wrappedValue: CustomerStopDataDetailViewModel(dataService: dataService))
        _customerId = State(wrappedValue: customerId)
    }
    @StateObject var VM : CustomerStopDataDetailViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var customerListVM : CustomerListViewModel
    private var customer: Customer? {
        customerListVM.customers.first { $0.id == customerId }
    }
    @State var customerId:String
    var body: some View {
        ZStack{
            Color.listColor
            VStack{
                Button(action: {
                    VM.loadTestData(companyId: masterDataManager.currentCompany!.id, customerId: customerId)
                }, label: {
                    Text("Load Test Data")
                        .modifier(DeleteButtonModifier())
                })
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
            Button(action: {
                VM.showLocationPicker.toggle()
            }, label: {
                if VM.selectedLocation.id != "" {
                    Text(VM.selectedLocation.address.streetAddress)
                } else {
                    Text("No Location Selected")
                }
            })
            .sheet(isPresented: $VM.showLocationPicker, onDismiss: {
                print("[CustomerStopDataDetailView][showLocationPicker] On dismiss")
            }, content: {
                ServiceLocationPicker(dataService: dataService, customerId: customerId, location: $VM.selectedLocation)
            })
        }
    }
    var BOWForm: some View {
        VStack{
            Button(action: {
                VM.showBOWPicker.toggle()
            }, label: {
                if VM.selectedBodyOfWater.id != "" {
                    Text(VM.selectedBodyOfWater.name)
                } else {
                    Text("No Water Body Selected")
                }
            })
            .sheet(isPresented: $VM.showBOWPicker, onDismiss: {
                print("[CustomerStopDataDetailView][showBOWPicker] On dismiss")
            }, content: {
                BodyOfWaterPicker(dataService: dataService, serviceLocationId: VM.selectedLocation.id, bodyOfWater: $VM.selectedBodyOfWater)
            })
        }
    }
    var table: some View {
        VStack{
            Text("Table")
                .font(.headline)
            if VM.selectedBodyOfWater.id != "" && VM.selectedLocation.id != "" {
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
