//
//  UserRouteOverView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/19/23.
//

import SwiftUI

struct UserRouteOverView: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService
    init(dataService:any ProductionDataServiceProtocol){
            _VM = StateObject(wrappedValue: UserRouteOverViewModel(dataService : dataService))
        }
    @StateObject private var VM : UserRouteOverViewModel

    @State var selectedDate:Date = Date()
    @State var isLoading:Bool = true
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                
                timeChanger
  
                    ScrollView(showsIndicators: false){
                        ForEach(VM.activeRoutes){ activeRoute in
                            //                UserRouteCardView(tech: tech, activeRoute: ActiveRoute(id: "", name: "", date: Date(), serviceStopsIds: [], startTime: Date(), techId: "", durationSeconds: 420, distanceMiles: 69))
                            //                    .padding()
                            UserRouteCardView2(activeRoute: activeRoute)
                                .padding(.horizontal,16)
                        }
                    }
                if isLoading {
                    ProgressView()
                    Spacer()
                }
            }
        }

        .toolbar{
                    NavigationLink(value: Route.routes(dataService:dataService), label: {
                    Text("Build")
                })

        }
        .toolbar{
            if VM.activeRoutes.count != 0 {
                
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.allTechRouteOverview(route: VM.activeRoutes,dataService:dataService), label: {
                        
                        Text(UIDevice.isIPhone ? "Detail" : "See All")
                            .foregroundColor(Color.basicFontText)
                            .padding(5)
                            .background(Color.accentColor)
                            .cornerRadius(5)
                    })
                    
                } else {
                    Button(action: {
                        
                        masterDataManager.selectedActiveRoute = nil
                        masterDataManager.selectedActiveRouteList = VM.activeRoutes
                        
                    }, label: {
                        Text(UIDevice.isIPhone ? "Detail" : "See All")
                            .foregroundColor(Color.basicFontText)
                            .padding(5)
                            .background(Color.accentColor)
                            .cornerRadius(5)
                    })
                }
            }
        }
        .task{
            if let company = masterDataManager.selectedCompany {
                isLoading = true
                do {
                    try await VM.initalLoad(companyId: company.id,  date: selectedDate)
                } catch {
                    print("Error in UserRouteOverView: initialLoad >> ")
                    print(error)
                }
                isLoading = false
            }
        }
        .onChange(of: selectedDate, perform: { date in
            Task{
                if let company = masterDataManager.selectedCompany {
                    isLoading = true
                    do {
                        try await VM.initalLoad(companyId: company.id,  date: selectedDate)
                    } catch {
                        print("Error in UserRouteOverView: initialLoad >> ")
                        print(error)
                    }
                    isLoading = false
                }
            }
        })
    }
}

extension UserRouteOverView {
    var timeChanger: some View {
        HStack{
            Button(action: {
                let calendar = Calendar.current
                selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate)!
                print("Subtracted 1 Day")
                
            }, label: {
                Image(systemName: "chevron.left.square.fill")
                    .font(.title)
            })
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            DatePicker(selection: $selectedDate, displayedComponents: .date) {
                Text("Selected Date")
            }
            Button(action: {
                let calendar = Calendar.current
                selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate)!
                print("Added 1 Day")
                
            }, label: {
                Image(systemName: "chevron.right.square.fill")
                    .font(.title)
            })
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
        }
        
    }
}
