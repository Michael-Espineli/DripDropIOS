//
//  UserCalendarEventView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct UserCalendarEventView: View {
    @StateObject var routeVM = ActiveRouteViewModel()

    @State var user:DBUser
    @State var company:Company

    @State var tech:DBUser
    @State var date:Date

    var body: some View {
        VStack(alignment: .leading,spacing: 0){
            ZStack{
                ForEach(routeVM.serviceStopList) { event in
                    let eventStartTime:Date = event.serviceDate ?? Date()
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
