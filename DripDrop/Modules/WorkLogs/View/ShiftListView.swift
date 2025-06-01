//
//  ShiftListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import SwiftUI

struct ShiftListView: View {
        //Mock Data
        @State var previousShift : WorkShift = WorkShift(
            date: Date(),
            techId: UUID().uuidString,
            techName: "John Doe",
            isCurrent: false,
            estimatedTime: 100,
            estimatedMiles: 15
        )
        //Next Shift
        //Mock Data
        @State var nextShift : WorkShift = WorkShift(
            date: Date(),
            techId: UUID().uuidString,
            techName: "John Doe",
            isCurrent: false,
            estimatedTime: 1000,
            estimatedMiles: 30
        )
    var body: some View {
        VStack{
            
            HStack{
                Text("Next Shift - ")
                Spacer()
            }
            ShiftCardView(workShift: nextShift)
            HStack{
                Text("Previous Shift - ")
                Spacer()
            }
            
            ShiftCardView(workShift: previousShift)
        }
    }
}

#Preview {
    ShiftListView()
}
