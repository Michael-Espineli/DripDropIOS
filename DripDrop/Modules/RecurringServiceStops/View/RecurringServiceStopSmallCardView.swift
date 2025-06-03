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
                    Spacer()
                    Text("\(recurringServiceStop.tech)")
                    Spacer()
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
                    Text(recurringServiceStop.daysOfWeek)     
                        .font(.footnote)

                    
                    Spacer()
                }
            }
        }
        .modifier(ListButtonModifier())
    }
}

#Preview {
    RecurringServiceStopSmallCardView(recurringServiceStop: MockDataService.mockRecurringServiceStop)
}
