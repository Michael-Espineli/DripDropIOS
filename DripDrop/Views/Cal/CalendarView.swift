//
//  CalendarView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/3/23.
//

import SwiftUI
struct Event: Identifiable {
    var id = UUID()
    var startTime: Date
    var endTime: Date
    var title: String
    var duration: Int {
         return Int(endTime.timeIntervalSince(startTime) / 60)//in minuets
     }
}

struct CalendarView: View {
    @StateObject private var techViewModel = TechViewModel()
    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State var company:Company

    @State var interval:[String] = []
    @State var increment:String = "hour" // hour , 30 min , 15 min.
    @State var dateSelected:Date = Date()
    @State private var offset = CGFloat.zero

    var body: some View {
        VStack{
            WeekDaysView(startDate: startOfWeek(for: dateSelected), selected: $dateSelected )
            ScrollView(.horizontal){
                HStack(spacing: 10){
                        Text(interval.first ?? "12:00 AM")
                            .font(.footnote)
                            .foregroundColor(Color.clear)
                    ForEach(techViewModel.techList) { tech in
                        
                        Text("Michael Espineli")
                            .padding(5)
                            .background(Color.blue)
                            .foregroundColor(Color.white)
                            .cornerRadius(5)
                            .frame(width:250)
                    }
                }
                .frame(height:30)
                .offset(x: -offset)

            }
            .disabled(true)
            ScrollView(.horizontal){
            ScrollView{
                ZStack{
                    //This is the background Lines
                    HStack{
                        VStack(spacing: 0){
                            ForEach(interval, id: \.self) { date in
                                HStack{
                                    Text(date)
                                        .font(.footnote)
                                        .foregroundColor(Color.clear)
                                    VStack{
                                        Divider()
                                            .overlay(Color.basicFontText)
                                    }
                                }
                                .frame(height:60)
                                .background(checkDuringDay(time:date,selectedTime: dateSelected) ? Color.clear:Color.gray.opacity(0.5))
                                .padding(0)
                            }
                        }
                    }
                    //put the times and events
                    HStack(spacing: 10){
                        //put the times Here
                        VStack(spacing: 0){
                            ForEach(interval, id: \.self) { date in
                                HStack{
                                    Text(date)
                                        .font(.footnote)
                                }
                                .frame(height:60)
                                .padding(0)
                            }
                        }
                        Spacer()
                        ForEach(techViewModel.techList) { tech in
                            //Put the Events Here
                            HStack{
                                UserCalendarEventView(user: user, company: company, tech: tech, date: dateSelected)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .background( GeometryReader {
                Color.clear.preference(key: ViewOffsetKey.self,
                                       value: -$0.frame(in: .named("scroll")).origin.x)
            })
            .onPreferenceChange(ViewOffsetKey.self) { value in
                print("offset >> \(value)")
                offset = value
            }
        }
   
        }
        .task{
            try? await techViewModel.getAllCompanyTechs(companyId: company.id)
        }
        .onAppear(perform: {
            interval = getScheduleInterval(increment: increment)
        })
    }
    
    func getScheduleInterval(increment:String) ->[String] {
        var incremnts:[String] = []
        var incrementMultiplier:Double = 60
        switch increment{
        case "hour":
            incrementMultiplier = 60
        case "30 min":
            incrementMultiplier = 30
        case "15 min":
            incrementMultiplier = 15
        default:
            incrementMultiplier = 60
        }
        let dayDurationInSeconds: TimeInterval = 60*incrementMultiplier
        let startDate = Date().startOfDay()
        let endDate = Date().endOfDay()
        print(startDate)
        print(endDate)
        
        for date in stride(from: startDate, to: endDate, by: dayDurationInSeconds) {
            print("Date From Get Scheduler --> \(date)")
            print("Date Converted --> \(time(date:date))")
            
            incremnts.append(time(date: date))
        }
        return incremnts
    }
    
}
struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
func checkDuringDay(time:String,selectedTime:Date)->Bool{
    var DisplayTime:Date = timeToDate(time)
    
    let displayTimeComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute,.second], from: DisplayTime)
    
    let selectedDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: selectedTime)
    
    DisplayTime = Calendar.current.date(from: DateComponents(year: selectedDate.year, month: selectedDate.month, day: selectedDate.day, hour: displayTimeComponents.hour, minute: displayTimeComponents.minute, second: displayTimeComponents.second))!
    
    print("Time Received \(time)")
    print("DisplayTime -> \(DisplayTime)")
    print("Is During Day \(DisplayTime > getSunRise() && DisplayTime < getSunSet())")
    return DisplayTime > getSunRise() && DisplayTime < getSunSet()
    
}
func timeToDate(_ time: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.date(from: time) ?? Date()
}
func getSunRise()->Date{
    //    let selectedDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
    //
    //    return Calendar.current.date(from: DateComponents(year: selectedDate.year, month: selectedDate.month, day: selectedDate.day, hour: 6, minute: selectedDate.minute, second: selectedDate.second))!
    return makeDate(year: 2023, month: 11, day: 16, hr: 6, min: 00, sec: 0)
    
}
func getSunSet()->Date{
    return makeDate(year: 2023, month: 11, day: 16, hr: 16, min: 45, sec: 0)
    
}
func checkForOtherEventsDuringThisTime(events:[ServiceStop],event:ServiceStop)->CGFloat{
    var numberOfOverlappingEvents:Int = 0
    var numberOfInsideEvents:Int = 0
    let calendar = Calendar.current

    var returnOffset:CGFloat = 1
    //check to see if event is inside of another event.
    for item in events {
        let endTime:Date = calendar.date(byAdding: .minute, value: item.duration, to: item.serviceDate!)!

        if (event.serviceDate!) > (item.serviceDate!) && (event.serviceDate!) < endTime || (event.serviceDate == item.serviceDate){
            numberOfOverlappingEvents = numberOfOverlappingEvents + 1
        }
    }
    
    //check to see if any event is inside this event
    for item in events {
        let endTime:Date = calendar.date(byAdding: .minute, value: event.duration, to: event.serviceDate!) ?? Date()

        if item.serviceDate! > event.serviceDate! && item.serviceDate! < endTime || event.serviceDate == item.serviceDate{
            numberOfInsideEvents = numberOfInsideEvents + 1
        }
    }
    if numberOfInsideEvents == 1 && numberOfOverlappingEvents == 1 {
        returnOffset = 0
        //        print("event Name --> \(event.title): Number Of Events \(numberOfOverlappingEvents + numberOfInsideEvents)")
        let totalNumberOfEvents = numberOfOverlappingEvents + numberOfInsideEvents
        let spacing = 450/totalNumberOfEvents
        //        print("Spacing --> \(spacing)")
        
    } else {
        //        print("event Name --> \(event.title): Number Of Events \(numberOfOverlappingEvents + numberOfInsideEvents)")
        let totalNumberOfEvents = numberOfOverlappingEvents + numberOfInsideEvents
        let spacing = 450/totalNumberOfEvents
        //            print("Spacing --> \(spacing)")
        returnOffset = -225 + CGFloat((spacing+numberOfOverlappingEvents) * (numberOfOverlappingEvents))
        
    }
    print("OverLapping Events for \(event.customerName) >> \(numberOfOverlappingEvents)")
    print("Inside Events for \(event.customerName) >> \(numberOfInsideEvents)")

    print("Return X OffSet for \(event.customerName) >> \(returnOffset)")
    return returnOffset
}
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSignInView:Bool = false
        CalendarView(showSignInView: $showSignInView, user: DBUser(id: "", exp: 0),company: Company(id: ""))
    }
}
