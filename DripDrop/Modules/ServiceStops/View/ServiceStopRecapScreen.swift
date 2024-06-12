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

    @State var showPhotoSelectionOptions:Bool = false
    
    @State private var showCamera = false
    @State var image: UIImage?
    
    @State var finished:Bool = false
    @State var skipped:Bool = false
    @State var showSkipReason:Bool = false
    @State var skipReason:String = ""
    @State var isLoading:Bool = true
    
    
    //Photos
    @State var pickerType:photoPickerType? = nil
    @State var selectedNewPicker:photoPickerType? = nil
    @State var selectedImage:UIImage? = nil
    @State var images:[UIImage] = []

    var body: some View {
            ZStack{
                Color.listColor.ignoresSafeArea()
                ScrollView{
                    VStack{
                        Text("Summary")
                        //Main Email / Service Stop Photo
                        ScrollView(.horizontal, showsIndicators: false) {
                            finalButtons
                            
                        }
                        HStack{
                            titleRow
                            Divider()
                            ScrollView(.horizontal, showsIndicators: false) {
                                readingsDosagesEquipment
                            }
                        }
                        Spacer()
                        //Final Buttons
                        HStack{
                            if skipped{
                                Button(action: {
                                    Task{
                                        if let serviceStop = masterDataManager.selectedServiceStops, let company = masterDataManager.selectedCompany {
                                            do{
                                                self.skipped.toggle()
                                                try await VM.skipServiceStop(companyId: company.id, stop: serviceStop, skip: skipped)
                                            } catch {
                                                print("Error")
                                            }
                                        }
                                    }
                                }, label: {
                                    Text("Unskip")
                                        .foregroundColor(Color.white)
                                        .padding(5)
                                        .background(Color.red)
                                        .cornerRadius(5)
                                })
                            } else {
                                Button(action: {
                                    self.skipped.toggle()
                                    showSkipReason = true
                                }, label: {
                                    Text("Skip")
                                        .foregroundColor(Color.white)
                                        .padding(5)
                                        .background(Color.gray)
                                        .cornerRadius(5)
                                })
                                .padding(5)
                            }
                            
                            if !skipped {
                                Button(action: {
//                                    Task{
//                                        if let company = navigationManager.selectedCompany, let activeRoute = navigationManager.selectedActiveRoute{
//                                            self.finished.toggle()
//                                            do {
//                                                try await VM.finishServiceStop(companyId: company.id, stop: serviceStop, finish: finished, activeRoute: activeRoute)
//                                            } catch {
//                                                print("Failed To Updated Finish Stops \(serviceStop.id)")
//                                            }
//                                            
//                                            // Add Observations
//                                            //Add Data
//                                            navigationManager.goBack()
//                                        } else {
//                                            print("Either Invalid Company or active Route")
//                                        }
//                                    }
                                    Task{
                                        if let company = masterDataManager.selectedCompany{
                                            self.finished.toggle()
                                            do {
                                                try await VM.finishServiceStop(companyId: company.id, stop: serviceStop, finish: finished)
                                            } catch {
                                                print("Failed To Updated Finish Stops \(serviceStop.id)")
                                            }
                                            
                                            // Add Observations
                                            //Add Data
                                            navigationManager.goBack()
                                        } else {
                                            print("Either Invalid Company or active Route")
                                        }
                                    }
                                }, label: {
                                    if finished {
                                        Text("Finished")
                                            .foregroundColor(Color.white)
                                            .padding(5)
                                            .background(Color.poolGreen)
                                            .cornerRadius(5)
                                        
                                        
                                    } else {
                                        Text("Finish")
                                            .foregroundColor(Color.white)
                                            .padding(5)
                                            .background(Color.poolRed)
                                            .cornerRadius(5)
                                    }
                                })
                                .padding(5)
                            }
                            
                        }
                        
                        
                    }
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
            finished = serviceStop.finished
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
        @State var stopData:StopData = StopData(id: "", date: Date(), serviceStopId: "", readings: [], dosages: [], bodyOfWaterId: "", customerId: "", serviceLocationId: "", userId: "")
        ServiceStopRecapScreen(serviceStop: ServiceStop(id: "", typeId: "", customerName: "", customerId: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), dateCreated: Date(), serviceDate: Date(), duration: 0, rate: 0, tech: "", techId: "", recurringServiceStopId: "", description: "", serviceLocationId: "", type: "", typeImage: "", jobId: "", jobName: "", finished: false, skipped: false, invoiced: false, checkList: [], includeReadings: false, includeDosages: false), stopData: $stopData)
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
    var titleRow: some View {
        VStack{
            Divider()
            Text("Readings")
                .font(.headline)
            ForEach(VM.readingTemplates) { template in
                Text("\(String(template.name.prefix(10)))")
            }
            Divider()
            VStack{
                Text("Dosages")
                    .font(.headline)
                ForEach(VM.dosageTemplates) { template in
                    Text("\(String((template.name ?? "").prefix(10)))")
                }
            }
            Divider()
            Spacer()
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
                                .font(.headline)
                                .frame(width: 60)
                            ChemReadingRecap(dataService: dataService,templates: VM.readingTemplates, BOW: BOW)
                        }
                        Divider()
                        VStack{
                            Text("\(BOW.name)")
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

    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    if showPhotoSelectionOptions {
                        Button(action: {
                            print("Add Album Selection Logic")
                        }, label: {
                            
                            ZStack{
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                Image(systemName: "photo.circle")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.yellow)
                            }
                        })
                        Button(action: {
                            showCamera = true
                            print("Add Camera Logic")
                        }, label: {
                            ZStack{
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                Image(systemName: "camera.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.blue)
                            }
                        })
                        .fullScreenCover(isPresented: $showCamera) {
                            accessCameraView(selectedImage: self.$selectedImage)
                        }
                    }
                    Button(action: {
                        showPhotoSelectionOptions.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            Image(systemName: showPhotoSelectionOptions ? "xmark.circle.fill" : "plus.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(showPhotoSelectionOptions ? Color.red : Color.poolGreen)
                        }
                        
                    })
                }
            }
            .padding(20)
        }
        .padding(20)
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
                    
                }
            }
        }
    }
}
