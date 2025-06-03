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
        ZStack{
            Color.listColor.ignoresSafeArea()
            if isLoading {
                ProgressView()
            } else {
                VStack{
                    Divider()
                    
                    if UIDevice.isIPhone{
                        VStack {
                            info
                            repairHistory
                        }
                    } else {
                        HStack {
                            info
                            Divider()
                            repairHistory
                        }
                    }
                    photos
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
            VStack{
                PhotoContentView(selectedImages: $VM.selectedDripDropPhotos)
                if !VM.selectedDripDropPhotos.isEmpty {
                    HStack{
                        Text("Loading Images...")
                        ProgressView()
                    }
                }
                if VM.loadedImages.isEmpty {
                    Text("No Images")
                } else {
                    DripDropStoredImageRow(images: VM.loadedImages)
                }
            }
        
    }
    var edit: some View {
        HStack{
            
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
    var repairHistory: some View {
        VStack{
            ZStack{
                
                HStack{
                    Text("Part List")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        showNewPart.toggle()
                    }, label: {
                        Text("Add Part")
                    })
                    .modifier(EditButtonModifier())
                    .sheet(isPresented: $showNewPart, content: {
                        Text("Add New Part View")
                    })
                }
            }
            ForEach(equipmentVM.partList) { part in
                HStack{
                    Text("Part: \(part.name)")
                    Text("Date Replaced: \(fullDate(date:part.date))")
                    Button(action: {
                        showRepairSheet.toggle()
                    }, label: {
                        Text("Detail")
                    })
                    .sheet(isPresented: $showRepairSheet, content: {
                        EquipmentPartDetailView(equipmentPart: part)
                    })
                }
            }
            Spacer()
        }
        .padding(8)
        .background(Color.gray.opacity(0.5))
        .cornerRadius(8)
    }
    var info: some View {
        HStack{
            VStack{
                if let selectedEquipment = masterDataManager.selectedEquipment {
                    VStack{
                        HStack{
                            Text("Category: ")
                            
                            
                            Text("\(selectedEquipment.category)")
                            Spacer()
                        }
                        HStack{
                            Text("Make: ")
                            
                            
                            Text("\(selectedEquipment.make)")
                            Spacer()
                        }
                        HStack{
                            Text("Model: ")
                            
                            Text("\(selectedEquipment.model)")
                            Spacer()
                        }
                    }
                    VStack{
                        HStack{
                            Text("Date Installed: ")
                            
                            Text("\(fullDate(date: selectedEquipment.dateInstalled))")
                            
                            Spacer()
                        }
                        HStack{
                            Text("Status: ")
                            
                            Text("\(selectedEquipment.status)")
                            Spacer()
                        }
                        if selectedEquipment.needsService {
                            if let serviceDate = selectedEquipment.lastServiceDate {
                                if let every = selectedEquipment.serviceFrequencyEvery {
                                    if let frequency = selectedEquipment.serviceFrequency {
                                        if let nextServiceDate = selectedEquipment.nextServiceDate {
                                            HStack{
                                                Text("Last Service Date: ")
                                                
                                                Text("\(fullDate(date:serviceDate))")
                                                Spacer()
                                            }
                                            HStack{
                                                Text("Service Frequency: ")
                                                
                                                Text("\(every) \(frequency)")
                                                Spacer()
                                            }
                                            HStack{
                                                Text("Next Service Date: ")
                                                
                                                Text("\(fullDate(date: nextServiceDate))")
                                                    .padding(5)
                                                
                                                    .background(nextServiceDate > Date() ? Color.poolGreen : Color.poolRed)
                                                    .cornerRadius(5)
                                                    .foregroundColor(Color.basicFontText)
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        HStack{
                            Text("Notes: ")
                            
                            Text("\(selectedEquipment.notes)")
                            Spacer()
                        }
                        
                    }
                } else {
                    VStack{
                        HStack{
                            Text("Category: ")
                            
                            
                            Text("\(equipment.category)")
                            Spacer()
                        }
                        HStack{
                            Text("Make: ")
                            
                            
                            Text("\(equipment.make)")
                            Spacer()
                        }
                        HStack{
                            Text("Model: ")
                            
                            Text("\(equipment.model)")
                            Spacer()
                        }
                    }
                    VStack{
                        HStack{
                            Text("Date Installed: ")
                            
                            Text("\(fullDate(date: equipment.dateInstalled))")
                            
                            Spacer()
                        }
                        HStack{
                            Text("Status: ")
                            
                            Text("\(equipment.status)")
                            Spacer()
                        }
                        if equipment.needsService {
                            if let serviceDate = equipment.lastServiceDate {
                                if let every = equipment.serviceFrequencyEvery {
                                    if let frequency = equipment.serviceFrequency {
                                        if let nextServiceDate = equipment.nextServiceDate {
                                            HStack{
                                                Text("Last Service Date: ")
                                                
                                                Text("\(fullDate(date:serviceDate))")
                                                Spacer()
                                            }
                                            HStack{
                                                Text("Service Frequency: ")
                                                
                                                Text("\(every) \(frequency)")
                                                Spacer()
                                            }
                                            HStack{
                                                Text("Next Service Date: ")
                                                
                                                Text("\(fullDate(date: nextServiceDate))")
                                                    .padding(5)
                                                
                                                    .background(nextServiceDate > Date() ? Color.poolGreen : Color.poolRed)
                                                    .cornerRadius(5)
                                                    .foregroundColor(Color.basicFontText)
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        HStack{
                            Text("Notes: ")
                            
                            Text("\(equipment.notes)")
                            Spacer()
                        }
                    }
                }
            }
            VStack{
                edit
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.5))
        .cornerRadius(8)
    }
    
}



