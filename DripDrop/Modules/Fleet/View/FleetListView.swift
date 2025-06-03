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
    @StateObject var fleetVM : FleetViewModel

    init(dataService:ProductionDataService){
        _fleetVM = StateObject(wrappedValue: FleetViewModel(dataService: dataService))
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
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await fleetVM.getFleetList(companyId: company.id)
                } catch {
                    print("Fleet Error")
                    print(error)
                }
            }
        }
        .toolbar{
            ToolbarItem(content: {
                Button(action: {
                    showAddVehical.toggle()
                }, label: {
                    Text("Add")
                        .foregroundColor(.poolWhite)
                        .fontDesign(.monospaced)
                        .padding(3)
                })
            })
        }
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
                        Text("Add First Vehical")
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
                        ZStack{
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 50, height: 50)
                                .overlay(
                            Image(systemName: "slider.horizontal.3")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(Color.white)
                            )
                        }
                        
                       
                    })
                    .padding(10)
    
                            Button(action: {

                            }, label: {
                                ZStack{
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(Color.green)
                                }
                            })

                    Button(action: {
                        showSearch.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.blue)
                        }
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
