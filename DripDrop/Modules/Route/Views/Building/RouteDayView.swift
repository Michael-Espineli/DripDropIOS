//
//  RouteStopDayFirstView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//
import SwiftUI

struct RouteDayView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @StateObject var VM : RouteManagmentViewModel
    @StateObject var companyVM = CompanyUserViewModel()

    init( dataService:any ProductionDataServiceProtocol,day:String){
        _VM = StateObject(wrappedValue: RouteManagmentViewModel(dataService: dataService))
        _day = State(wrappedValue: day)
    }
    @State var day:String
    @State var showAddNewRoute:Bool = false
    var body: some View {
        ZStack{
            ScrollView{
                VStack(spacing: 0){
                        HStack{
                            Text("\(day)")
                            Spacer()
                            Button(action: {
                                    if UIDevice.isIPhone {
                                        showAddNewRoute.toggle()
                                    } else {
                                        masterDataManager.newRoute = true
                                        masterDataManager.modifyRoute = false
                                        masterDataManager.reassignRoute = false
                                        masterDataManager.routeBuilderDay = day
                                    }
                            }, label: {
                                Image(systemName: "plus")
                            })
                            .sheet(isPresented: $showAddNewRoute, content: {
                                //DEVLOPER PLEASE FIX
                                NewRouteView(dataService: dataService, tech: CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active), day: day)
                                    
                                
                            })
                        }
                        .font(.headline)

                        .padding(.horizontal,16)
                        .padding(.vertical,8)
                    .background(Color.poolBlue)
                    .foregroundColor(Color.white)
                    .cornerRadius(5)
                    ForEach(VM.companyUsers){ tech in
                        RouteTechView(dataService: dataService, day: day, tech: tech)
                    }
                }
            }
        }
        .task {
            if let company = masterDataManager.selectedCompany {
                
                do {
                    try await VM.firstLoad(companyId: company.id)
                } catch {
                    print(error)
                }
            }
        }
    }
}

