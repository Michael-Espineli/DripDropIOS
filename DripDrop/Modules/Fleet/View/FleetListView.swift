//
//  FleetListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import SwiftUI

struct FleetListView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var fleetVM : FleetViewModel

    init(dataService:ProductionDataService){
    }
    @State var showSearch:Bool = false
    @State var searchTerm:String = ""
    @State var showAddVehical:Bool = false

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
            icons
            Text("")
                .sheet(isPresented: $showAddVehical, onDismiss: {
                    Task{
                        if let company = masterDataManager.currentCompany {
                            do {
                                try await fleetVM.getFleetList(companyId: company.id)
                            } catch {
                                print("Fleet Error")
                                print(error)
                            }
                        }
                    }
                }, content: {
                    AddNewVehical(dataService: dataService)
                })
        }
        .onAppear(perform: {
            fleetVM.onLoadVehicalList(companyId: masterDataManager.currentCompany?.id)
        })
        .onDisappear(perform: {
            fleetVM.stop()
        })
//        .task {
//            if let company = masterDataManager.currentCompany {
//                do {
//                    try await fleetVM.getFleetList(companyId: company.id)
//                } catch {
//                    print("Fleet Error")
//                    print(error)
//                }
//            }
//        }
    }
}

struct FleetListView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()

    static var previews: some View {
        FleetListView(dataService: dataService)
    }
}
extension FleetListView {
    var list: some View {
        VStack{
                if fleetVM.listOfVehicals.isEmpty {
                    Spacer()
                    Button(action: {
                        showAddVehical.toggle()
                    }, label: {
                        Text("Add First Vehicle")
                            .modifier(AddButtonModifier())
                    })
                    Spacer()
                } else {
                    ScrollView{
                        ForEach(fleetVM.listOfVehicals){ vehical in
                            Divider()
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.vehicalDetailView(vehical:vehical,dataService: dataService), label: {
                                    VehicleCardView(vehical: vehical)
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedCategory = .fleet
                                    masterDataManager.selectedVehical = vehical
                                }, label: {
                                    VehicleCardView(vehical: vehical)
                                })
                            }
                        }
                    }
                }
            
        }
        .padding(.horizontal,8)
    }
    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {

                    }, label: {
                        Image(systemName: "slider.horizontal.3")
                            .modifier(FilterIconModifer())
                    })
                    .padding(10)
    
                    Button(action: {
                        showAddVehical.toggle()
                    }, label: {
                        Image(systemName: "plus")
                            .modifier(PlusIconModifer())
                    })

                    Button(action: {
                        showSearch.toggle()
                    }, label: {
                        Image(systemName: "magnifyingglass")
                            .modifier(SearchIconModifer())
                    })
                    .padding(10)

                }
            }
            if showSearch {
                HStack{
                    TextField(
                        "Search",
                        text: $searchTerm
                    )
                    Button(action: {
                        searchTerm = ""
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
                .modifier(SearchTextFieldModifier())
                .padding(8)
            }
            
        }

    }
}
