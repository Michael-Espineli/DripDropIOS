//
//  WeekDaysView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//
import SwiftUI

struct WeekDaysView: View {
    let startDate: Date
    @Binding var selected: Date

    var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Set Sunday as the first day of the week
        return calendar
    }
    var body: some View {
        VStack{
            HStack {
                ForEach(0..<7) { index in
                    let date = self.calendar.date(byAdding: .day, value: index, to: self.startDate)!
                    let dayOfWeekString = self.calendar.veryShortWeekdaySymbols[(self.calendar.component(.weekday, from: date) - 1) % 7]
                    Button(action: {
                        selected = date
                    }, label: {
                        VStack{
                            Text("\(dayOfWeekString)")
                        }
                    })
#if os(iOS)
                    .frame(width: (UIScreen.main.bounds.width-50) / 7)
                    #endif
                                       .foregroundColor(Color.blue)
                }
            }
            HStack {
                ForEach(0..<7) { index in
                    let date = self.calendar.date(byAdding: .day, value: index, to: self.startDate)!
                    let dayOfWeekString = self.calendar.veryShortWeekdaySymbols[(self.calendar.component(.weekday, from: date) - 1) % 7]
                    Button(action: {
                        selected = date
                    }, label: {
                        if isDate(date, inDayContaining: Date()) {
                            VStack{
                                Text("\(self.calendar.component(.day, from: date))")
                            }
                            .padding(4)
                            .bold(true)
                            .foregroundColor(isDate(date, inDayContaining: selected) ? .white:.blue)
                            .background(isDate(date, inDayContaining: selected) ? .blue:.clear)
                            .cornerRadius(20)
                        } else {
                            VStack{
                                Text("\(self.calendar.component(.day, from: date))")
                            }
                            .padding(4)
                            .bold(true)
                            .foregroundColor(isDate(date, inDayContaining: selected) ? .white:.gray)
                            .background(isDate(date, inDayContaining: selected) ? .blue:.clear)
                            .cornerRadius(20)
                        }
                    })
#if os(iOS)
                    .frame(width: (UIScreen.main.bounds.width-50) / 7)
                    #endif
                                       .foregroundColor(Color.blue)
                }
            }
        }
        .gesture(DragGesture(minimumDistance: 50, coordinateSpace: .local)
                            .onEnded({ value in
                                if value.translation.width < 0 && value.translation.height > -30 && value.translation.height < 30 {
                                    print("left swipe")
                                    selected = selected.addingTimeInterval(60*60*24*7)
                                }
                                else if value.translation.width > 0 && value.translation.height > -30 && value.translation.height < 30 {
                                    print("right swipe")
                                    selected = selected.addingTimeInterval(-60*60*24*7)

                                } else {
                                    print("none")
                                }
                            }))
    }
}

struct WeekDaysView_Previews: PreviewProvider {
    static var previews: some View {
        @State var selectedDate = Date()

        WeekDaysView(startDate: startOfWeek(for: Date()), selected: $selectedDate)
    }
}
