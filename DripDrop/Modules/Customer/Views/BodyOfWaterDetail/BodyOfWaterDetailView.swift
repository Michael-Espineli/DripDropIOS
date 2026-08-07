    //
    //  BodyOfWaterDetailView.swift
    //  BuisnessSide
    //
    //  Created by Michael Espineli on 12/2/23.
    //


import SwiftUI
import MapKit

@MainActor
final class BodyOfWaterDetailViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published private(set) var equipmentList: [Equipment] = []
    @Published private(set) var waterHistory: [BodyOfWaterHistory] = []
    @Published var loadedImages:[DripDropStoredImage] = []
    
    @Published var selectedDripDropPhotos:[DripDropImage] = []
    @Published var selectedEquipment:Equipment? = nil
    func onLoad(companyId:String,bodyOfWater:BodyOfWater) async throws {

                self.equipmentList = try await dataService.getEquipmentByBodyOfWater(companyId: companyId, bodyOfWater: bodyOfWater)
                self.waterHistory = try await dataService.getBodyOfWaterHistory(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
         
    }
    func getAllBodiesOfWaterByServiceLocation(companyId: String,bodyOfWater:BodyOfWater) async throws {
        
        self.equipmentList = try await dataService.getEquipmentByBodyOfWater(companyId: companyId, bodyOfWater: bodyOfWater)
        
    }
    func updatePhotoUrl(companyId:String,bodyOfWaterId:String) {
        Task{
            do {
                var uploadedImages : [DripDropStoredImage] = []
                for photo in selectedDripDropPhotos {
                    let (path,name) = try await dataService.uploadBodyOfWaterImage(companyId: companyId, bodyOfWaterId: bodyOfWaterId, image: photo)
                    let storedImage = DripDropStoredImage(
                        id: UUID().uuidString,
                        description: name,
                        imageURL: path
                    )
                    uploadedImages.append(storedImage)
                    self.loadedImages.append(storedImage)
                    
                }
                try await dataService.updateBodyOfWaterPhotoURLs(companyId: companyId, bodyOfWaterId: bodyOfWaterId, photoUrls: uploadedImages)
                self.selectedDripDropPhotos = []
            } catch {
                print(error)
            }
        }
    }
}
struct BodyOfWaterDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    
        //ViewModels
        //received Variables
    
    init(dataService:any ProductionDataServiceProtocol,bodyOfWater:BodyOfWater){
        _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
        _VM = StateObject(wrappedValue: BodyOfWaterDetailViewModel(dataService: dataService))
        
        _bodyOfWater = State(wrappedValue: bodyOfWater)
    }
    @StateObject var equipmentVM : EquipmentViewModel
    @StateObject var VM : BodyOfWaterDetailViewModel
    
    @State var bodyOfWater:BodyOfWater
    
        //Variables for use
    @State var showEditSheet:Bool = false
    @State var showAddSheet:Bool = false
    @State var isLoading:Bool = false
    
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            if isLoading {
                VStack {
                    Spacer()
                    ProgressView().scaleEffect(1.1)
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                            info
                                .padding(12)
                            photos
                                .padding(12)
                            recentReadings
                                .padding(12)
                            waterHistory
                                .padding(12)
                        Divider()
                            .opacity(0.15)
                            .padding(.vertical, 2)

                        equipment
                    }
                }
            }
        }
        .task{
            isLoading = true
            do {
                if let bodyOfWater = masterDataManager.selectedBodyOfWater, let currentCompany = masterDataManager.currentCompany {
                    VM.loadedImages = bodyOfWater.photoUrls ?? []
                    try await VM.onLoad(companyId: currentCompany.id, bodyOfWater: bodyOfWater)
                    
                    if VM.equipmentList.count != 0 {
                        VM.selectedEquipment = VM.equipmentList.first!
                        masterDataManager.selectedEquipment = VM.equipmentList.first!
                    } else {
                        print("equipment set to nil")
                        VM.selectedEquipment = nil
                        masterDataManager.selectedEquipment = nil
                    }
                }
            } catch{
                print("Error")
            }
            isLoading = false
        }
        .onChange(of: masterDataManager.selectedBodyOfWater, perform: { BOW in
            Task{
                isLoading = true
                do {
                    if let bodyOfWater = BOW, let currentCompany = masterDataManager.currentCompany {
                        VM.loadedImages = bodyOfWater.photoUrls ?? []
                        try await VM.onLoad(companyId: currentCompany.id, bodyOfWater: bodyOfWater)
                        
                        if VM.equipmentList.count != 0 {
                            VM.selectedEquipment = VM.equipmentList.first!
                            masterDataManager.selectedEquipment = VM.equipmentList.first!
                        } else {
                            print("equipment set to nil")
                            VM.selectedEquipment = nil
                            masterDataManager.selectedEquipment = nil
                        }
                    }
                } catch{
                    print("Error")
                }
                isLoading = false
            }
        })
        .onChange(of: VM.selectedEquipment, perform: { datum in
            Task{
                if let datum {
                    isLoading = true
                    
                    sleep(1)
                    isLoading = false
                }
            }
        })
        .onChange(of: VM.selectedDripDropPhotos, perform: { photo in
            if let currentCompany = masterDataManager.currentCompany {
                VM.updatePhotoUrl(companyId: currentCompany.id, bodyOfWaterId: bodyOfWater.id)
            }
        })
    }
}
extension BodyOfWaterDetailView {
    var edit: some View {
        HStack{
            Spacer()
            Button(action: {
                showEditSheet = true
            }, label: {
                Label("Edit", systemImage: "pencil")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(Color.poolBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            })
            .buttonStyle(.plain)
            .sheet(isPresented: $showEditSheet,onDismiss: {
                
            }, content: {
                if let BOW = masterDataManager.selectedBodyOfWater {
                    EditBodyOfWaterView(dataService:dataService, bodyOfWater: BOW)
                }
            })
        }
    }
    
    var info: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let bodyOfWater = masterDataManager.selectedBodyOfWater {

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bodyOfWater.name)
                            .font(.title3.weight(.semibold))
                            .lineLimit(1)

                        Text("Body of Water")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                    edit
                }

                Divider().opacity(0.15)

                InfoRow(title: "Gallons", value: "\(bodyOfWater.gallons)")
                InfoRow(title: "Material", value: "\(bodyOfWater.material)")
                InfoRow(title: "Shape", value: "\(bodyOfWater.shape ?? "-")")
                InfoRow(title: "Dimensions", value: "\(bodyOfWater.material)")

                Divider().opacity(0.15)

                Text("Notes").ddSectionTitle()

                if let notes = bodyOfWater.notes {
                    Text("\(notes)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .modifier(PlainTextFieldModifier())
                } else {
                    Text("No notes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .ddCard()
    }

    var photos: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos").ddSectionTitle()
                Spacer()
            }

            PhotoContentView(selectedImages: $VM.selectedDripDropPhotos)

            if !VM.selectedDripDropPhotos.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading Images...")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Capsule().fill(Color.primary.opacity(0.06)))
            }

            if VM.loadedImages.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundStyle(.secondary)
                    Text("No Images")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            } else {
                DripDropStoredImageRow(images: VM.loadedImages)
            }
        }
        .ddCard()
    }

    
    var recentReadings: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Readings").ddSectionTitle()
                Spacer()
                Button(action: {

                }, label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.poolBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.poolBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                })
                .buttonStyle(.plain)
            }
        }
        .ddCard()
    }

    var waterHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Water History").ddSectionTitle()
                Spacer()
            }

            if VM.waterHistory.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "drop")
                        .foregroundStyle(.secondary)
                    Text("No fill or empty history yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            } else {
                ForEach(VM.waterHistory.prefix(5)) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: item.type == .fill ? "drop.fill" : "drop")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(item.type == .fill ? Color.blue : Color.orange)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.primary.opacity(0.06)))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.type.rawValue)
                                .font(.subheadline.weight(.semibold))

                            Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if !item.description.isEmpty {
                                Text(item.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        if !item.techName.isEmpty {
                            Text(item.techName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)

                    if item.id != VM.waterHistory.prefix(5).last?.id {
                        Divider().opacity(0.12)
                    }
                }
            }
        }
        .ddCard()
    }

    
    var equipment: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Equipment").ddSectionTitle()
                Spacer()
            }

            if let role = masterDataManager.role {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {

                        if role.permissionIdList.contains("62") {
                            Button(action: {
                                showAddSheet = true
                            }, label: {
                                Image(systemName: "plus")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.primary)
                                    .padding(10)
                                    .background(Circle().fill(Color.primary.opacity(0.08)))
                            })
                            .sheet(isPresented: $showAddSheet, onDismiss: {
                                Task {
                                    do {
                                        if let currentCompany = masterDataManager.currentCompany,
                                           let bodyOfWater = masterDataManager.selectedBodyOfWater {
                                            try await VM.onLoad(companyId: currentCompany.id, bodyOfWater: bodyOfWater)
                                        }
                                    } catch {
                                        print("Error")
                                    }
                                }
                            }, content: {
                                AddEquipmentView(dataService: dataService, bodyOfWater: bodyOfWater)
                            })
                        }

                        if VM.equipmentList.count == 0 {
                            if role.permissionIdList.contains("62") {
                                Button(action: {
                                    showAddSheet = true
                                }, label: {
                                    Text("Add First Equipment")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                                })
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("No Equipment")
                                        .font(.subheadline.weight(.semibold))
                                    Text("You do not have permission to add equipment")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                        } else {
                            ForEach(VM.equipmentList) { equipment in
                                Button(action: {
                                    Task {
                                        VM.selectedEquipment = nil
                                        VM.selectedEquipment = equipment
                                        masterDataManager.selectedEquipment = equipment
                                    }
                                }, label: {
                                    HStack(spacing: 8) {
                                        if equipment.status != .operational {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(Color.poolRed)
                                        }

                                        Text(equipment.type.rawValue)
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule().fill(
                                            VM.selectedEquipment == equipment
                                            ? Color.primary.opacity(0.14)
                                            : Color.primary.opacity(0.06)
                                        )
                                    )
                                    .overlay(
                                        Capsule().stroke(
                                            VM.selectedEquipment == equipment
                                            ? Color.primary.opacity(0.22)
                                            : Color.primary.opacity(0.10),
                                            lineWidth: 1
                                        )
                                    )
                                })
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }

            Divider().opacity(0.15)

            if VM.selectedEquipment == nil {
                Group {
                    if VM.equipmentList.count == 0 {
                        Text("No Equipment")
                        Text("Please Set Up")
                    } else {
                        Text("Please select an Equipment")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
            } else {
                if let equipment = VM.selectedEquipment {
                    EquipmentDetailView(dataService: dataService, equipment: equipment)
//                        .ddCard()
                } else {
                    Text("Please select an Equipment")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
//        .ddCard()
    }

}
struct BodyOfWaterDetailView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        BodyOfWaterDetailView(
            dataService: dataService,
            bodyOfWater: BodyOfWater(
                id: UUID().uuidString,
                name: "",
                gallons: "",
                material: "",
                customerId: "",
                serviceLocationId: "",
                lastFilled: Date(),
                isActive: true
            )
        )
    }
}


private extension View {
    func ddCard() -> some View {
        self
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
    }

    func ddSectionTitle() -> some View {
        self
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
