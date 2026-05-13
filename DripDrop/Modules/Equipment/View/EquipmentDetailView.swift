    //
    //  EquipmentDetailView.swift
    //  BuisnessSide
    //
    //  Created by Michael Espineli on 12/2/23.
    //


import SwiftUI
import MapKit

@MainActor
final class EquipmentDetailViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published private(set) var bodiesOfWater: [BodyOfWater] = []
    @Published var loadedImages:[DripDropStoredImage] = []
    
    @Published var selectedDripDropPhotos:[DripDropImage] = []
    @Published var selectedBOW:BodyOfWater? = nil
    
    func getAllBodiesOfWaterByServiceLocation(companyId: String,serviceLocation:ServiceLocation) async throws {
        
        self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocation(companyId: companyId, serviceLocation: serviceLocation)
        
    }
    func updatePhotoUrl(companyId:String,equipmentId:String) {
        Task{
            do {
                var uploadedImages : [DripDropStoredImage] = []
                for photo in selectedDripDropPhotos {
                    let (path,name) = try await dataService.uploadEquipmentImage(companyId: companyId, equipmentId: equipmentId, image: photo)
                    let storedImage = DripDropStoredImage(
                        id: UUID().uuidString,
                        description: name,
                        imageURL: path
                    )
                    uploadedImages.append(storedImage)
                    self.loadedImages.append(storedImage)
                    try dataService.updateEquipmentPhotoUrls(companyId: companyId, equipmentId: equipmentId, image: storedImage)
                }
                self.selectedDripDropPhotos = []
            } catch {
                print(error)
            }
        }
    }
}

struct EquipmentDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
        //ViewModels
    @StateObject var equipmentVM : EquipmentViewModel
    @StateObject var VM : EquipmentDetailViewModel

    @State var equipment:Equipment
    
    init(dataService:any ProductionDataServiceProtocol,equipment:Equipment){
        _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
        _VM = StateObject(wrappedValue: EquipmentDetailViewModel(dataService: dataService))

        _equipment = State(wrappedValue: equipment)
    }
        //received Variables
    
    
        //Variables for use
    @State var showEditSheet:Bool = false
    @State var showAddSheet:Bool = false
    @State var showRepairSheet:Bool = false
    @State var showNewPart:Bool = false
    
    @State var isLoading:Bool = false
    let columns = [
        GridItem(.adaptive(minimum: 150)),
        GridItem(.adaptive(minimum: 300))
    ]
    @State var equipmentParts:[EquipmentPart] = [
        
    ]
    @State var selectedDripDropPhotos:[DripDropImage] = []
    @State var photoUrls:[DripDropStoredImage] = []
    
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .scaleEffect(1.1)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if UIDevice.isIPhone {
                            VStack(spacing: 12) {
                                info
                                repairHistory
                            }
                        } else {
                            HStack(alignment: .top, spacing: 12) {
                                info
                                repairHistory
                            }
                        }
                        photos
                    }
                    .padding(12)
                }
            }
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany, let equipment = masterDataManager.selectedEquipment {
                    VM.loadedImages = equipment.photoUrls ?? []
                    try await equipmentVM.getAllPartsByEquipment(companyId: company.id, equipmentId: equipment.id)
                }
            } catch {
                print("Error")
            }
        }
        .onChange(of: masterDataManager.selectedEquipment, perform: { datum in
            Task{
                if let eq = datum {
                    do {
                        if let company = masterDataManager.currentCompany {
                            try await equipmentVM.getAllPartsByEquipment(companyId: company.id, equipmentId: eq.id)
                        }
                    } catch {
                        print("Error")
                    }
                }
            }
        })
        .onChange(of: VM.selectedDripDropPhotos, perform: { photos in
            if let currentCompany = masterDataManager.currentCompany, let equipment = masterDataManager.selectedEquipment {
                VM.updatePhotoUrl(companyId: currentCompany.id, equipmentId: equipment.id)
            }
        })
    }
    func getNextServiceDate(lastServiceDate:Date,every:String,frequency:String) -> Date {
        let calendar = Calendar.current
        
        var date = Date()
        
        
        if let repeatingEvery = Int(every) {
            switch frequency {
            case "Day":
                print("Day")
                date = calendar.date(byAdding: .day, value: repeatingEvery, to: lastServiceDate)!
                
            case "Week":
                print("Week")
                
                let week = repeatingEvery * 7
                date = calendar.date(byAdding: .day, value: week, to: lastServiceDate)!
                
            case "Month":
                print("Month")
                
                date = calendar.date(byAdding: .month, value: repeatingEvery, to: lastServiceDate)!
                
            case "Year":
                print("Year")
                
                date = calendar.date(byAdding: .year, value: repeatingEvery, to: lastServiceDate)!
                
            default:
                print("None")
            }
        } else {
            print("Error Converting Number")
        }
        return date
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
}
extension EquipmentDetailView {
    var photoListView: some View {
        VStack{
            Text("Photos")
                .font(.title)
            VStack{
                ForEach(photoUrls){ photo in
                    VStack{
                        if let url = URL(string: photo.imageURL){
                            AsyncImage(url: url){ image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(Color.gray)
                            } placeholder: {
                                Image(systemName:"photo.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(Color.gray)
                                    .frame(maxWidth:100 ,maxHeight:100)
                                    .cornerRadius(100)
                            }
                        } else {
                            Image(systemName:"photo.circle")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.gray)
                                .frame(maxWidth:100 ,maxHeight:100)
                                .cornerRadius(100)
                        }
                    }
                    .padding(5)
                }
            }
            
        }
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
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
            } else {
                DripDropStoredImageRow(images: VM.loadedImages)
            }
        }
        .ddCard()
    }

 
    var repairHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Repair And Maintenance History").ddSectionTitle()
                Spacer()

                Button(action: {
                    showNewPart.toggle()
                }, label: {
                    Text("Add Part")
                        .modifier(EditButtonModifier())
                })
                .sheet(isPresented: $showNewPart, content: {
                    Text("Add New Part View")
                })
            }

            if equipmentVM.partList.isEmpty {
                Text("No parts added yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(equipmentVM.partList) { part in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(part.name)")
                                    .font(.subheadline.weight(.semibold))
                                Text("Install Date: \(fullDate(date: part.date))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                showRepairSheet.toggle()
                            }, label: {
                                Image(systemName: "chevron.right")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                                    .background(Circle().fill(Color.primary.opacity(0.06)))
                            })
                            .sheet(isPresented: $showRepairSheet, content: {
                                EquipmentPartDetailView(equipmentPart: part)
                            })
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.primary.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .ddCard()
    }

    var info: some View {
        HStack(alignment: .top, spacing: 12) {

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Equipment").ddSectionTitle()
                    Spacer()
                        // Right-side edit column (same permission logic)
                        if let role = masterDataManager.role {
                            if role.permissionIdList.contains("64") {
                            Button(action: {
                                showEditSheet = true
                            }, label: {
                                Text("Edit")
                                    .modifier(AddButtonModifier())
                                
                            })
                            .sheet(isPresented: $showEditSheet, content: {
                                if let EQ = masterDataManager.selectedEquipment {
                                    EditEquipmentView(dataService: dataService, equipment: EQ)
                                } else {
                                    EditEquipmentView(dataService: dataService, equipment: equipment)
                                }
                            })
                        }
                    }
                }
                if let selectedEquipment = masterDataManager.selectedEquipment {
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(title: "Category", value: "\(selectedEquipment.type.rawValue)")
                        InfoRow(title: "Make", value: "\(selectedEquipment.make)")
                        InfoRow(title: "Model", value: "\(selectedEquipment.model)")
                    }
                    Divider().opacity(0.18)
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(title: "Date Installed", value: "\(fullDate(date: selectedEquipment.dateInstalled))")

                        HStack {
                            Text("Status")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            Spacer()
                            switch equipment.status {
                            case .operational:
                                Text(equipment.status.rawValue).modifier(BlueButtonModifier())
                            case .nonoperational:
                                Text(equipment.status.rawValue).modifier(DismissButtonModifier())
                            case .needsRepair:
                                Text(equipment.status.rawValue).modifier(OrangeButtonModifier())
                            case .needsMaintenance:
                                Text(equipment.status.rawValue).modifier(YellowButtonModifier())
                            }
                        }

                        if selectedEquipment.needsService {
                            if let serviceDate = selectedEquipment.lastServiceDate,
                               let every = selectedEquipment.serviceFrequencyEvery,
                               let frequency = selectedEquipment.serviceFrequency,
                               let nextServiceDate = selectedEquipment.nextServiceDate {

                                Divider().opacity(0.18)

                                InfoRow(title: "Last Service Date", value: "\(fullDate(date: serviceDate))")
                                InfoRow(title: "Service Frequency", value: "\(every) \(frequency)")

                                HStack {
                                    Text("Next Service Date")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(fullDate(date: nextServiceDate))")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(nextServiceDate > Date() ? Color.poolGreen : Color.poolRed)
                                        .cornerRadius(10)
                                        .foregroundColor(Color.poolWhite)
                                }

                                if equipment.type == .filter {
                                    Divider().opacity(0.18)

                                    if let cleanPressure = equipment.cleanFilterPressure {
                                        HStack {
                                            Text("Clean Pressures").font(.subheadline.weight(.semibold))
                                            Spacer()
                                            Text("\(String(format: "%.0f", Double(cleanPressure))) PSI")
                                                .font(.subheadline.monospacedDigit())
                                        }

                                        if let currentPressure = equipment.currentPressure {
                                            let difference = Double(Int(currentPressure) - cleanPressure)
                                            HStack {
                                                Text("Dirty").font(.subheadline.weight(.semibold))
                                                Spacer()
                                                Text("\(String(format: "%.0f", (difference/15)*100)) %")
                                                    .font(.subheadline.monospacedDigit())
                                            }
                                        }
                                    }

                                    Divider().opacity(0.18)

                                    HStack {
                                        Text("Last Cleaned").font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text(shortDate(date: equipment.lastServiceDate))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    HStack {
                                        Text("Installed").font(.subheadline.weight(.semibold))
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(shortDate(date: equipment.dateInstalled))
                                                .font(.subheadline)
                                            Text("(\(String(format: "%.1f", numberOfYearsBetween(equipment.dateInstalled, Date()))) years)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }

                        Divider().opacity(0.18)

                        InfoRow(title: "Notes", value: "\(selectedEquipment.notes)")
                    }

                } else {
                    // fallback equipment (same logic)
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(title: "Category", value: "\(equipment.type.rawValue)")
                        InfoRow(title: "Make", value: "\(equipment.make)")
                        InfoRow(title: "Model", value: "\(equipment.model)")
                    }

                    Divider().opacity(0.18)

                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(title: "Date Installed", value: "\(fullDate(date: equipment.dateInstalled))")
                        InfoRow(title: "Status", value: "\(equipment.status)")

                        if equipment.needsService {
                            if let serviceDate = equipment.lastServiceDate,
                               let every = equipment.serviceFrequencyEvery,
                               let frequency = equipment.serviceFrequency,
                               let nextServiceDate = equipment.nextServiceDate {

                                Divider().opacity(0.18)
                                InfoRow(title: "Last Service Date", value: "\(fullDate(date: serviceDate))")
                                InfoRow(title: "Service Frequency", value: "\(every) \(frequency)")

                                HStack {
                                    Text("Next Service Date")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(fullDate(date: nextServiceDate))")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(nextServiceDate > Date() ? Color.poolGreen : Color.poolRed)
                                        .cornerRadius(10)
                                        .foregroundColor(Color.basicFontText)
                                }
                            }
                        }

                        Divider().opacity(0.18)

                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("\(equipment.notes)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .modifier(PlainTextFieldModifier())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .ddCard()


        }
    }

}
private extension View {
    func ddCard() -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)
                    .shadow(color: Color.darkGray.opacity(0.06), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
    }

    func ddSectionTitle() -> some View {
        self
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }
}
