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
    @Published var loadedImages:[DripDropStoredImage] = []
    
    @Published var selectedDripDropPhotos:[DripDropImage] = []
    @Published var selectedEquipment:Equipment? = nil
    func onLoad(companyId:String,bodyOfWater:BodyOfWater) async throws {

                self.equipmentList = try await dataService.getEquipmentByBodyOfWater(companyId: companyId, bodyOfWater: bodyOfWater)
         
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
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if isLoading {
                    VStack{
                        Spacer()
                        LoadingSpinner()
                        Spacer()
                    }
                } else {
                    Divider()
                    info
                    photos
                    Rectangle()
                        .frame(height: 4)
                    equipment
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
                Text("Edit")
                    .modifier(AddButtonModifier())
            })
            .sheet(isPresented: $showEditSheet,onDismiss: {
                
            }, content: {
                if let BOW = masterDataManager.selectedBodyOfWater {
                    EditBodyOfWaterView(dataService:dataService, bodyOfWater: BOW)
                }
            })
        }
    }
    var info: some View {
        VStack{
            
            if let bodyOfWater = masterDataManager.selectedBodyOfWater {
                VStack{
                    HStack{
                        Text("Name: \(bodyOfWater.name)")
                        Spacer()
                        edit
                    }
                    
                    HStack{
                        Text("Gallons: \(bodyOfWater.gallons)")
                        Spacer()
                    }
                    
                    
                    HStack{
                        Text("Material: \(bodyOfWater.material)")
                        Spacer()
                    }
                    HStack{
                        Text("Shape:")
                        if let shape = bodyOfWater.shape {
                            Text("\(shape)")
                        }
                        Spacer()
                    }
                    HStack{
                        Text("Dimensions: \(bodyOfWater.material)")
                        Spacer()
                    }
                    HStack{
                        Text("Notes:")
                        if let notes = bodyOfWater.notes {
                            Text("\(notes)")
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.5))
        .cornerRadius(8)
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
    var equipment: some View {
        VStack{
            Divider()
            Text("Equipment Detail View")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false){
                HStack{
                    Button(action: {
                        showAddSheet = true
                    }, label: {
                        Image(systemName: "plus.square.on.square")
                            .modifier(AddButtonModifier())
                    })
                    .sheet(isPresented: $showAddSheet, content: {
                        AddEquipmentView(dataService: dataService, bodyOfWater: bodyOfWater)
                    })
                    if VM.equipmentList.count == 0 {
                        Button(action: {
                            showAddSheet = true
                        }, label: {
                            Text("Add First Equipment")
                        })
                    } else {
                        ForEach(VM.equipmentList){ equipment in
                            Button(action: {
                                Task{
                                    VM.selectedEquipment = nil
                                    VM.selectedEquipment = equipment
                                    masterDataManager.selectedEquipment = equipment
                                }
                            }, label: {
                                HStack{
                                    if equipment.status != .operational {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(Color.poolRed)
                                    }
                                    if VM.selectedEquipment == equipment {
                                        Text(equipment.category.rawValue)
                                            .modifier(AddButtonModifier())
                                    } else {
                                        Text(equipment.category.rawValue)
                                            .modifier(ListButtonModifier())
                                    }
                                }
                            })
                            .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                        }
                    }
                    
                }
            }
            if VM.selectedEquipment == nil {
                if VM.equipmentList.count == 0 {
                    Text("No Equipment")
                    Text("Please Set Up")
                } else {
                    Text("Please select an Equipment")
                }
            } else {
                if let equipment = VM.selectedEquipment {
                    EquipmentDetailView(dataService:dataService,equipment: equipment)
                } else {
                    Text("Please select an Equipment")
                }
            }
        }
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
                lastFilled: Date()
            )
        )
    }
}


