//
//  ActiveRouteCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/2/24.
//

import SwiftUI

struct ActiveRouteCardView: View {
    @Environment(\.locale) var locale

    let activeRoute: ActiveRoute
    var body: some View {

            VStack{
                HStack{
                    Text("\(shortDate(date: activeRoute.date))")
                    Spacer()
                }
                HStack{
                    if let start = activeRoute.startMilage{
                        Text("\(Measurement(value: Double(start), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))")
                    } else {
                        Text("No Start")
                    }
                    Text(" - ")
                    if let end = activeRoute.endMilage {
                        
                        Text("\(Measurement(value: Double(end), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))")
                    } else {
                        Text("No End")

                    }
                }
                HStack{
                    Spacer()
                    if let startMilage = activeRoute.startMilage, let endMilage = activeRoute.endMilage {
                        Text(" (\(Measurement(value: Double(endMilage)-Double(startMilage), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))))")

                    }
                }
                HStack{
                    Text("\(time(date: activeRoute.startTime)) - \(time(date: activeRoute.endTime))")
                }
                HStack{
                    Spacer()
                    if let startTime = activeRoute.startTime,let endTime = activeRoute.endTime {
                        Text(" (\(displayMinAsMinAndHour(min:minBetween(start: startTime, end: endTime))))")
                    }
                }

            }
        
    }
}

struct ActiveRouteCardView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveRouteCardView(activeRoute: ActiveRoute(id: "",
                                                     name: "",
                                                     date: Date(),
                                                     serviceStopsIds: [],
                                                     startTime: Date(),
                                                     endTime: Date(),
                                                     startMilage: 0,
                                                     endMilage: 0,
                                                     techId: "",
                                                     techName: "",
                                                     traineeId: "",
                                                     traineeName: "",
                                                     durationMin: 0,
                                                     distanceMiles: 0,
                                                     status: .didNotStart,
                                                     totalStops: 0,
                                                     finishedStops: 0,
                                                     vehicalId: ""))
    }
}
