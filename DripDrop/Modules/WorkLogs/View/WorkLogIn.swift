    //
    //  WorkLogIn.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 12/11/24.
    //

import SwiftUI
import SwiftUI
import MapKit

@MainActor
final class WorkLogInViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var activeCompanyWorkLogs : [WorkLog] = []    
    @Published var activeCompanyShift : [WorkShift] = []

    @Published var isLoading : Bool = true
    //Current Shift
    @Published var workLogSheet : [WorkLog] = []
    @Published var currentLog : WorkLog? = nil
    @Published var currentShiftId : String? = nil
    @Published var duration : Int = 0
    @Published var totalShiftDuration : Int = 0
    
    @Published var showDetails : Bool = false
    
    //Previous Shift
    //Mock Data
    @Published var previousShift : WorkShift = WorkShift(
        date: Date(),
        techId: UUID().uuidString,
        techName: "John Doe",
        isCurrent: false,
        estimatedTime: 100,
        estimatedMiles: 15
    )
    //Next Shift
    //Mock Data
    @Published var nextShift : WorkShift = WorkShift(
        date: Date(),
        techId: UUID().uuidString,
        techName: "John Doe",
        isCurrent: false,
        estimatedTime: 1000,
        estimatedMiles: 30
    )
    func onLoad(company:Company,user:DBUser){
        Task{
            do {
                self.isLoading = true
                //Get Active Shift
                var currentShifts = try await dataService.getCurrentShift(companyId:company.id, userId:user.id)
                //Get active Work Log
//                var logs = try await dataService.getActiveWorkLogsByUser(companyId: company.id, userId: user.id)
                
                currentShifts = currentShifts.sorted(by: {$0.date > $1.date})
                if let firstLog = currentShifts.first {
                    print("Found Shift")
                    print(firstLog)
                    self.activeCompanyShift.append(firstLog)
                } else {
                    print("No Shift Found")
                }
                
                
                if let firstShift = self.activeCompanyShift.first {
                    self.currentShiftId = firstShift.id
                    print(firstShift.id)
                    var workLogSheets = try await dataService.getWorkLogByShift(companyId: company.id, shiftId: firstShift.id, userId: user.id)
                    workLogSheets = workLogSheets.sorted(by: {$0.startTime > $1.startTime})
                    print("Go work Logs \(workLogSheets.count)")
                    self.workLogSheet = workLogSheets
                    if let firstLog = workLogSheets.first(where: {$0.current == true}) {
                        
                        self.currentLog = firstLog
                        self.duration = timeBetweenAsSeconds(start: firstLog.startTime, end: Date())
                        self.totalShiftDuration = duration
                        
                        for sheet in workLogSheet {
                            if let end = sheet.endTime {
                                if sheet.type != .onBreak {
                                    self.totalShiftDuration = totalShiftDuration + timeBetweenAsSeconds(start: sheet.startTime, end: end)
                                }
                            }
                        }
                    } else {
                        print("No First Log")
                    }
                } else {
                    print("No First Shift")
                }
                
                //Get Previous Shift
                
                self.isLoading = false
                
            } catch {
                print(error)
            }
        }
    }
    
    func updateCurrentShift(company:Company,user:DBUser,newType:WorkLogType?) {
        Task{
            do {
                
                self.currentLog?.endTime = Date()
                self.currentLog?.endLatitude = 0
                self.currentLog?.endLongitude = 0
                self.currentLog?.current = false
                
                
                if let log = self.currentLog {
                        //Update workLog
                    try await dataService.updateWorkLogEndTime(companyId: company.id, workLogId: log.id, endTime: Date())
                    try await dataService.updateWorkLogEndLatAndLong(companyId: company.id, workLogId: log.id, lat: 0, long: 0)
                    try await dataService.updateWorkLogActive(companyId: company.id, workLogId: log.id, current: log.current)
                    self.workLogSheet.append(log)
                    if let newType {

                    }
                }
                if let newType , let currentShiftId {
                    
                    let name = user.firstName + " " + user.lastName
                    self.duration = 0
                    
                    let workLog = WorkLog(
                        id: UUID().uuidString,
                        shiftId: currentShiftId,
                        startTime: Date(),
                        startLatitude: 0,
                        startLongitude: 0,
                        type: newType,
                        companyId: company.id,
                        companyName: company.name,
                        userId: user.id,
                        userName: name,
                        current: true
                    )
                        //Create New work log
                    
                    try await dataService.uploadWorkLog(companyId: company.id, workLog: workLog)
                    self.currentLog = workLog
                } else {
                    print("Just Log Out")
                    self.currentLog = nil
                }
            } catch {
                print(error)
            }
        }
    }
    func clockOut(company:Company,user:DBUser,newType:WorkLogType?) {
        Task{
            do {
                
                self.currentLog?.endTime = Date()
                self.currentLog?.endLatitude = 0
                self.currentLog?.endLongitude = 0
                self.currentLog?.current = false
                
                
                if let log = self.currentLog {
                        //Update workLog
                    try await dataService.updateWorkLogEndTime(companyId: company.id, workLogId: log.id, endTime: Date())
                    try await dataService.updateWorkLogEndLatAndLong(companyId: company.id, workLogId: log.id, lat: 0, long: 0)
                    try await dataService.updateWorkLogActive(companyId: company.id, workLogId: log.id, current: log.current)
                    self.workLogSheet.append(log)
                    if let newType, let currentShiftId {
                        try await dataService.updateWorkShiftActive(companyId: company.id, workShiftId: currentShiftId, current: log.current)
                    }
                }
                if let newType , let currentShiftId {
                    
                    let name = user.firstName + " " + user.lastName
                    self.duration = 0
                    
                    let workLog = WorkLog(
                        id: UUID().uuidString,
                        shiftId: currentShiftId,
                        startTime: Date(),
                        startLatitude: 0,
                        startLongitude: 0,
                        type: newType,
                        companyId: company.id,
                        companyName: company.name,
                        userId: user.id,
                        userName: name,
                        current: true
                    )
                        //Create New work log
                    
                    try await dataService.uploadWorkLog(companyId: company.id, workLog: workLog)
                    self.currentLog = workLog
                } else {
                    print("Just Log Out")
                    self.currentLog = nil
                }
            } catch {
                print(error)
            }
        }
    }

    func clockIn(company:Company,user:DBUser) {
        Task{
            do {
                let name = user.firstName + " " + user.lastName
                self.duration = 0
                
                let shiftId = "comp_ws_" + UUID().uuidString
                self.currentShiftId = shiftId
                let shift = WorkShift(
                    id: shiftId,
                    date: Date(),
                    techId: user.id,
                    techName: name,
                    isCurrent: true,
                    estimatedTime: 0,
                    estimatedMiles: 0
                )
                let workLog = WorkLog(
                    id: UUID().uuidString,
                    shiftId: shiftId,
                    startTime: Date(),
                    startLatitude: 0,
                    startLongitude: 0,
                    type: .working,
                    companyId: company.id,
                    companyName: company.name,
                    userId: user.id,
                    userName: name,
                    current: true
                )
                print("Clock In")
                print("shift")
                print(shift)
                print("workLog")
                print(workLog)
                try await dataService.uploadWorkShift(companyId: company.id, workShift: shift)
                try await dataService.uploadWorkLog(companyId: company.id, workLog: workLog)
                self.currentLog = workLog
            } catch {
                print(error)
            }
        }
    }
    
}
struct WorkLogIn: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : WorkLogInViewModel
    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: WorkLogInViewModel(dataService: dataService))
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                VStack{
                    form
                    if VM.showDetails {
                        ScrollView{
                            list
                        }
                    }
                }
                .padding(8)
                .disabled(VM.isLoading)
                .opacity(VM.isLoading ? 0.75 : 1)
            }
            if VM.isLoading {
                ProgressView()
            }
        }
        .task{
            if let user = masterDataManager.user, let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(company : currentCompany, user: user)
            }
        }
        .onReceive(timer) { time in
            if !VM.isLoading {
                VM.duration += 1
                VM.totalShiftDuration += 1
            }
        }
    }
}
    //
    //#Preview {
    //    WorkLogIn()
    //}

extension WorkLogIn {
    var form: some View {
        VStack{
            if let currentLog = VM.currentLog {
                HStack{
                    Text(currentLog.companyName)
                    Spacer()
                }
                HStack{
                    switch currentLog.type {
                    case .working:
                        Text(currentLog.type.rawValue)
                            .modifier(SubmitButtonModifier())
                    case .onBreak:
                        Text(currentLog.type.rawValue)
                            .modifier(YellowButtonModifier())
                    case .onLunch:
                        Text(currentLog.type.rawValue)
                            .modifier(YellowButtonModifier())
                    }
                    Spacer()
                }
                .lineLimit(1)
                HStack{
                    Text("Start : \(time(date: currentLog.startTime))")
                    if let endTime = currentLog.endTime {
                        Text("End : \(time(date: endTime)) (\(displayNumberAsMinAndHourAndSecond(seconds: timeBetweenAsSeconds(start: currentLog.startTime, end: endTime))))")
                    } else {
                        Text("(\(displayNumberAsMinAndHourAndSecond(seconds: VM.duration)))")
                    }
                    Spacer()
                }
                .lineLimit(1)
                switch currentLog.type {
                case .working:
                    Button(action: {
                        if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                            VM.updateCurrentShift(company: currentCompany, user: user, newType: .onBreak)
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Go On Break")
                            Spacer()
                        }
                        .modifier(AddButtonModifier())
                    })
                    Button(action: {
                        if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                            VM.updateCurrentShift(company: currentCompany, user: user, newType: .onLunch)
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Go On Lunch")
                            Spacer()
                        }
                        .modifier(AddButtonModifier())
                    })
                    Button(action: {
                        if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                            VM.clockOut(company: currentCompany, user: user, newType: nil)
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Clock Out")
                            Spacer()
                        }
                        .modifier(DismissButtonModifier())
                    })
                    
                case .onBreak, .onLunch:
                    Button(action: {
                        if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                            VM.updateCurrentShift(company: currentCompany, user: user, newType: .working)
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Back To Work")
                            Spacer()
                        }
                        .modifier(SubmitButtonModifier())
                    })
                }
                HStack{
                    Text("Total : (\(displayNumberAsMinAndHourAndSecond(seconds: VM.totalShiftDuration)))")
                    Spacer()
                    Button(action: {
                        VM.showDetails.toggle()
                    }, label: {
                        if VM.showDetails {
                            Text("Collapse")
                                .modifier(DismissButtonModifier())
                        } else {
                            Text("Expand")
                                .modifier(AddButtonModifier())
                        }
                    })
                }
            } else {
                if let company = masterDataManager.currentCompany {
                    HStack{
                        Text(company.name)
                        Spacer()
                    }
                    Button(action: {
                        if let user = masterDataManager.user {
                            VM.clockIn(company: company, user: user)
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Clock in")
                            Spacer()
                        }
                        .modifier(SubmitButtonModifier())
                    })
                }
            }
        }
        .modifier(ListButtonModifier())
        
    }
    var list: some View {
        VStack{
            ForEach(VM.workLogSheet){ log in
                WorkLogCardView(workLog: log)
            }
        }
    }
}
