//
//  ServiceStopDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//


import SwiftUI

struct ServiceStopDetailView: View {
    @EnvironmentObject private var masterDataManager : MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @StateObject private var VM : ServiceStopDetailViewModel

//    @StateObject var serviceStopVM : ServiceStopsViewModel
    @StateObject var activeRouteVM = ActiveRouteViewModel()
    init(dataService:any ProductionDataServiceProtocol,serviceStop:ServiceStop) {
        _VM = StateObject(wrappedValue: ServiceStopDetailViewModel(dataService: dataService))
        self.servicestop = serviceStop
    }
    @State var servicestop:ServiceStop
    @State var finished:Bool = false
    @State var skipped:Bool = false
    @State var showSkipReason:Bool = false
    @State var skipReason:String = ""
    @State var isLoading:Bool = false
    
    @State var selectedScreen:serviceStopScreen = .waterDetails
    @State var stopData:StopData = StopData(id: "", date: Date(), serviceStopId: "", readings: [], dosages: [], bodyOfWaterId: "", customerId: "", serviceLocationId: "", userId: "")
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        VStack(spacing: 0){
                            switch selectedScreen {
                            case .info:
                                ServiceStopInfoView( serviceStop: servicestop, dataService: dataService)
                            case .waterDetails:
                                ServiceStopUtilityView(serviceStop:servicestop,stopData: $stopData)
                            case .equipmentDetails:
                                ServiceStopEquipmentView(serviceStop:servicestop)
                            case .photoSelection:
                                ServiceStopPhotoSelection()
                            case .recap:
                                ServiceStopRecapScreen(serviceStop:servicestop, stopData: $stopData)
                            case .tasks:
                                ServiceStopTaskView(serviceStop: servicestop)
                            case .locationStartUp:
                                if let location = VM.location {
                                    ServiceLocationStartUpView(dataService: dataService, serviceLocation: location)
                                }
                            }
                        }
                    }, header: {
                        screenSelector
                            .padding(8)
                            .background(.ultraThinMaterial)
                    })
                })
                .clipped()
            }

        }
        .environmentObject(VM)
        .navigationTitle("\(servicestop.customerName)")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif

        .task {
            if let company = masterDataManager.selectedCompany,let user = masterDataManager.user {
                do {
                    finished = servicestop.finished
                    skipped = servicestop.skipped
                    try await VM.onInitalLoad(companyId: company.id,  serviceStop: servicestop, userId: user.id)
                    if let receivedStopData = VM.stopData {
                        stopData = receivedStopData
                    }
                } catch {
                    print(error)
                    print("Error Getting Service stop")
                }
            }
        }
        .onChange(of: stopData, perform: { datum in
            Task{
                print("Change in Stop Data")
                if let comapny = masterDataManager.selectedCompany{
                    do {
                        try await VM.updateStopData(companyId: comapny.id, stopData: stopData)
                    } catch {
                        print("Failed to update Stop Data")
                        print(error)
                    }
                }
            }
        })
        .alert("Provide skip reason", isPresented: $showSkipReason) {
            TextField("reason", text: $skipReason)
            Button("OK", action: submitSkipReason)
        } message: {
            Text("Will send to customer and manager")
                .font(.footnote)
        }
    
        /*
         Developer maybe I need to Keep For mac
        .onChange(of: masterDataManager.selectedID, perform: { id in
            Task{
            if let selectedID = id, let company = masterDataManager.selectedCompany {
                isLoading = true
                do {
                    try await serviceStopVM.getServiceStopById(companyId: company.id, serviceStopId: selectedID)
                    if let stop = serviceStopVM.serviceStop {
                        finished = stop.finished
                        skipped = stop.skipped
                    }
                } catch {
                    print("Error Getting Service stop")
                }
                isLoading = false
            }
        }
        })
         */
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
    var screenSelector: some View {
            HStack{
                if  selectedScreen == .info {
                    Button(action: {
                        selectedScreen = .info
                    }, label: {
                        Text(serviceStopScreen.info.title())
                    })
                    .padding(5)
                    .background(Color.poolGreen)
                    .frame(height: 30)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
                } else {
                    Button(action: {
                        selectedScreen = .info
                    }, label: {
                        Text(serviceStopScreen.info.title())
                    })
                    .padding(5)
                    .frame(height: 30)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
                }
                if servicestop.checkList.contains(where: {$0.description == "Location Start Up"}) {
                    if selectedScreen == .locationStartUp {
                        Button(action: {
                            selectedScreen = .locationStartUp
                        }, label: {
                            Text(serviceStopScreen.locationStartUp.title())
                        })
                        .padding(5)
                        .background(Color.poolGreen)
                        .frame(height: 30)
                        .cornerRadius(5)
                        .foregroundColor(Color.white)
                        
                    } else {
                        Button(action: {
                            selectedScreen = .locationStartUp
                        }, label: {
                            Text(serviceStopScreen.locationStartUp.title())
                        })
                        .padding(5)
                        .frame(height: 30)
                        .cornerRadius(5)
                        .foregroundColor(Color.white)
                        
                    }
                }
                if  selectedScreen == .waterDetails {
                    Button(action: {
                        selectedScreen = .waterDetails
                    }, label: {
                        Text(serviceStopScreen.waterDetails.title())
                    })
                    .padding(5)
                    .background(Color.poolGreen)
                    .frame(height: 30)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
              
                } else {
                    Button(action: {
                        selectedScreen = .waterDetails
                    }, label: {
                        Text(serviceStopScreen.waterDetails.title())
                    })
                    .padding(5)
                    .frame(height: 30)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
                }
                if selectedScreen == .equipmentDetails {
                    Button(action: {
                        selectedScreen = .equipmentDetails
                    }, label: {
                        Text(serviceStopScreen.equipmentDetails.title())
                    })
                    .padding(5)
                    .background(Color.poolGreen)
                    .frame(height: 30)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)

                } else {
                    Button(action: {
                        selectedScreen = .equipmentDetails
                    }, label: {
                        Text(serviceStopScreen.equipmentDetails.title())
                    })
                    .padding(5)
                    .frame(height: 30)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
        
                }
                if selectedScreen == .photoSelection {
                    Button(action: {
                        selectedScreen = .photoSelection
                    }, label: {
                        Text(serviceStopScreen.photoSelection.title())
                    })
                    .padding(5)
                    .background(Color.poolGreen)
                    .frame(height: 30)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
       
                } else {
                    Button(action: {
                        selectedScreen = .tasks
                    }, label: {
                        Text(serviceStopScreen.tasks.title())
                    })
                    .padding(5)
                    .frame(height: 30)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)

                }
                if selectedScreen == .recap {
                    Button(action: {
                        selectedScreen = .recap
                    }, label: {
                        Text(serviceStopScreen.recap.title())
                    })
                    .padding(5)
                    .background(Color.poolGreen)
                    .frame(height: 30)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
       
                } else {
                    Button(action: {
                        selectedScreen = .recap
                    }, label: {
                        Text(serviceStopScreen.recap.title())
                    })
                    .padding(5)
                    .frame(height: 30)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
                 
                }

            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(Color.gray)
            .cornerRadius(5)
    }
}
