//
//  ServiceStopDetailView 2.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/3/26.
//
import SwiftUI
import UniformTypeIdentifiers

struct ServiceStopDetailView2: View {
    init(dataService:any ProductionDataServiceProtocol,serviceStopId:String) {
        _VM = StateObject(wrappedValue: ServiceStopDetailViewModel(dataService: dataService))
        _activeRouteVM = StateObject(wrappedValue: ActiveRouteViewModel(dataService: dataService))
        _serviceStopId = State(wrappedValue: serviceStopId)
    }
    
    @StateObject private var VM : ServiceStopDetailViewModel
    @StateObject var activeRouteVM : ActiveRouteViewModel
    
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var navigationManager : NavigationStateManager

    @EnvironmentObject private var vm: MobileDailyRouteDisplayViewModel
    @State var serviceStopId: String

    @State var opStatus:ServiceStopOperationStatus?

    @State private var isSaving = false
    
    @State var showSkipReason:Bool = false
    @State var skipReason:String = ""
    @State var expandScreenSelector:Bool = false
    @State var selectedScreen:serviceStopScreen = .waterDetails
    @State var stopData:StopData = StopData(
        id: "",
        date: Date(),
        serviceStopId: "",
        readings: [],
        dosages: [],
        observation: [],
        bodyOfWaterId: "",
        customerId: "",
        serviceLocationId: "",
        userId: "",
        equipmentMeasurements: []
    )
    @State var dropDropImages:[DripDropImage] = []
    @State var title:String = ""

    private var serviceStop: ServiceStop? {
        vm.serviceStopList.first { $0.id == serviceStopId }
    }
//Recap Variables
    @State var showPhotoSelectionOptions:Bool = false
    @State var pickerType:photoPickerType? = nil
    @State var selectedNewPicker:photoPickerType? = nil
    @State var selectedImage:UIImage? = nil
    @State var images:[UIImage] = []
    @State private var selectedTab = "Water"

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack(spacing: 0){
                if let stop = serviceStop {
                    TabView(selection: $selectedTab) {
                        ServiceStopInfoView( serviceStop: stop, dataService: dataService)
                             .tabItem {
                                 Image(systemName: "info.circle")
                                 Text("Info")
                             }
                             .tag("Info")
                        ServiceStopTaskView(dataService: dataService,taskList:$VM.taskList, serviceStop: stop)
                             .tabItem {
                                 Image(systemName: "chart.bar.doc.horizontal")
                                 Text("Tasks")
                             }
                             .tag("Tasks")

                        ServiceStopUtilityView(serviceStop:stop,stopData: $stopData)
                             .tabItem {
                                 Image(systemName: "spigot.fill")
                                 Text("Water")
                             }
                             .tag("Water")
                        ServiceStopEquipmentView(serviceStop:stop, stopData: $stopData)
                             .tabItem {
                                 Image(systemName: "wrench.and.screwdriver.fill")
                                 Text("Equipment")
                             }
                             .tag("Equipment")
                        recap
                             .tabItem {
                                 Image(systemName: "checkerboard.rectangle")
                                 Text("Finish")
                             }
                             .tag("Finish")
                     }
                    
                }
            }
        
        }
        .navigationTitle(title)
        .environmentObject(VM)
        .onAppear {
            if let stop = serviceStop {
                
                opStatus = stop.operationStatus
            }
        }
        .task {
            
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user, let serviceStop {
                title = serviceStop.customerName

                do {
    
                    try await VM.onInitalLoad(companyId: company.id,  serviceStop: serviceStop, userId: user.id)

                    if let receivedStopData = VM.stopData {
                        stopData = receivedStopData
                    }
                } catch {
                    print("Error Getting Service stop")
                    print(error)
                }
            }
        }
        .onChange(of: stopData, perform: { datum in
            Task{
                print("Change in Stop Data")
                if let comapny = masterDataManager.currentCompany, let serviceStop {
                    do {
                        try await VM.updateStopData(companyId: comapny.id,serviceStop: serviceStop, stopData: stopData)
                        print("[ServiceStopDetailView][onChange:stopData] Updated")
                    } catch {
                        print("Failed to update Stop Data")
                        print(error)
                    }
                }
            }
        })
        .onChange(of: VM.selectedDripDropPhotos, perform: { photo in
            if let currentCompany = masterDataManager.currentCompany, let serviceStop {
                if serviceStop.otherCompany && serviceStop.contractedCompanyId != "" {
                    VM.updatePhotoUrl(companyId: serviceStop.contractedCompanyId, serviceStopId: serviceStop.id)
                }
                VM.updatePhotoUrl(companyId: currentCompany.id, serviceStopId: serviceStop.id)

            }
        })
        .alert("Provide skip reason", isPresented: $showSkipReason) {
            TextField("reason", text: $skipReason)
            Button("OK", action: submitSkipReason)
        } message: {
            Text("Will send to customer and manager")
                .font(.footnote)
        }
    }
    func submitSkipReason() {
        if skipReason == "" {
            print("Did not Provide a Reason")
        } else {
            print("You skipped because \(skipReason)")
        }
    }

    private func save(companyId:String?, _ stop: ServiceStop) {
//        guard let newStatus = opStatus else { return }
        guard let companyId else { return }
        guard let opStatus else { return }
        isSaving = true

        vm.updateServiceStopStatus(
            companyId: companyId,
            stopId: stop.id,
            status: opStatus
        )
        print("[ServiceStopDetailView2][updateServiceStopStatus]")
        isSaving = false
        
    }
}
extension ServiceStopDetailView2 {
    var verticalScreenSelector: some View {
        HStack(alignment:.top){
            VStack(alignment: .trailing, spacing: 16) {
                    //Info
                if  selectedScreen == .info {
                    Button(action: {
                        selectedScreen = .info
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "info.circle")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Info")
                            }
                        }
                        .modifier(BlueButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .info
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "info.circle")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Info")
                            }
                        }
                        .modifier(ListButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                }
                if selectedScreen == .tasks {
                    Button(action: {
                        selectedScreen = .tasks
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "chart.bar.doc.horizontal")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Tasks")
                            }
                        }
                        .modifier(BlueButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .tasks
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "chart.bar.doc.horizontal")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Tasks")
                            }
                        }
                        .modifier(ListButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                }
                if  selectedScreen == .waterDetails {
                    Button(action: {
                        selectedScreen = .waterDetails
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "drop.fill")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Water Details")
                            }
                        }
                        .modifier(BlueButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .waterDetails
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "drop.fill")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Water Details")
                            }
                        }
                        .modifier(ListButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                }
                if selectedScreen == .equipmentDetails {
                    Button(action: {
                        selectedScreen = .equipmentDetails
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "spigot.fill")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Equipment")
                            }
                        }
                        .modifier(BlueButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .equipmentDetails
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "spigot.fill")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Equipment")
                            }
                        }
                        .modifier(ListButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                }
                if selectedScreen == .recap {
                    Button(action: {
                        selectedScreen = .recap
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "checkerboard.rectangle")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Recap")
                            }
                        }
                        .modifier(BlueButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .recap
                        expandScreenSelector.toggle()
                        
                    }, label: {
                        HStack{
                            Image(systemName: "checkerboard.rectangle")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Recap")
                            }
                        }
                        .modifier(ListButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                }
            }
            .padding(16)
        }
    }
    
    //Recap Screen information based on Recap View
    var recap: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                ScrollView(showsIndicators:false){
                    if let serviceStop {
                        if serviceStop.typeId == "0E398067-1E3D-487A-BC21-1CC3A54933D5" {
                            waterRecap
                        } else if serviceStop.typeId == "2"{
                            startUpRecap
                        } else {
                            waterRecap
                        }
                        Rectangle()
                            .frame(height: 1)
                        observationRecap
                        Rectangle()
                            .frame(height: 1)
                        taskRecap
                        Rectangle()
                            .frame(height: 1)
                        
                        photos
                    }
                }
                .padding(.horizontal,8)
                    //Final Buttons

                HStack{
                    switch opStatus {
                    case .finished:
                        Button(action: {
                            opStatus = .skipped
                            showSkipReason = true
                        }, label: {
                            Text("Skip")
                                .foregroundColor(Color.white)
                                .padding(5)
                                .background(Color.gray)
                                .cornerRadius(5)
                        })
                        .padding(5)
                        Spacer()
                        Button(action: {
                            Task{
                                if let company = masterDataManager.currentCompany, let serviceStop{
                                    opStatus = .notFinished
                                    do {
                                        print("")
                                        try await VM.updateServicestopOperationStatus(companyId: company.id, stop: serviceStop, operationStatus: .notFinished)
                                        if serviceStop.otherCompany && serviceStop.contractedCompanyId != "" {
                                            try await VM.updateServicestopOperationStatus(companyId: serviceStop.contractedCompanyId, stop: serviceStop, operationStatus: .notFinished)
                                        }
                                        print("Un finished")
                                        print("Successful")
                                        print("")
                                    } catch {
                                        
                                        print("Failed To Updated Finish Stops \(serviceStop.id)")
                                        print(error)
                                        print("")
                                    }
                                    navigationManager.goBack()
                                } else {
                                    
                                    print("Either Invalid Company or active Route")
                                }
                            }
                        }, label: {
                            Text("Finished")
                                .modifier(DismissButtonModifier())
                        })
                        .padding(5)
                    case .notFinished:
                        Button(action: {
                            opStatus = .skipped
                            showSkipReason = true
                        }, label: {
                            Text("Skip")
                                .modifier(YellowButtonModifier())
                        })
                        .padding(5)
                        Spacer()
                        Button(action: {
                            Task{
                                if let company = masterDataManager.currentCompany, let serviceStop{
                                    opStatus = .finished
                                    do {
                                        print("")
                                        print("Finishing Screen")
                                        print("-----------------")
                                        
                                        try await VM.updateServicestopOperationStatus(companyId: company.id, stop: serviceStop, operationStatus: .finished)
                                    } catch {
                                        print("Failed To Updated Finish Stops \(serviceStop.id)")
                                        print(error)
                                        print("")
                                    }
                                    
                                    // Add Observations
                                    //Add Data
                                    navigationManager.goBack()
                                } else {
                                    print("Either Invalid Company or active Route")
                                }
                            }
                        }, label: {
                            Text("Finish")
                                .modifier(SubmitButtonModifier())
                            
                        })
                        .padding(5)
                    case .skipped:
                        Button(action: {
                            Task{
                                if let serviceStop = masterDataManager.selectedServiceStops, let company = masterDataManager.currentCompany {
                                    do{
                                        opStatus = .notFinished
                                        
                                        if serviceStop.otherCompany && serviceStop.contractedCompanyId != "" {
                                            try await VM.updateServicestopOperationStatus(companyId: serviceStop.contractedCompanyId, stop: serviceStop, operationStatus: .notFinished)
                                        }
                                        try await VM.updateServicestopOperationStatus(companyId: company.id, stop: serviceStop, operationStatus: .notFinished)
                                    } catch {
                                        print("Error")
                                    }
                                }
                            }
                        }, label: {
                            Text("Unskip")
                                .modifier(YellowButtonModifier())

                        })
                    case .none:
                        Text("none")
                    }
                }
                .padding(.horizontal,16)
                .background(Color.darkGray.opacity(0.5))
            }
        }

    }
    var finalButtons: some View {
        HStack{
            VStack{
                Button(action: {
                    showPhotoSelectionOptions.toggle()
                }, label: {
                    ZStack{
                        Circle()
                            .fill(Color.white)
                            .frame(width: 50, height: 50)
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.poolGreen)
                    }
                    
                })
                .confirmationDialog("Select Type", isPresented: self.$showPhotoSelectionOptions, actions: {
                    Button(action: {
                        self.pickerType = .album
                        self.selectedNewPicker = .album
                    }, label: {
                        Text("Album")
                    })
                    Button(action: {
                        self.pickerType = .camera
                        self.selectedNewPicker = .camera
                        
                    }, label: {
                        Text("Camera")
                    })
                    
                })
                .sheet(item: self.$pickerType,onDismiss: {
                    
                }){ item in
                    switch item {
                    case .album:
                        NavigationView{
                            VStack{
                                HStack{
                                    Spacer()
                                    Button(action: {
                                        pickerType = nil
                                    }, label: {
                                        Text("Done")
                                    })
                                    .padding(16)
                                }
                                ImagePicker(image: self.$selectedImage)
                            }
                        }
                    case .camera:
                        NavigationView{
                            accessCameraView(selectedImage: self.$selectedImage)
                        }
                    }
                    
                }
            }
            if images.isEmpty {
                if let selectedImage{
                    Image(uiImage: selectedImage)
                        .resizable()
                        .frame(width: 100)
                        .scaledToFit()
                } else {
                    Button(action: {
                        showPhotoSelectionOptions = true
                        print("add New Photo")
                    }, label: {
                        Image(systemName: "photo.fill")
                            .resizable()
                            .frame(width: 100)
                            .scaledToFit()
                        
                            .foregroundColor(Color.blue)
                    })
                }
            } else {
                ForEach(images,id:\.self){image in
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 100)
                        .scaledToFit()
                }
            }
        }
        .frame(height: 100)
    }
    var waterRecap: some View {
        HStack{
            titleRow
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                readingsDosagesEquipment
            }
        }
    }
    var titleRow: some View {
        VStack{
            Divider()
            VStack{
                VStack{
                        Text("Readings")
                            .lineLimit(1,reservesSpace: true)
                        
                            .font(.headline)
                    
                    ForEach(VM.readingTemplates) { template in
                        Text("\(String(template.name.prefix(10)))")
                    }
                }
                Divider()
                VStack{
                        Text("Dosages")
                            .lineLimit(1,reservesSpace: true)
                            .font(.headline)
                    
                    ForEach(VM.dosageTemplates) { template in
                        Text("\(String((template.name ?? "").prefix(10)))")
                    }
                }
                Divider()
                Spacer()
            }
        }
        .frame(width: 100)
    }
    var readingsDosagesEquipment: some View {
        VStack{
            Divider()
            HStack{
                ForEach(VM.bodiesOfWater) { BOW in
                    VStack{
                        VStack{
                            Text("\(BOW.name)")
                                .lineLimit(1,reservesSpace: true)

                                .font(.headline)
                                .frame(width: 60)
                            ChemReadingRecap(dataService: dataService,templates: VM.readingTemplates, BOW: BOW)
                        }
                        Divider()
                        VStack{
                            Text("\(BOW.name)")
                                .lineLimit(1,reservesSpace: true)
                                .font(.headline)
                                .frame(width: 60)
                            ChemDosageRecap(dataService: dataService, templates: VM.dosageTemplates, BOW: BOW)
                        }
                        Divider()
                        VStack{
                            ForEach(VM.BOWEquipmentDick[BOW] ?? []){ equipment in
                                EquipmentRecapCardView(equipment: equipment, equipmentMeasurments: VM.EquipmentReadings[equipment])
                            }
                        }
                        Divider()
                    }
                    Divider()
                }
            }
        }
    }
    var photos: some View {
        VStack{
            PhotoContentView(selectedImages: $VM.selectedDripDropPhotos)
            if !VM.selectedDripDropPhotos.isEmpty {
                HStack{
                    ProgressView()
                    Text("Loading...")
                }
            }
            DripDropStoredImageRow(images:VM.loadedImages)
        }
    }
    var taskRecap: some View {
        VStack(alignment:.leading){
            HStack{
                Spacer()
                Text("Tasks")
                    .bold()
                Spacer()
            }
            Divider()
            ForEach(VM.taskList, id:\.self) { task in
                Text("\(task.name) - \(task.status.rawValue)")
            }
        }
    }
    var observationRecap: some View {
        VStack(alignment:.leading){
            HStack{
                Spacer()
                Text("Observations")
                    .bold()
                Spacer()
            }
            Divider()
            ForEach(stopData.observation, id:\.self) { observation in
                
                Text(observation)
            }
            
        }
    }
    var startUpRecap: some View {
        VStack{
            Text("start Up Recap")
        }
    }
}
