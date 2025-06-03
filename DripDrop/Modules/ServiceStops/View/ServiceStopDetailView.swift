    //
    //  ServiceStopDetailView.swift
    //  BuisnessSide
    //
    //  Created by Michael Espineli on 12/2/23.
    //


import SwiftUI

struct ServiceStopDetailView: View {
    @EnvironmentObject private var navigationManager : NavigationStateManager
    @EnvironmentObject private var masterDataManager : MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @StateObject private var VM : ServiceStopDetailViewModel
    @StateObject var activeRouteVM : ActiveRouteViewModel
    
    init(dataService:any ProductionDataServiceProtocol,serviceStop:ServiceStop) {
        _VM = StateObject(wrappedValue: ServiceStopDetailViewModel(dataService: dataService))
        _activeRouteVM = StateObject(wrappedValue: ActiveRouteViewModel(dataService: dataService))
        
        _serviceStop = State(wrappedValue: serviceStop)
    }
    @State var serviceStop:ServiceStop
    @State var usableServiceStop:ServiceStop = ServiceStop(
        id: "",
        internalId: "",
        companyId: "",
        companyName: "",
        customerId: "",
        customerName: "",
        address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0),
        dateCreated: Date(),
        serviceDate: Date(),
        startTime: Date(),
        endTime: Date(),
        duration: 0,
        estimatedDuration: 0,
        tech: "",
        techId: "",
        recurringServiceStopId: "",
        description: "",
        serviceLocationId: "",
        typeId: "",
        type: "",
        typeImage: "",
        jobId: "",
        jobName: "",
        operationStatus: .notFinished,
        billingStatus: .notInvoiced,
        includeReadings: true,
        includeDosages: true,
        otherCompany: false,
        laborContractId: "",
        contractedCompanyId: "",
        isInvoiced: false
    )
    
    @State var opStatus:ServiceStopOperationStatus = .notFinished
    @State var showSkipReason:Bool = false
    @State var skipReason:String = ""
    @State var isLoading:Bool = false
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
        userId: ""
    )
    @State var dropDropImages:[DripDropImage] = []
    @State var title:String = ""
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
                //                screenSelector
            VStack(spacing: 0){
                toolbar
                switch selectedScreen {
                case .info:
                    ServiceStopInfoView( serviceStop: usableServiceStop, dataService: dataService)
                    
                case .tasks:
                    ServiceStopTaskView(dataService: dataService,taskList:$VM.taskList, serviceStop: usableServiceStop)
                    
                case .waterDetails:
                    ServiceStopUtilityView(serviceStop:usableServiceStop,stopData: $stopData)
                    
                case .equipmentDetails:
                    ServiceStopEquipmentView(serviceStop:usableServiceStop)
                    
                case .photoSelection:
                    ServiceStopPhotoSelection()
                    
                case .recap:
                    ServiceStopRecapScreen(serviceStop:usableServiceStop, stopData: $stopData,tasks:VM.taskList)
                    
                case .locationStartUp:
                    ServiceLocationStartUpViewInField(dataService: dataService, customerId: usableServiceStop.customerId,serviceLocationId:usableServiceStop.serviceLocationId, serviceStop: usableServiceStop)
                    
                case .checkList:
                    ServiceStopCheckListView(serviceStop: usableServiceStop, dataService: dataService)
                    
                }
            }
            
            if expandScreenSelector {
                VStack{
                    Spacer()
                    HStack{
                        Spacer()
                    }
                }
                .background(Color.darkGray.opacity(0.85))
                .onTapGesture(perform: {
                    print("Toggle expandScreenSelector")
                    expandScreenSelector.toggle()
                })
            }
            if expandScreenSelector {
                verticalScreenSelector
            }
            
        }
        .environmentObject(VM)
//        .navigationTitle(title)
        .navigationBarBackButtonHidden(true)
        .task {
            title = serviceStop.customerName
                //                if servicestop.typeId == "1" { //Developer Change Before Release
            if serviceStop.typeId == "0E398067-1E3D-487A-BC21-1CC3A54933D5" {
                selectedScreen = .waterDetails
            } else if serviceStop.typeId == "2"{
                selectedScreen  = .locationStartUp
            } else {
                selectedScreen = .tasks
            }
            if let company = masterDataManager.currentCompany,let user = masterDataManager.user {
                do {
                    usableServiceStop = serviceStop
                    opStatus = serviceStop.operationStatus
    
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
        .onChange(of: masterDataManager.selectedServiceStops, perform: { datum in
            Task{
                if let datum {
                    title = datum.customerName
                    print("Change in Service Stop Detail \(datum.id)")
                    usableServiceStop = datum
                    if let company = masterDataManager.currentCompany,let user = masterDataManager.user {
                        do {
                            opStatus = serviceStop.operationStatus
                            if serviceStop.otherCompany {
                                if serviceStop.contractedCompanyId != "" {
                                    try await VM.onInitalLoad(companyId: serviceStop.contractedCompanyId,  serviceStop: serviceStop, userId: user.id)
                                } else {
                                    try await VM.onInitalLoad(companyId: company.id,  serviceStop: serviceStop, userId: user.id)
                                }
                            } else {
                                try await VM.onInitalLoad(companyId: company.id,  serviceStop: serviceStop, userId: user.id)
                            }
                            if let receivedStopData = VM.stopData {
                                stopData = receivedStopData
                            }
                        } catch {
                            print(error)
                            print("Error Getting Service stop")
                        }
                    }
                }
            }
        })
            // Changes in Stop Data
        .onChange(of: stopData, perform: { datum in
            Task{
                print("Change in Stop Data")
                if let comapny = masterDataManager.currentCompany{
                    do {
                        try await VM.updateStopData(companyId: comapny.id,serviceStop: serviceStop, stopData: stopData)
                        print("Done")
                    } catch {
                        print("Failed to update Stop Data")
                        print(error)
                    }
                }
            }
        })
        .onChange(of: VM.selectedDripDropPhotos, perform: { photo in
            if let currentCompany = masterDataManager.currentCompany {
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
}


extension ServiceStopDetailView {
    var toolbar: some View {
        HStack(alignment: .top){
            Button(action: {
                navigationManager.routes.removeLast()
            }, label: {
                HStack{
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            })
            Spacer()
            Text(title)
                .font(.title)
            Spacer()
               Button(action: {
                   expandScreenSelector.toggle()
               }, label: {
                   ZStack{
                       switch selectedScreen {
                       case .info:
                           Image(systemName: "info.circle")
                       case .waterDetails:
                           Image(systemName: "drop.fill")
                           
                       case .tasks:
                           Image(systemName: "chart.bar.doc.horizontal")
                           
                       case .equipmentDetails:
                           Image(systemName: "spigot.fill")
                           
                       case .photoSelection:
                           Image(systemName: "photo.on.rectangle.angled")
                           
                       case .recap:
                           Image(systemName: "checkerboard.rectangle")
                           
                       case .locationStartUp:
                           Image(systemName: "location.circle.fill")
                       case .checkList:
                           Image(systemName: "chart.bar.doc.horizontal")
                       }
                   }
                   .font(.title)
                   .foregroundColor(Color.white)
                   .modifier(BlueButtonModifier())
                   .modifier(OutLineButtonModifier())
               })
        }
        .padding(.horizontal,8)
    }
    var screenSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack{
                    //Info
                if  selectedScreen == .info {
                    Button(action: {
                        selectedScreen = .info
                    }, label: {
                        Text(serviceStopScreen.info.title())
                            .modifier(SubmitButtonModifier())
                            .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .info
                    }, label: {
                        Text(serviceStopScreen.info.title())
                            .modifier(ListButtonModifier())
                            .modifier(OutLineButtonModifier())
                    })
                }
                if selectedScreen == .tasks {
                    Button(action: {
                        selectedScreen = .tasks
                    }, label: {
                        Text(serviceStopScreen.tasks.title())
                            .modifier(SubmitButtonModifier())
                            .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .tasks
                    }, label: {
                        Text(serviceStopScreen.tasks.title())
                            .modifier(ListButtonModifier())
                            .modifier(OutLineButtonModifier())
                    })
                }
                if  selectedScreen == .waterDetails {
                    Button(action: {
                        selectedScreen = .waterDetails
                    }, label: {
                        Text(serviceStopScreen.waterDetails.title())
                            .modifier(SubmitButtonModifier())
                            .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .waterDetails
                    }, label: {
                        Text(serviceStopScreen.waterDetails.title())
                            .modifier(ListButtonModifier())
                            .modifier(OutLineButtonModifier())
                    })
                }
                if selectedScreen == .equipmentDetails {
                    Button(action: {
                        selectedScreen = .equipmentDetails
                    }, label: {
                        Text(serviceStopScreen.equipmentDetails.title())
                            .modifier(SubmitButtonModifier())
                            .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .equipmentDetails
                    }, label: {
                        Text(serviceStopScreen.equipmentDetails.title())
                            .modifier(ListButtonModifier())
                            .modifier(OutLineButtonModifier())
                    })
                }
                if selectedScreen == .recap {
                    Button(action: {
                        selectedScreen = .recap
                    }, label: {
                        Text(serviceStopScreen.recap.title())
                            .modifier(SubmitButtonModifier())
                            .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .recap
                    }, label: {
                        Text(serviceStopScreen.recap.title())                            
                            .modifier(ListButtonModifier())
                            .modifier(OutLineButtonModifier())

                    })
                }
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
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
}
