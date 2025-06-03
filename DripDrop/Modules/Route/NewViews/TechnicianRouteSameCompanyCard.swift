//
//  TechnicianRouteSameCompanyCard.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//
import SwiftUI

struct TechnicianRouteSameCompanyCard: View {
    //No Data Service No Logic Please. Just View
    let technicianName : String
    let isContractedOut : Bool
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
            if companyName != ""{
                if isContractedOut {
                    Divider()
                    HStack{
                        Spacer()
                        Text("Contracted with")
                            .font(.footnote)
                        Text(companyName)
                            .font(.footnote)
                            .modifier(CustomerCardModifier())
                    }
                } else {
                    Divider()
                    HStack{
                        Spacer()
                        Text("Contracted by")
                            .font(.footnote)
                        Text(companyName)
                            .font(.footnote)
                            .modifier(GreenCardModifier())
                    }
                }
            }
        }
        .padding(5)
    }
}
