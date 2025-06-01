//
//  WorkLogCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/27/25.
//

import SwiftUI

struct WorkLogCardView: View {
    let workLog : WorkLog
    var body: some View {
        VStack{
            HStack{
                Spacer()
                Text(sheet.type.rawValue)
                Spacer()
            }
            HStack{
                Text("Start : \(time(date: sheet.startTime))")
                Spacer()
            }
            .font(.footnote)
            HStack{
                if let endTime = sheet.endTime {
                    Text("End : \(time(date: endTime)) (\(displayNumberAsMinAndHourAndSecond(seconds: timeBetweenAsSeconds(start: sheet.startTime, end: endTime))))")
                } else {
                    Text("(\(displayNumberAsMinAndHourAndSecond(seconds: timeBetweenAsSeconds(start: sheet.startTime, end: sheet.endTime ?? Date()))))")
                }
                Spacer()
            }
            .font(.footnote)
        }
        .modifier(ListButtonModifier())
    }
}

#Preview {
    WorkLogCardView()
}
