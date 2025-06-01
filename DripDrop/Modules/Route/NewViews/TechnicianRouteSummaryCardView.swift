//
//  TechnicianRouteSummaryCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/17/25.
//

import SwiftUI

struct TechnicianRouteSummaryCardView: View {
    var body: some View {
        VStack{
            HStack{
                Text("\(VM.recurringRoute?.tech ?? "")")

            }
        }
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    TechnicianRouteSummaryCardView()
}
