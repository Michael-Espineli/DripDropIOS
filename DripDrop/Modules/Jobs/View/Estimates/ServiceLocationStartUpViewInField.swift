//
//  ServiceLocationStartUpViewInField.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/14/24.
//

import SwiftUI

struct ServiceLocationStartUpViewInField: View {
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var vm : JobTemplateViewModel
    @StateObject var VM : ServiceLocationStartUpViewModel

    init(
        dataService: any ProductionDataServiceProtocol,
        customerId: String,
        serviceLocationId: String,
        serviceStop: ServiceStop,
        serviceLocation: ServiceLocation? = nil
    ) {
        _vm = StateObject(wrappedValue: JobTemplateViewModel(dataService: dataService))
        _VM = StateObject(wrappedValue: ServiceLocationStartUpViewModel(dataService: dataService))
        _customerId = State(wrappedValue: customerId)
        _serviceLocationId = State(wrappedValue: serviceLocationId)
        _serviceStop = State(wrappedValue: serviceStop)
        self.serviceLocation = serviceLocation

    }
    @State var customerId: String
    @State var serviceLocationId: String
    @State var serviceStop: ServiceStop
    let serviceLocation: ServiceLocation?
    
    @State var selectedBOW:BodyOfWater = BodyOfWater(
        id: UUID().uuidString,
        name: "Main Pool",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        notes: "",
        shape: "",
        length: [],
        depth: [],
        width: [],
        lastFilled: Date(),
        isActive: true
    )
    @State var bodyOfWaterList:[BodyOfWater] = []
    
    //Equipment
    @State var equipmentList:[Equipment] = []
    @State var selectedEquipmentId:String = ""
    @State var selectedEquipmentCategory:EquipmentCategory? = nil
    
    //Images
    @State var bodyOfWaterImages:[String:[DripDropImage]] = [:]
    @State var equipmentImages:[String:[DripDropImage]] = [:]
    @State private var serviceLocationPhotos: [DripDropImage] = []

    @State private var locationNickName: String = ""
    @State private var gateCode: String = ""
    @State private var locationNotes: String = ""
    @State private var saveMessage: String? = nil
    @State private var didSeedSurveyDraft: Bool = false
    @State private var didHydrateLocationFields: Bool = false
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        VStack{
                            locationSurveyCard
                            bodyOfWaterStartUp
                            equipmentStartUp
                        }
                        .padding(.horizontal,16)
                        
                    }, header: {
                        HStack{
                            bodyOfWaterPicker
                            
                            button
                        }
                        .padding(.vertical,5)
                        .padding(.horizontal,8)
                        .padding(.top,24)
                        .background(Color.listColor)
                        
                    })
                })
                .clipped()
            }
            .ignoresSafeArea()
            if VM.isLoading {
                ProgressView()
                    .padding(8)
                    .background(Color.darkGray)
                    .cornerRadius(8)
            }
            
        }
        .onAppear {
            seedSurveyDraftIfNeeded()
            hydrateLocationFieldsIfPossible()
        }
        .onChange(of: serviceLocation) { _ in
            hydrateLocationFieldsIfPossible()
        }
    }
}

//#Preview {
//    ServiceLocationStartUpView(dataService: MockDataService(), serviceLocation: MockDataService.mockServiceLocation)
//}
extension ServiceLocationStartUpViewInField {
    private func saveSurvey(companyId: String) async throws {
        try await VM.createLocation(
            companyId: companyId,
            customerId: customerId,
            serviceLocationId: serviceLocationId,
            bodyOfWaterList: bodyOfWaterList,
            equipmentList: equipmentList,
            bodyOfWaterImages: bodyOfWaterImages,
            equipmentImages: equipmentImages,
            locationNickName: locationNickName,
            gateCode: gateCode,
            locationNotes: locationNotes,
            serviceLocationPhotos: serviceLocationPhotos
        )
    }

    private func seedSurveyDraftIfNeeded() {
        guard !didSeedSurveyDraft else { return }

        didSeedSurveyDraft = true
        selectedBOW.customerId = customerId
        selectedBOW.serviceLocationId = serviceLocationId

        if bodyOfWaterList.isEmpty {
            bodyOfWaterList = [selectedBOW]
        }

        if equipmentList.isEmpty {
            equipmentList = [
                defaultEquipment(name: "Main Pump", type: .pump, bodyOfWaterId: selectedBOW.id),
                defaultEquipment(name: "Main Filter", type: .filter, bodyOfWaterId: selectedBOW.id)
            ]
        }
    }

    private func hydrateLocationFieldsIfPossible() {
        guard !didHydrateLocationFields else { return }

        if let serviceLocation {
            locationNickName = serviceLocation.nickName
            gateCode = serviceLocation.gateCode
            locationNotes = serviceLocation.notes ?? ""
            didHydrateLocationFields = true
        } else if locationNickName.isEmpty {
            locationNickName = "\(serviceStop.customerName) Service Location"
        }
    }

    private func defaultEquipment(
        name: String,
        type: EquipmentCategory,
        bodyOfWaterId: String
    ) -> Equipment {
        Equipment(
            id: UUID().uuidString,
            name: name,
            type: type,
            typeId: "",
            make: "",
            makeId: "",
            model: "",
            modelId: "",
            dateInstalled: Date(),
            status: .operational,
            needsService: false,
            cleanFilterPressure: type == .filter ? 15 : nil,
            currentPressure: type == .filter ? 20 : nil,
            lastServiceDate: Date(),
            serviceFrequency: type == .filter ? 6 : nil,
            serviceFrequencyEvery: type == .filter ? .monthly : nil,
            nextServiceDate: Date(),
            notes: "",
            customerName: serviceStop.customerName,
            customerId: customerId,
            serviceLocationId: serviceLocationId,
            bodyOfWaterId: bodyOfWaterId,
            isActive: true
        )
    }

    private var locationSurveyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title3)
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Location Survey")
                        .font(.headline.weight(.semibold))

                    Text(fullAddress)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            VStack(spacing: 10) {
                surveyTextField(title: "Location Name", text: $locationNickName)
                surveyTextField(title: "Gate Code", text: $gateCode)
                surveyTextField(title: "Location Notes", text: $locationNotes, lineLimit: 3...6)
            }

            if let storedImages = serviceLocation?.photoUrls, !storedImages.isEmpty {
                DripDropStoredImageRow(images: storedImages)
            }

            PhotoContentView(selectedImages: $serviceLocationPhotos)

            if let saveMessage {
                Text(saveMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(saveMessage == "Survey saved" ? Color.poolGreen : Color.poolRed)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var fullAddress: String {
        [
            serviceStop.address.streetAddress,
            serviceStop.address.city,
            serviceStop.address.state,
            serviceStop.address.zip
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }

    private func surveyTextField(
        title: String,
        text: Binding<String>,
        lineLimit: ClosedRange<Int>? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let lineLimit {
                TextField(title, text: text, axis: .vertical)
                    .lineLimit(lineLimit)
                    .padding(10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .foregroundColor(Color.basicFontText)
            } else {
                TextField(title, text: text)
                    .padding(10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .foregroundColor(Color.basicFontText)
            }
        }
    }

    var button: some View {
        HStack{
            Button(action: {
                Task{
                    if VM.isLoading {
                    } else {
                        do {
                            if let company = masterDataManager.currentCompany {
                                if serviceStop.otherCompany && serviceStop.contractedCompanyId != "" {
                                    try await saveSurvey(companyId: serviceStop.contractedCompanyId)
                                }

                                try await saveSurvey(companyId: company.id)
                            } else {
                                print("no Company")
                            }
                            print("Successful")
                            saveMessage = "Survey saved"
                        } catch {
                            print("error")
                            print(error)
                            saveMessage = "Could not save survey"
                        }
                    }
                }
            },
                   label: {
                Label(VM.isLoading ? "Saving" : "Save", systemImage: "tray.and.arrow.down.fill")
                    .modifier(SubmitButtonModifier())
            })
            .disabled(VM.isLoading)
        }
    }
    var bodyOfWaterPicker: some View {
        VStack{
            HStack{
                Text("Bodies Of Water")
                Spacer()
            }
            HStack{
                Rectangle()
                    .frame(width: 150, height: 3)
                Spacer()
            }
            
            ScrollView(.horizontal){
                HStack(spacing:16){
                    Button(action: {
                        let name = "Pool" + " " + String(bodyOfWaterList.count + 1)
                        let id = UUID().uuidString
                        bodyOfWaterList.append(
                            BodyOfWater(
                                id: id,
                                name: name,
                                gallons: "",
                                material: "",
                                customerId: customerId,
                                serviceLocationId: serviceLocationId,
                                notes: "",
                                shape: "",
                                length: [],
                                depth: [],
                                width: [],
                                lastFilled: Date(),
                                isActive: true
                            ))
                        selectedBOW = bodyOfWaterList.first(where: {$0.id == id})! //DEVELOPER, I know i explicitly unwrapped but it should never fail.
                        equipmentList.append(
                            contentsOf: [
                                defaultEquipment(name: "Main Pump", type: .pump, bodyOfWaterId: selectedBOW.id),
                                defaultEquipment(name: "Main Filter", type: .filter, bodyOfWaterId: selectedBOW.id)
                            ]
                        )
                    }, label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(Color.poolBlue)
                            .cornerRadius(8)
                    })
                    ForEach(bodyOfWaterList){ BOW in
                        Button(action: {
                            selectedBOW = BOW
                            
                            if let selectedEquipmentCategory,
                               let first = equipmentList
                                .filter({ $0.bodyOfWaterId == BOW.id })
                                .first(where: { $0.type == selectedEquipmentCategory }) {
                                selectedEquipmentId = first.id
                                print("Selected Equipment Id true")
                            } else {
                                print("Selected Equipment Id is nil")
                                selectedEquipmentId = ""
                            }
                            
                        }, label: {
                            Text("\(BOW.name)")
                                .padding(8)
                                .background(selectedBOW.id == BOW.id ? Color.poolBlue : Color.darkGray)
                                .foregroundColor(Color.white)
                                .cornerRadius(8)
                        })
                        
                    }
                }
            }
        }
    }
    var bodyOfWaterStartUp: some View {
        VStack{
            BodyOfWaterDetailStartUpView(bodiesOfWater: $bodyOfWaterList, selectedBodyOfWater: $selectedBOW, equipmentList: $equipmentList, photos: $bodyOfWaterImages)
        }
    }
    var equipmentStartUp: some View {
        VStack{
            Text("Equipment Start Up")
                .font(.headline)
            Rectangle()
                .frame(height: 4)
            ForEach(EquipmentCategory.allCases,id:\.self){ category in
                Section(content: {
                    if selectedEquipmentId != "" {
                        if let selectedEquipmentCategory {
                            if selectedEquipmentCategory == category {
                                EquipmentDetailStartUpView(
                                    dataService: VM.dataService,
                                    equipmentList: $equipmentList,
                                    selectedEquipmentId: $selectedEquipmentId,
                                    photos:$equipmentImages
                                )
                            }
                        }
                    }
                },
                        header: {
                    VStack{
                        HStack{
                            Text(category.rawValue)
                            Spacer()
                        }
                        HStack{
                            Rectangle()
                                .frame(width:50,height: 1)
                            Spacer()
                        }
                        ScrollView(.horizontal){
                            HStack{
                                Button(action: {
                                    selectedEquipmentId = ""
                                    let newId = UUID().uuidString
                                    let name = category.rawValue + " " + String(equipmentList.filter({$0.bodyOfWaterId == selectedBOW.id}).filter({$0.type == category}).count + 1)
                                    equipmentList.append(
                                        Equipment(
                                            id: newId,
                                            name: name,
                                            type: category,
                                            typeId: "",
                                            make: "",
                                            makeId: "",
                                            model: "",
                                            modelId: "",
                                            dateInstalled: Date(),
                                            status: .operational,
                                            needsService: false,
                                            notes: "",
                                            customerName: serviceStop.customerName,
                                            customerId: customerId,
                                            serviceLocationId: serviceLocationId,
                                            bodyOfWaterId: selectedBOW.id,
                                            isActive: true
                                        )
                                    )
                                    selectedEquipmentId = newId
                                    selectedEquipmentCategory = category
                                },label: {
                                    Image(systemName: "plus")
                                        .foregroundColor(Color.white)
                                        .padding(8)
                                        .background(Color.poolBlue)
                                        .cornerRadius(8)
                                })
                                ForEach(equipmentList.filter({$0.bodyOfWaterId == selectedBOW.id}).filter({$0.type == category})) { equipment in
                                    Button(action: {
                                        if selectedEquipmentId == equipment.id {
                                            selectedEquipmentId = ""
                                            selectedEquipmentCategory = nil
                                        } else {
                                            selectedEquipmentId = equipment.id
                                            selectedEquipmentCategory = category
                                        }
                                    }, label: {
                                        Text("\(equipment.name)")
                                            .padding(8)
                                            .background(selectedEquipmentId == equipment.id ? Color.poolBlue : Color.darkGray)
                                            .foregroundColor(Color.white)
                                            .cornerRadius(8)
                                    })
                                }
                            }
                        }
                    }
                })
                Rectangle()
                    .frame(height: 2)
            }
        }
    }
}
