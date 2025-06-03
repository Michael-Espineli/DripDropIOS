//
//  CalendarEvent.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct CalendarEvents: View {
    var event:ServiceStop
    var events:[ServiceStop]
    var eventColor:Color
    var body: some View {
        
        VStack(alignment: .leading,spacing: 0){
            VStack(alignment: .leading,spacing: 0){
                Divider()
#if os(iOS)

                Button(action: {
                    print(event.customerName)
                }, label: {
                    VStack{
                        Text(event.customerName)
                        Text(time(date: event.serviceDate))
                    }
                })
                .foregroundColor(Color.basicFontText)
                #endif
#if os(macOS)
                VStack{
                    Text(event.customerName)
                    Text(time(date: event.serviceDate))
                }
                Button(action: {
                    print(event.customerName)

                }, label: {
                    Text("See Info")
                })
#endif

                Spacer()
            }
            .background(eventColor.opacity(0.5))
            .cornerRadius(10)
            .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
        }
        .frame(width:checkForOtherEventsDuringThisTimeWidth(events: events, event: event),height: CGFloat(event.duration))
        .cornerRadius(10)
    }
    func checkForOtherEventsDuringThisTimeWidth(events:[ServiceStop],event:ServiceStop)->CGFloat{
        var numberOfOverlappingEvents:Int = 0
        var numberOfInsideEvents:Int = 0
        let calendar = Calendar.current

        var returnOffset:CGFloat = 1
        //check to see if event is inside of another event.
        for item in events {
            let endTime:Date = calendar.date(byAdding: .minute, value: item.duration, to: item.serviceDate) ?? Date()

            if event.serviceDate > item.serviceDate && event.serviceDate < endTime || event.serviceDate == item.serviceDate{
                numberOfOverlappingEvents = numberOfOverlappingEvents + 1
            }
        }
        //check to see if any event is inside this event
        for item in events {
            let endTime:Date = calendar.date(byAdding: .minute, value: event.duration, to: event.serviceDate) ?? Date()

            if item.serviceDate > event.serviceDate && item.serviceDate < endTime || event.serviceDate == item.serviceDate{
                numberOfInsideEvents = numberOfInsideEvents + 1
            }
        }
        if numberOfInsideEvents == 1 && numberOfOverlappingEvents == 1 {
            returnOffset = 250
            
            
        } else {
            let totalNumberOfEvents = numberOfOverlappingEvents + numberOfInsideEvents - 1
            
            print("event Name --> \(event.customerName): Number Of Events \(totalNumberOfEvents)")
            let spacing = 250/(totalNumberOfEvents)
            //developer issue
            print("Spacing --> \(spacing)")
            
            returnOffset = CGFloat(spacing)
            
        }
        
        return returnOffset
    }
}
