//
//  ShiftDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/27/25.
//

//
//  ShiftCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import SwiftUI

@MainActor
final class ShiftDetailViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var workLogs:[WorkLog] = []
    @Published private(set) var activeRoute: ActiveRoute? = nil

    @Published private(set) var timeMin: Int? = nil
    @Published private(set) var milage: Int? = nil

    func onLoad(companyId:String, user:DBUser, workShift:WorkShift) async throws {
        self.timeMin = workShift.estimatedTime
        self.workLogs = try await dataService.getWorkLogByShift(companyId: companyId, shiftId: workShift.id, userId: user.id)
        var updatedMin = 0
        
        for log in workLogs {
            if log.type == .working {
                if let endTime = log.endTime {
                    let duration = minBetween(start: log.startTime, end: endTime)
                    print("Duration: \(duration) min")
                    updatedMin = updatedMin + duration
                }
            }
        }
        print("Duration: \(updatedMin/60) Hour")

        self.timeMin = updatedMin
        let dayOfWeek = weekDay(date: workShift.date)
        self.activeRoute = try? await dataService.getAllActiveRoutesBasedOnDate(companyId: companyId, date: workShift.date, tech: user).first
        if let activeRoute, let endMilage = activeRoute.endMilage, let startMilage = activeRoute.startMilage {
            let duration = endMilage - startMilage
            self.milage = duration
        }
    }
}
struct ShiftDetailView: View {
    @Environment(\.locale) private var locale
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject var VM : ShiftCardViewModel

    init(dataService: any ProductionDataServiceProtocol,workShift: WorkShift){
        _VM = StateObject(wrappedValue: ShiftCardViewModel(dataService: dataService))
        _workShift = State(wrappedValue: workShift)
    }
    
    @State var workShift: WorkShift
    var body: some View {
        ZStack{
            VStack{
                VStack{
                    HStack{
                        Text(shortDate(date: workShift.date))
                        Spacer()
                    }
                    HStack{
                        if let timeMin = VM.timeMin {
                            Text(displayMinAsMinAndHour(min: timeMin))
                        }
                        Spacer()
                        if let milage = VM.milage {
                            Text(Measurement(value: Double(milage), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))
                        }
                    }
                }
                .modifier(ListButtonModifier())
                .padding(8)
                ForEach(VM.workLogs){ log in
                    WorkLogCardView(workLog: log)
                }
            }
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user{
                do {
                    try await VM.onLoad(companyId: currentCompany.id,user: user, workShift: workShift)
                } catch {
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    ShiftCardView()
//}

