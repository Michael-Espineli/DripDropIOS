//
//  UserCalendarEventView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct UserCalendarEventView: View {
    @StateObject var routeVM : ActiveRouteViewModel
    init(dataService: any ProductionDataServiceProtocol,user:DBUser,company:Company,tech:DBUser,date:Date){
        _routeVM = StateObject(wrappedValue: ActiveRouteViewModel(dataService: dataService))
        _user = State(initialValue: user)
        _company = State(initialValue: company)
        _tech = State(initialValue: tech)
        _date = State(initialValue: date)

    }
    @State var user:DBUser
    @State var company:Company
    @State var tech:DBUser
    @State var date:Date

    var body: some View {
        VStack(alignment: .leading,spacing: 0){
            ZStack{
                ForEach(routeVM.serviceStopList) { event in
                    let eventStartTime:Date = event.serviceDate
                    let xoffset:CGFloat = checkForOtherEventsDuringThisTime(events: routeVM.serviceStopList, event:event)
                    let yoffset:CGFloat = 15 +  CGFloat(Int(eventStartTime.timeIntervalSince(eventStartTime.startOfDay()) / 3600)*60) + CGFloat(event.duration/2)
                    CalendarEvents(event: event, events: routeVM.serviceStopList , eventColor: Color[tech.color ?? "red"])
                        .offset(x: xoffset, y: yoffset)
                }
            }
            .padding(0)
            Spacer()
        }
        .task{
            try? await routeVM.checkForActiveRouteOnDateForUser(companyId: company.id, date: date, tech: tech)
        }
    }
}
