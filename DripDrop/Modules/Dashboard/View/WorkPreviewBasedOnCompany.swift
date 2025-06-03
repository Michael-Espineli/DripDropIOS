    //
    //  WorkPreviewBasedOnCompany.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 5/13/24.
    //

import SwiftUI

struct WorkPreviewBasedOnCompany: View {
    @Environment(\.locale) var locale
    
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @StateObject private var VM : AllViewModel
    
    init(dataService:any ProductionDataServiceProtocol,company:Company){
        _VM = StateObject(wrappedValue: AllViewModel(dataService: dataService))
        _company = State(wrappedValue: company)
    }
    
    @State var company:Company
    @State var showShift:Bool = false

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                Rectangle()
                    .frame(height: 1)
                info
                login
                route
            }
        }
        .task {
            if let user = masterDataManager.user {
                do {
                    try await VM.loadCompanyWorkPreview(companyId: company.id, user: user)
                } catch {
                    print("Error - [WorkPreviewBasedOnCompany]")
                    print(error)
                }
            }
        }
    }
}

#Preview {
    WorkPreviewBasedOnCompany(dataService: MockDataService(), company: MockDataService.mockCompany)
}

extension WorkPreviewBasedOnCompany {
    var info: some View{
        VStack{
            HStack{
                if let role = VM.role {
                    Text("Role Permissions: \(role.name)")
                        .bold()
                        .font(.footnote)
                }
                Spacer()
            }
        }
    }
    var login: some View {
        VStack{
            if let companyUser = VM.companyUser {
                switch companyUser.workerType {
                case .contractor:
                    HStack{
                        Text(companyUser.workerType.rawValue)
                        Spacer()
                    }
                case .employee:
                    HStack{
                        Text(companyUser.workerType.rawValue)
                        Spacer()
                        Button(action: {
                            showShift.toggle()
                        }, label: {
                            Text("Login")
                                .modifier(AddButtonModifier())
                        })
                        .sheet(isPresented: $showShift, onDismiss: {
                            
                        }, content: {
                            WorkLogIn(dataService: dataService)
                                .presentationDetents([.fraction(0.2),.fraction(0.6)])
                        })
                    }
                case .notAssigned:
                    HStack{
                        Text(companyUser.workerType.rawValue)
                        Spacer()
                    }
                }
            }
        }
    }
    var route: some View {
        VStack{
            if VM.activeRoute != nil {
                if let companyUser = VM.companyUser {
                    switch companyUser.workerType {
                    case .contractor:
                        if UIDevice.isIPhone {
                            NavigationLink(value: Route.mainDailyDisplayView(dataService:dataService), label: {
                                routePreview
                            })
                        } else {
                            Button(action: {
                                masterDataManager.selectedCategory = .dailyDisplay
                            }, label: {
                                routePreview
                            })
                        }
                    case .employee:
                        if UIDevice.isIPhone {
                            NavigationLink(value: Route.employeeMainDailyDisplayView(dataService:dataService), label: {
                                routePreview
                            })
                        } else {
                            Button(action: {
                                masterDataManager.selectedCategory = .dailyDisplay
                            }, label: {
                                routePreview
                            })
                        }
                    case .notAssigned:
                        if UIDevice.isIPhone {
                            NavigationLink(value: Route.mainDailyDisplayView(dataService:dataService), label: {
                                routePreview
                            })
                            .disabled(true)
                        } else {
                            Button(action: {
                                masterDataManager.selectedCategory = .dailyDisplay
                            }, label: {
                                routePreview
                            })
                        }
                    }
                }
               
            } else {
                if let companyUser = VM.companyUser {
                    switch companyUser.workerType {
                    case .contractor:
                        if UIDevice.isIPhone {
                            NavigationLink(value: Route.mainDailyDisplayView(dataService:dataService), label: {
                                Text("No Work Today")
                                    .modifier(ListButtonModifier())
                            })
                            Text("Next Shift")
                        } else {
                            Button(action: {
                                masterDataManager.selectedCategory = .dailyDisplay
                            }, label: {
                                Text("No Work Today")
                                    .modifier(ListButtonModifier())
                            })
                            Text("Next Shift")
                        }
                    case .employee:
                        if UIDevice.isIPhone {
                            NavigationLink(value: Route.employeeMainDailyDisplayView(dataService:dataService), label: {
                                Text("No Work Today")
                                    .modifier(ListButtonModifier())
                            })
                            Text("Next Shift")
                        } else {
                            Button(action: {
                                masterDataManager.selectedCategory = .dailyDisplay
                            }, label: {
                                Text("No Work Today")
                                    .modifier(ListButtonModifier())
                            })
                            Text("Next Shift")
                        }
                    case .notAssigned:
                        if UIDevice.isIPhone {
                            NavigationLink(value: Route.mainDailyDisplayView(dataService:dataService), label: {
                                Text("No Work Today")
                                    .modifier(ListButtonModifier())
                            })
                            Text("Next Shift")
                        } else {
                            Button(action: {
                                masterDataManager.selectedCategory = .dailyDisplay
                            }, label: {
                                Text("No Work Today")
                                    .modifier(ListButtonModifier())
                            })
                            Text("Next Shift")
                        }
                    }
                }
               
            }
        }
    }
    var routePreview: some View {
        HStack{
            ZStack{
                
                Circle()
                    .fill(.poolWhite)
                    .frame(width: 85, height: 85)
                Circle()
                    .trim(from: 0, to: Double(VM.finishedStops ?? 0) / Double(VM.totalStops ?? 1))
                    .stroke(Color.poolGreen, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                Text("\(String( VM.finishedStops ?? 0)) / \(String( VM.totalStops ?? 0))")
                    .foregroundColor(Color.black)
                    .font(.headline)
                    .bold(true)
            }
            .foregroundColor(Color.basicFontText)

            Spacer()
            if let activeRoute = VM.activeRoute {
                VStack(alignment: .leading){
                    HStack(spacing: 0){
                        if let startMilage = activeRoute.startMilage {
                            Text("\(Measurement(value: Double(startMilage), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))")
                                .foregroundColor(Color.white)
                        }
                        if let endMilage = activeRoute.endMilage {
                            Text("- \(Measurement(value: Double(endMilage), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))")
                                .foregroundColor(Color.white)
                        }
                        if let startMilage = activeRoute.startMilage, let endMilage = activeRoute.endMilage {
                            Text(" (\(Measurement(value: Double(endMilage)-Double(startMilage), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))))")
                                .foregroundColor(Color.white)
                        }
                    }
                    .padding(.vertical,16)
                    HStack(spacing: 0){
                        HStack{
                            if let startTime = activeRoute.startTime {
                                Text("Time: ")
                                    .foregroundColor(Color.white)
                                Text("\(time(date:startTime))")
                                    .foregroundColor(Color.white)
                            }
                            if let endTime = activeRoute.endTime {
                                Text("- \(time(date:endTime))")
                                    .foregroundColor(Color.white)
                            }
                        }
                        if let startTime = activeRoute.startTime, let endTime = activeRoute.endTime {
                            Text(" (\(displayMinAsMinAndHour(min: minBetween(start: startTime, end: endTime))))")
                                .foregroundColor(Color.white)
                        }
                    }
                }
                .font(.footnote)
            }
        }
        .modifier(ListButtonModifier())
        .modifier(OutLineButtonModifier())

    }
}
