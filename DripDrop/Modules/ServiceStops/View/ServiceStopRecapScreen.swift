    //
    //  ServiceStopRecapScreen.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 3/18/24.
    //


import SwiftUI
import PhotosUI
struct ServiceStopRecapScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var VM : ServiceStopDetailViewModel
    
    
    @State var serviceStop:ServiceStop
    @Binding var stopData : StopData
    @State var tasks : [ServiceStopTask]
    
    @State var showPhotoSelectionOptions:Bool = false
    
    @State private var showCamera = false
    @State var image: UIImage?
    
    @State var opStatus:ServiceStopOperationStatus = .notFinished
    
    @State var showSkipReason:Bool = false
    @State var skipReason:String = ""
    @State var isLoading:Bool = true
    
    
        //Photos
    @State var pickerType:photoPickerType? = nil
    @State var selectedNewPicker:photoPickerType? = nil
    @State var selectedImage:UIImage? = nil
    @State var images:[UIImage] = []
//    @Binding var dropDropImages:[DripDropImage]
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{                               
                ScrollView(showsIndicators:false){
                    
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
                                if let company = masterDataManager.currentCompany{
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
                                if let company = masterDataManager.currentCompany{
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
                    }
                }
                .padding(.horizontal,16)
                .background(Color.darkGray.opacity(0.5))
            }
        }
        .alert("Provide skip reason", isPresented: $showSkipReason) {
            TextField("reason", text: $skipReason)
            Button("OK", action: submitSkipReason)
        } message: {
            Text("Will send to customer and manager")
                .font(.footnote)
        }
        .onAppear(perform: {
            opStatus = serviceStop.operationStatus
        })
        .onChange(of: selectedImage, perform: { image in
            if let image {
                images.append(image)
            }
            
        })
    }
    func submitSkipReason() {
        if skipReason == "" {
            print("Did not Provide a Reason")
        } else {
            print("You skipped because \(skipReason)")
        }
    }
}

struct ServiceStopRecapScreen_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
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
            userId: ""
        )
        @State var dripDropImages:[DripDropImage] = []
        ServiceStopRecapScreen(serviceStop: MockDataService().mockServiceStops.first!, stopData: $stopData, tasks: [])
    }
}
extension ServiceStopRecapScreen {
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
    var taskRecap: some View {
        VStack(alignment:.leading){
            HStack{
                Spacer()
                Text("Tasks")
                    .bold()
                Spacer()
            }
            Divider()
            ForEach(tasks, id:\.self) { task in
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
struct EquipmentRecapCardView: View {
    let equipment:Equipment
    let equipmentMeasurments:EquipmentMeasurements?
    var body: some View {
        VStack{
            if let measurements = equipmentMeasurments {
                switch equipment.category {
                case .cleaner:
                    Text("Cleaner")
                        .bold(true)
                case .pump:
                    Text("Pump")
                        .bold(true)
                    Text("\(measurements.status)")
                case .filter:
                    Text("Filter")
                        .bold(true)
                    Text("\(measurements.status)")
                    if let PSI = measurements.psi {
                        Text("\(String(PSI))")
                    } else {
                        Text("-")
                    }
                case .heater:
                    Text("Heater")
                        .bold(true)
                    Text("\(measurements.status)")
                    
                case .saltCell:
                    Text("Salt Cell")
                        .bold(true)
                    Text("\(measurements.status)")
                    
                case .light:
                    Text("Light")
                        .bold(true)
                    Text("\(measurements.status)")
                case .autoChlorinator:
                    Text("Light")
                        .bold(true)
                    Text("\(measurements.status)")
                case .controlSystem:
                    Text("Light")
                        .bold(true)
                    Text("\(measurements.status)")
                }
            }
        }
    }
}
