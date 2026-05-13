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
    @EnvironmentObject var mobileDailyVM: MobileDailyRouteDisplayViewModel

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
//                login
                startRoute
                route
            }
            Text("")
            .sheet(isPresented: $mobileDailyVM.showMilage, onDismiss: {
                mobileDailyVM.updateRouteStartMilage(companyId: masterDataManager.currentCompany?.id)
            }, content: {
                startMilageView
                    .presentationDetents([.fraction(0.5), .fraction(0.6)])
            })
            Text("")
            .sheet(isPresented: $mobileDailyVM.showEndMilage, onDismiss: {
                mobileDailyVM.updateRouteEndtMilage(companyId: masterDataManager.currentCompany?.id)
            }, content: {
                endMilageView
                    .presentationDetents([.fraction(0.5), .fraction(0.6)])
            })
        }
        .task {
            if let user = masterDataManager.user {
                do {
                    try await VM.loadCompanyWorkPreview(companyId: company.id, user: user)
                } catch {
                    print("[WorkPreviewBasedOnCompany][task]Error - \(error)")
                }
            }
        }
        .onAppear(perform: {
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                print("")
                print("[WorkPreviewBasedOnCompany][onAppear] Calling start")
                mobileDailyVM.start(companyId: company.id, user: user, date: Date())
             }
        })
        .onDisappear(perform: {
            mobileDailyVM.stop()
        })
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
                            Text("Clock In")
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
            if mobileDailyVM.activeRoute != nil {
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
                        } else {
                            Button(action: {
                                masterDataManager.selectedCategory = .dailyDisplay
                            }, label: {
                                Text("No Work Today")
                                    .modifier(ListButtonModifier())
                            })
                        }
                    case .employee:
                        if UIDevice.isIPhone {
                            NavigationLink(value: Route.employeeMainDailyDisplayView(dataService:dataService), label: {
                                Text("No Work Today")
                                    .modifier(ListButtonModifier())
                            })
                        } else {
                            Button(action: {
                                masterDataManager.selectedCategory = .dailyDisplay
                            }, label: {
                                Text("No Work Today")
                                    .modifier(ListButtonModifier())
                            })
                        }
                    case .notAssigned:
                        if UIDevice.isIPhone {
                            NavigationLink(value: Route.mainDailyDisplayView(dataService:dataService), label: {
                                Text("No Work Today")
                                    .modifier(ListButtonModifier())
                            })
                        } else {
                            Button(action: {
                                masterDataManager.selectedCategory = .dailyDisplay
                            }, label: {
                                Text("No Work Today")
                                    .modifier(ListButtonModifier())
                            })
                        }
                    }
                }
               
            }
        }
    }
//    New Version
    /*
    var startRoute: some View {
        VStack{
            if let activeRoute = mobileDailyVM.activeRoute {
                VStack{
                    HStack{
                        Spacer()
                        Text(activeRoute.status.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(getColor(status: VM.activeRoute?.status.rawValue ?? ""))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    switch activeRoute.status {
                    case .inProgress, .traveling:
                        HStack{
                            Button(action: {
                                mobileDailyVM.stopActiveRoute(companyId: masterDataManager.currentCompany?.id, companyName: masterDataManager.currentCompany?.name, user: masterDataManager.user)
                            }, label: {
                                Text("Stop Route")
                                    .modifier(DeleteButtonModifier())
                            })
                            Spacer()
                            Button(action: {
                                mobileDailyVM.pauseActiveRoute(companyId: masterDataManager.currentCompany?.id, companyName: masterDataManager.currentCompany?.name, user: masterDataManager.user)
                            }, label: {
                                Text("Pause Route")
                                    .modifier(OrangeButtonModifier())
                            })
                        }
                    case .didNotStart:
                        HStack{
                            Button(action: {
                                mobileDailyVM.startActiveRoute(companyId: masterDataManager.currentCompany?.id, companyName: masterDataManager.currentCompany?.name, user:masterDataManager.user)
                            }, label: {
                                Text("Start Route")
                                    .modifier(BlueButtonModifier())
                            })
                            Spacer()
                        }
                    case .onBreak:
                        
                        HStack{
                            Button(action: {
                                mobileDailyVM.resumeActiveRoute(companyId: masterDataManager.currentCompany?.id)
                            }, label: {
                                Text("Resume Route")
                                    .modifier(BlueButtonModifier())
                            })
                            Spacer()
                        }
                    case .finished:
                        HStack{
                            Text("Route Finished")
                            Spacer()
                            Button(action: {
                                mobileDailyVM.resumeActiveRoute(companyId: masterDataManager.currentCompany?.id)
                            }, label: {
                                Text("Resume Route")
                                    .modifier(BlueButtonModifier())
                            })
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .modifier(ListButtonModifier())
            }
        }
    }
    var routePreview: some View {
        HStack(spacing: 16) {
            // MARK: - Progress Ring
            if let activeRoute = mobileDailyVM.activeRoute {
                
                ZStack {
                    Circle()
                        .fill(Color.poolWhite.opacity(0.15))
                        .frame(width: 72, height: 72)
                    
                    Circle()
                        .trim(
                            from: 0,
                            to: Double(activeRoute.finishedStops)
                            / Double(max(activeRoute.totalStops, 1))
                        )
                        .stroke(
                            Color.poolGreen,
                            style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 64, height: 64)
                    
                    VStack(spacing: 2) {
                        Text("\(activeRoute.finishedStops)")
                            .font(.headline)
                            .bold()
                        Text("of \(activeRoute.totalStops)")
                            .font(.caption2)
                            .opacity(0.7)
                    }
                    .foregroundColor(.white)
                }
            }
            // MARK: - Route Metrics
            if let activeRoute = mobileDailyVM.activeRoute {
                VStack(alignment: .leading, spacing: 8) {

                    // Mileage
                    if let startMilage = activeRoute.startMilage {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mileage")
                                .font(.caption2)
                                .opacity(0.6)

                            HStack(spacing: 4) {
                                Text(
                                    Measurement(
                                        value: Double(startMilage),
                                        unit: UnitLength.miles
                                    )
                                    .formatted(
                                        .measurement(
                                            width: .abbreviated,
                                            usage: .road
                                        )
                                        .locale(locale)
                                    )
                                )
                                if let endMilage = activeRoute.endMilage {
                                    Text("→")
                                        .opacity(0.5)
                                    Text(
                                        Measurement(
                                            value: Double(endMilage),
                                            unit: UnitLength.miles
                                        )
                                        .formatted(
                                            .measurement(
                                                width: .abbreviated,
                                                usage: .road
                                            )
                                            .locale(locale)
                                        )
                                    )
                                }
                            }
                            if let start = activeRoute.startMilage,
                               let end = activeRoute.endMilage {
                                Text(
                                    Measurement(
                                        value: Double(end - start),
                                        unit: UnitLength.miles
                                    )
                                    .formatted(
                                        .measurement(
                                            width: .abbreviated,
                                            usage: .road
                                        )
                                        .locale(locale)
                                    )
                                )
                                .font(.caption2)
                                .opacity(0.7)
                            }
                        }
                    }
                    // Time
                    if let startTime = activeRoute.startTime {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time")
                                .font(.caption2)
                                .opacity(0.6)
                            HStack(spacing: 4) {
                                Text(time(date: startTime))
                                if let endTime = activeRoute.endTime {
                                    Text("→")
                                        .opacity(0.5)
                                    Text(time(date: endTime))
                                }
                            }
                            if let endTime = activeRoute.endTime {
                                Text(
                                    displayMinAsMinAndHour(
                                        min: minBetween(
                                            start: startTime,
                                            end: endTime
                                        )
                                    )
                                )
                                .font(.caption2)
                                .opacity(0.7)
                            }
                        }
                    }
                }
                .foregroundColor(.white)
                .font(.footnote)
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .modifier(ListButtonModifier())
    }
    */
    //Newest Version
    var startRoute: some View {
        VStack {
            if let activeRoute = mobileDailyVM.activeRoute {
                
                VStack(spacing: 16) {
                    
                    // MARK: - Status Badge
                    HStack {
                        Spacer()
                        Text(activeRoute.status.rawValue)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(getColor(status: activeRoute.status.rawValue))
                            )
                            .foregroundColor(.white)
                    }
                    
                    // MARK: - Action Buttons
                    switch activeRoute.status {
                        
                    case .inProgress, .traveling:
                        HStack(spacing: 12) {
                            
                            Button {
                                mobileDailyVM.stopActiveRoute(
                                    companyId: masterDataManager.currentCompany?.id,
                                    companyName: masterDataManager.currentCompany?.name,
                                    user: masterDataManager.user
                                )
                            } label: {
                                Text("Stop Route")
                                    .frame(maxWidth: .infinity)
                                    .modifier(DeleteButtonModifier())
                            }
                            
                            Button {
                                mobileDailyVM.pauseActiveRoute(
                                    companyId: masterDataManager.currentCompany?.id,
                                    companyName: masterDataManager.currentCompany?.name,
                                    user: masterDataManager.user
                                )
                            } label: {
                                Text("Pause Route")
                                    .frame(maxWidth: .infinity)
                                    .modifier(OrangeButtonModifier())
                            }
                        }
                        
                    case .didNotStart:
                        Button {
                            mobileDailyVM.startActiveRoute(
                                companyId: masterDataManager.currentCompany?.id,
                                companyName: masterDataManager.currentCompany?.name,
                                user: masterDataManager.user
                            )
                        } label: {
                            Text("Start Route")
                                .frame(maxWidth: .infinity)
                                .modifier(BlueButtonModifier())
                        }
                        
                    case .onBreak:
                        Button {
                            mobileDailyVM.resumeActiveRoute(
                                companyId: masterDataManager.currentCompany?.id
                            )
                        } label: {
                            Text("Resume Route")
                                .frame(maxWidth: .infinity)
                                .modifier(BlueButtonModifier())
                        }
                        
                    case .finished:
                        VStack(spacing: 8) {
                            Text("Route Finished")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            Button {
                                mobileDailyVM.resumeActiveRoute(
                                    companyId: masterDataManager.currentCompany?.id
                                )
                            } label: {
                                Text("Resume Route")
                                    .frame(maxWidth: .infinity)
                                    .modifier(BlueButtonModifier())
                            }
                        }
                    }
                }
                .padding(20)
                .modifier(ListButtonModifier())
            }
        }
    }
    
    var routePreview: some View {
        HStack(spacing: 20) {
            
            if let activeRoute = mobileDailyVM.activeRoute {
                
                // MARK: - Progress Ring
                ZStack {
                    
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                        .frame(width: 72, height: 72)
                    
                    Circle()
                        .trim(
                            from: 0,
                            to: Double(activeRoute.finishedStops) /
                                Double(max(activeRoute.totalStops, 1))
                        )
                        .stroke(
                            Color.poolGreen,
                            style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 72, height: 72)
                    
                    VStack(spacing: 2) {
                        Text("\(activeRoute.finishedStops)")
                            .font(.headline.weight(.bold))
                        
                        Text("of \(activeRoute.totalStops)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Route Metrics
                VStack(alignment: .leading, spacing: 14) {
                    
                    // Mileage
                    if let startMilage = activeRoute.startMilage {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mileage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 6) {
                                Text(
                                    Measurement(
                                        value: Double(startMilage),
                                        unit: UnitLength.miles
                                    )
                                    .formatted(
                                        .measurement(
                                            width: .abbreviated,
                                            usage: .road
                                        )
                                        .locale(locale)
                                    )
                                )
                                
                                if let endMilage = activeRoute.endMilage {
                                    Text("→")
                                        .foregroundColor(.secondary)
                                    
                                    Text(
                                        Measurement(
                                            value: Double(endMilage),
                                            unit: UnitLength.miles
                                        )
                                        .formatted(
                                            .measurement(
                                                width: .abbreviated,
                                                usage: .road
                                            )
                                            .locale(locale)
                                        )
                                    )
                                }
                            }
                            
                            if let end = activeRoute.endMilage {
                                let diff = end - startMilage
                                Text(
                                    Measurement(
                                        value: Double(diff),
                                        unit: UnitLength.miles
                                    )
                                    .formatted(
                                        .measurement(
                                            width: .abbreviated,
                                            usage: .road
                                        )
                                        .locale(locale)
                                    )
                                )
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Time
                    if let startTime = activeRoute.startTime {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 6) {
                                Text(time(date: startTime))
                                
                                if let endTime = activeRoute.endTime {
                                    Text("→")
                                        .foregroundColor(.secondary)
                                    Text(time(date: endTime))
                                }
                            }
                            
                            if let endTime = activeRoute.endTime {
                                Text(
                                    displayMinAsMinAndHour(
                                        min: minBetween(
                                            start: startTime,
                                            end: endTime
                                        )
                                    )
                                )
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(20)
        .modifier(ListButtonModifier())
    }

    func getColor(status: String) -> Color {
        switch status {
        case "In Progress": return .orange
        case "Did Not Start": return .black.opacity(0.5)
        case "Traveling": return .poolBlue
        case "Break": return .purple
        case "Finished": return .poolGreen
        default: return .gray
        }
    }
    
    var startMilageView: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Button {
                    mobileDailyVM.showVehicalPicker.toggle()
                } label: {
                    Text(
                        mobileDailyVM.selectedVehical.id.isEmpty
                        ? "Pick Vehicle"
                        : "\(mobileDailyVM.selectedVehical.nickName) \(mobileDailyVM.selectedVehical.plate)"
                    )
                }
                .sheet(isPresented: $mobileDailyVM.showVehicalPicker) {
                    VehicalPickerView(
                        dataService: dataService,
                        vehical: $mobileDailyVM.selectedVehical
                    )
                }
                if !mobileDailyVM.selectedVehical.id.isEmpty {
                    Divider()

                    HStack {
                        Text("Recent Mileage")
                        Spacer()
                        Text(
                            Measurement(value: mobileDailyVM.selectedVehical.miles, unit: UnitLength.miles)
                                .formatted(.measurement(width: .abbreviated))
                        )
                    }

                    Divider()
                    HStack{
                        Text("Start Milage:")
                        MilesField(text: $mobileDailyVM.inputStartMilage)
                    }
                    
//                    HStack{
//                        Text("End Milage:")
//                        MilesField(text: $mobileDailyVM.endMilage)
//                    }
                }
            }
            .padding()
            Spacer()
        }
    }
    var endMilageView: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                if !mobileDailyVM.selectedVehical.id.isEmpty {
                    Divider()
                    HStack {
                        Text("Recent Start")
                        Spacer()
                        Text(
                            Measurement(value: mobileDailyVM.startMilage, unit: UnitLength.miles)
                                .formatted(.measurement(width: .abbreviated))
                        )
                    }
                    HStack{
                        Text("End Milage:")
                        MilesField(text: $mobileDailyVM.inputEndMilage)
                    }
                }
            }
            .padding()
            Spacer()
        }
    }

}
