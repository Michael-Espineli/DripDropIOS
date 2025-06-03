//
//  WorkLogListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/11/24.
//

import SwiftUI

@MainActor
final class WorkLogListViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published var selectedShift:WorkShift? = nil
    
    @Published private(set) var weekOfShifts : [WorkShift] = []
    @Published private(set) var previousShifts : [WorkShift] = []
    @Published private(set) var nextShifts : [WorkShift] = []
    @Published private(set) var startOfWeek : Date? = nil
    @Published private(set) var endOfWeek : Date? = nil
    @Published private(set) var currentDate : Date? = nil

    @Published private(set) var totalMiles : Int? = nil
    @Published private(set) var totalMin : Int? = nil
    @Published private(set) var totalShifts : Int? = nil

    func onLoad(companyId:String, user:DBUser) async throws {
        self.nextShifts = try await dataService.getNextShiftByUserId(companyId: companyId, userId: user.id, count: 1)
        self.nextShifts.append(WorkShift(
            date: Calendar.current.date(byAdding: DateComponents(month: 0, day: 1), to: Date())!,
            techId: UUID().uuidString,
            techName: "John Doe",
            isCurrent: false,
            estimatedTime: 100,
            estimatedMiles: 15
        ))
        self.currentDate = Date()
        self.startOfWeek = Date().startOfWeek()
        self.endOfWeek = Date().endOfWeek()
        try await getSummary(companyId: companyId, user: user, startDate: startOfWeek, endDate: endOfWeek)
        
        // Get summary
    }
    
    func nextWeek(companyId:String, user:DBUser) async throws {
        if let currentDate {
            let newDate = Calendar.current.date(byAdding: DateComponents(month: 0, day: 7), to: currentDate)!
            
            try await getSummary(companyId: companyId, user: user, startDate: newDate.startOfWeek(), endDate: newDate.endOfWeek())

            self.startOfWeek = newDate.startOfWeek()
            self.endOfWeek = newDate.endOfWeek()
            self.currentDate = newDate
        }
    }
    
    func previousWeek(companyId:String, user:DBUser) async throws {
        if let currentDate {
            let newDate = Calendar.current.date(byAdding: DateComponents(month: 0, day: -7), to: currentDate)!
            
            try await getSummary(companyId: companyId, user: user, startDate: newDate.startOfWeek(), endDate: newDate.endOfWeek())

            self.startOfWeek = newDate.startOfWeek()
            self.endOfWeek = newDate.endOfWeek()
            self.currentDate = newDate
        }
    }
    
    func getSummary(companyId:String, user:DBUser, startDate:Date?, endDate:Date?) async throws {
        if let startDate, let endDate {
            var totalMiles = 0
            var totalMin = 0
            
            let weekOfShifts = try await dataService.getShiftByUserIdBetweenDates(companyId: companyId, userId: user.id, start: startDate, end: endDate)
            self.weekOfShifts = weekOfShifts
            self.totalShifts = weekOfShifts.count
            for shift in weekOfShifts {
                let workLogs = try await dataService.getWorkLogByShift(companyId: companyId, shiftId: shift.id, userId: user.id)
                
                for log in workLogs {
                    if log.type == .working {
                        if let endTime = log.endTime {
                            let duration = minBetween(start: log.startTime, end: endTime)
                            print("Duration: \(duration) min")
                            totalMin = totalMin + duration
                        }
                    }
                }
                print("Duration: \(totalMin/60) Hour")
                let dayOfWeek = weekDay(date: shift.date)
                let activeRoute = try? await dataService.getAllActiveRoutesBasedOnDate(companyId: companyId, date: shift.date, tech: user).first
                if let activeRoute, let endMilage = activeRoute.endMilage, let startMilage = activeRoute.startMilage {
                    let duration = endMilage - startMilage
                    totalMiles = totalMiles + duration
                }
            }
            self.totalMiles = totalMiles
            self.totalMin = totalMin
        }
    }
}

struct WorkLogListView: View {
    @Environment(\.locale) private var locale
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject var VM : WorkLogListViewModel

    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: WorkLogListViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                summary
                Rectangle()
                    .frame(height: 1)
                    HStack{
                        Text("Next Shifts")
                            .font(.headline)
                        Spacer()
                    }
                    .sheet(item: $VM.selectedShift, onDismiss: {
                        
                    }, content: { shift in
                        ShiftDetailView(dataService: dataService, workShift: shift)
                    })
                    ForEach(VM.nextShifts) { shift in
                        Button(action: {
                            print("Detail View ")
                            VM.selectedShift = shift
                        }, label: {
                            ShiftCardView(dataService: dataService, workShift: shift)
                        })
                    }
                    Rectangle()
                        .frame(height: 1)
                    
                    HStack{
                        Text("Shifts")
                            .font(.headline)
                        Spacer()
                    }
                    ForEach(VM.weekOfShifts) { shift in
                        Button(action: {
                            print("Detail View ")
                            VM.selectedShift = shift
                        }, label: {
                            ShiftCardView(dataService: dataService, workShift: shift)
                        })
                    }
            }
            .padding(8)
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, user: user)
                } catch {
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    WorkLogListView()
//}
extension WorkLogListView {
    var summary: some View {
        VStack{
            HStack{
                Button(action: {
                    Task{
                        if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                            do {
                                try await VM.previousWeek(companyId: currentCompany.id, user: user)
                            } catch {
                                print(error)
                            }
                        }
                    }
                }, label: {
                    Image(systemName: "chevron.left.square.fill")
                        .font(.title)
                })
                Text("\(shortDate(date: VM.startOfWeek))")
                Spacer()
                Button(action: {
                    Task{
                        
                        if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                            do {
                                try await VM.onLoad(companyId: currentCompany.id, user: user)
                            } catch {
                                print(error)
                            }
                        }
                    }
                }, label: {
                    Text("Today")
                        .modifier(BlueButtonModifier())
                })
                Spacer()
                Text("\(shortDate(date: VM.endOfWeek))")
                Button(action: {
                    Task{
                        if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                            do {
                                try await VM.nextWeek(companyId: currentCompany.id, user: user)
                            } catch {
                                print(error)
                            }
                        }
                    }
                }, label: {
                    Image(systemName: "chevron.right.square.fill")
                        .font(.title)
                })
            }
            .padding(.horizontal,8)
            Text("Summary")
                .font(.headline)
            Divider()
            VStack{
                HStack{
                    Text("Total Miles")
                    Spacer()
                    if let milage = VM.totalMiles {
                        Text(Measurement(value: Double(milage), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))
                    }
                }
                
                HStack{
                    Text("Total Min")
                    Spacer()
                    if let totalMin = VM.totalMin {
                        Text(displayMinAsMinAndHour(min: totalMin))
                    }
                }
                
                HStack{
                    Text("Total Shifts")
                    Spacer()
                    if let totalShifts = VM.totalShifts {
                        Text(String(totalShifts))
                    }
                }
            }
        }
    }
}
