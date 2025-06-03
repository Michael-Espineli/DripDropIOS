//
//  TechnicianRouteSummaryCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/17/25.
//

import SwiftUI

struct TechnicianRouteSummaryCardView: View {
    //No Data Service No Logic Please. Just View
    let technicianName : String
    let roleName : String
    let isOtherCompany : Bool
    let companyName : String
    @Binding var showDialogConfirmation : Bool
    var body: some View {
        VStack{
            HStack{
                Text(technicianName)
                Spacer()
                
                Button(action: {
                    showDialogConfirmation.toggle()
                    
                }, label: {
                    Image(systemName: "line.3.horizontal")
                        .padding(4)
                })
            }
            if isOtherCompany {
                Divider()
                HStack{
                    Text(roleName)
                    Spacer()
                    Text(companyName)
                }
            }
        }
        .padding(5)
    }
}

//#Preview {
//    TechnicianRouteSummaryCardView(technicianName: "")
//}
