//
//  RecurringServiceStopSmallCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/12/24.
//

import SwiftUI

struct RecurringServiceStopSmallCardView: View {
    let recurringServiceStop : RecurringServiceStop
    var body: some View {
        HStack{
            Text("\(recurringServiceStop.id)")
            VStack{
                HStack{
                    Text("\(recurringServiceStop.tech)")
                }
                HStack{
                    Text("\(shortDate(date:recurringServiceStop.startDate))")
                    if recurringServiceStop.noEndDate {
                        Text("- No End")
                    } else {
                        Text("- \(shortDate(date: recurringServiceStop.endDate))")
                    }
                }
                HStack{
                    ForEach(recurringServiceStop.daysOfWeek, id:\.self ){ day in
                        Text(day)
                            .font(.footnote)
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    RecurringServiceStopSmallCardView(recurringServiceStop: MockDataService.mockRecurringServiceStop)
}
