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
    @EnvironmentObject var VM: RouteBoardViewModel
    @StateObject var companyVM = CompanyUserViewModel()
    

    
    @State var day: DaysOfWeek
    @State var showAddNewRoute:Bool = false
    var body: some View {
        ZStack{
            ScrollView{
                HStack{
                    Text(day.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                        Button(action: {
                            if UIDevice.isIPhone {
                                showAddNewRoute.toggle()
                            } else {
                                masterDataManager.newRoute = true
                                masterDataManager.modifyRoute = false
                                masterDataManager.reassignRoute = false
                                masterDataManager.selectedRouteBuilderDay = day
                                showAddNewRoute.toggle()
                            }
                        }, label: {
                            Image(systemName: "plus")
                                .font(.subheadline)
                                .padding(8)
                                .background(Color.gray.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        })
                    
                    .sheet(isPresented: $showAddNewRoute, content: {
                        //DEVLOPER PLEASE FIX
                        NewRouteView(dataService: dataService, tech: CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active,workerType: .contractor), day: day)
                    })
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                
                ForEach(VM.companyUsers){ tech in
                    RouteTechView2(tech: tech, day: day)
                }
                .padding(.leading, 8)
            }
        }
    }
}

