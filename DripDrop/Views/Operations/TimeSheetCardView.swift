//
//  TimeSheetCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/14/24.
//

struct TimeSheet: Identifiable{
    let id:String
    var name:WorkTimeType
    var clockIn:Date
    var clockOut:Date?
}
import SwiftUI

struct TimeSheetCardView: View {
    let sheet : TimeSheet
    var body: some View {
        VStack{
            HStack{
                Text("\(sheet.name.rawValue)")
                    .font(.footnote)
                Spacer()
                switch sheet.name {
                case .workTime:
                    Image(systemName: "circlebadge.fill")
                        .foregroundColor(Color.poolGreen)
                case .breakTime:
                    Image(systemName: "circlebadge.fill")
                        .foregroundColor(Color.poolYellow)

                case .lunchTime:
                    Image(systemName: "circlebadge.fill")
                        .foregroundColor(Color.poolBlue)

                }
            }
            HStack{
                Text("\(time(date:sheet.clockIn))")
                if let clockOut = sheet.clockOut {
                    Text(" - \(time(date:clockOut))")
                    Spacer()
                    Text("\(displayNumberAsMinAndHourAndSecond(seconds:timeBetweenAsSeconds(start: sheet.clockIn, end: clockOut)))")
                } else {
                    Spacer()
                    Text("\(displayNumberAsMinAndHourAndSecond(seconds: 0))")
                }
            }
            .padding(.horizontal,16)
        }
    }
}

#Preview {
    TimeSheetCardView(sheet: TimeSheet(id: "", name: .workTime, clockIn: Date(), clockOut: Date()))
}
