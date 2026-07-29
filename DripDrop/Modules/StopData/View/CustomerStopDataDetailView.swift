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
                    await loadBodiesOfWater(companyId: companyId, customerId: customerId)
                }
            } catch {
                print(error)
            }
        }
    }
    func onChangeOfServiceLocation(companyId:String,customerId:String){
        Task{
            print("[CustomerStopDataDetailViewModel][onChangeOfServiceLocation] selectedLocation \(selectedLocation.id)")
            await loadBodiesOfWater(companyId: companyId, customerId: customerId)
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

    private func loadBodiesOfWater(companyId: String, customerId: String) async {
        guard !selectedLocation.id.isEmpty else {
            bodiesOfWater = []
            selectedBodyOfWater = emptyBodyOfWater()
            currentHistory = []
            return
        }

        do {
            bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocation(
                companyId: companyId,
                serviceLocation: selectedLocation
            )

            if let firstBodyOfWater = bodiesOfWater.first {
                if selectedBodyOfWater.id.isEmpty ||
                    !bodiesOfWater.contains(where: { $0.id == selectedBodyOfWater.id }) {
                    selectedBodyOfWater = firstBodyOfWater
                }

                currentHistory = try await dataService.getRecentServiceStopsByBodyOfWater(
                    companyId: companyId,
                    bodyOfWaterId: selectedBodyOfWater.id,
                    amount: 20
                )
            } else {
                selectedBodyOfWater = emptyBodyOfWater()
                currentHistory = []
            }
        } catch {
            bodiesOfWater = []
            currentHistory = []
            print("[CustomerStopDataDetailViewModel][loadBodiesOfWater] Error: \(error)")
        }
    }

    private func emptyBodyOfWater() -> BodyOfWater {
        BodyOfWater(
            id: "",
            name: "",
            gallons: "",
            material: "",
            customerId: "",
            serviceLocationId: "",
            lastFilled: Date(),
            isActive: true
        )
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
                
                    #if DEBUG
                if AppEnvironment.current == .dev {
                    Button(action: {
                        VM.loadTestData(companyId: masterDataManager.currentCompany!.id, customerId: customerId)
                    }, label: {
                        Text("Load Test Data")
                            .modifier(DeleteButtonModifier())
                    })
                }
#endif
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                locationForm
                BOWForm
                table
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    var locationForm: some View {
        selectorCard(
            title: "Service Location",
            value: selectedLocationTitle,
            detail: selectedLocationDetail,
            systemImage: "mappin.and.ellipse",
            accentColor: Color.poolBlue
        ) {
            VM.showLocationPicker.toggle()
        }
        .sheet(isPresented: $VM.showLocationPicker, onDismiss: {
            print("[CustomerStopDataDetailView][showLocationPicker] On dismiss")
        }, content: {
            ServiceLocationPicker(dataService: dataService, customerId: customerId, location: $VM.selectedLocation)
        })
    }

    var BOWForm: some View {
        selectorCard(
            title: "Body of Water",
            value: selectedBodyOfWaterTitle,
            detail: bodyOfWaterMetaText(VM.selectedBodyOfWater),
            systemImage: "drop.fill",
            accentColor: Color.poolGreen
        ) {
            VM.showBOWPicker.toggle()
        }
        .disabled(VM.selectedLocation.id.isEmpty)
        .opacity(VM.selectedLocation.id.isEmpty ? 0.55 : 1)
        .sheet(isPresented: $VM.showBOWPicker, onDismiss: {
            print("[CustomerStopDataDetailView][showBOWPicker] On dismiss")
        }, content: {
            BodyOfWaterPicker(dataService: dataService, serviceLocationId: VM.selectedLocation.id, bodyOfWater: $VM.selectedBodyOfWater)
        })
    }

    var table: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Water History")
                        .font(.headline.weight(.semibold))

                    Text(selectedBodyOfWaterTitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(VM.currentHistory.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.poolBlue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.poolBlue.opacity(0.1), in: Capsule())
            }

            if VM.selectedBodyOfWater.id != "" && VM.selectedLocation.id != "" {
                if VM.currentHistory.count != 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        StopDataTableView(
                            stopData: VM.currentHistory,
                            readingTemplates: VM.readingTemplates,
                            dosageTemplates: VM.dosageTemplates,
                            bodyOfWaterId: VM.selectedBodyOfWater.id
                        )
                    }
                } else {
                    ContentUnavailableView(
                        "No Water History",
                        systemImage: "tablecells",
                        description: Text("No readings or dosages have been saved for this body of water yet.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
            } else {
                ContentUnavailableView(
                    "Select Water",
                    systemImage: "drop.triangle",
                    description: Text("Choose a service location and body of water to view history.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.separator).opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var selectedLocationTitle: String {
        if !VM.selectedLocation.nickName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return VM.selectedLocation.nickName
        }

        let street = VM.selectedLocation.address.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        return street.isEmpty ? "No Location Selected" : street
    }

    private var selectedLocationDetail: String {
        let address = VM.selectedLocation.address
        let detail = [
            address.city,
            address.state,
            address.zip,
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")

        return detail.isEmpty ? "Tap to choose a location" : detail
    }

    private var selectedBodyOfWaterTitle: String {
        let name = VM.selectedBodyOfWater.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "No Water Body Selected" : name
    }

    private func bodyOfWaterMetaText(_ bodyOfWater: BodyOfWater) -> String {
        let gallons = bodyOfWater.gallons.trimmingCharacters(in: .whitespacesAndNewlines)
        let material = bodyOfWater.material.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = [
            gallons.isEmpty ? "" : "\(gallons) gal",
            material,
        ].filter { !$0.isEmpty }

        return parts.isEmpty ? "Tap to choose water" : parts.joined(separator: " · ")
    }

    private func selectorCard(
        title: String,
        value: String,
        detail: String,
        systemImage: String,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: systemImage)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(value)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(detail)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.separator).opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
