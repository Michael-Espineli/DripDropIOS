//
//  LifeCyclesView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/29/25.
//

import SwiftUI

struct LifeCyclesView: View {
    init(dataService:any ProductionDataServiceProtocol) {

    }
    var body: some View {
        VStack{
            oneTime
            Rectangle()
                .frame(height: 1)
            recurring
        }
    }
}

//#Preview {
//    LifeCyclesView()
//}
extension LifeCyclesView {
    var oneTime: some View {
        VStack{
            Text("Jobs")
                .modifier(HeaderModifier())
            Text("Draft Jobs")
                .modifier(YellowButtonModifier())
            Text("Jobs")
                .modifier(YellowButtonModifier())
            Text("Estimates")
                .modifier(YellowButtonModifier())
            HStack{
                Text("Labor Contracts")
                    .modifier(YellowButtonModifier())
                Spacer()
                Text("Service Stops")
                    .modifier(YellowButtonModifier())
            }
            Text("Finished Jobs")
                .modifier(YellowButtonModifier())
            Text("Invoices")
                .modifier(YellowButtonModifier())
            Text("Labor")
            Divider()
            
            HStack{
                Text("Accounts Payable")
                    .modifier(YellowButtonModifier())
                Spacer()
                Text("Payroll")
                    .modifier(YellowButtonModifier())
            }
        }
    }
    
    var recurring: some View {
        VStack{
            Text("Recurring Contracts")
                .modifier(HeaderModifier())
            Text("Recurring Contracts")
                .modifier(YellowButtonModifier())
            HStack{
                Text("Labor Contracts")
                    .modifier(YellowButtonModifier())
                Spacer()
                Text("RSS")
                    .modifier(YellowButtonModifier())
            }
            Text("Labor")
            Divider()
            HStack{
                Text("Accounts Payable")
                    .modifier(YellowButtonModifier())
                Spacer()
                Text("Payroll")
                    .modifier(YellowButtonModifier())
            }
        }
    }
}
