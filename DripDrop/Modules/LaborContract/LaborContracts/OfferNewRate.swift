//
//  OfferNewRate.swift
//  DripDrop
//
//  Created by Michael Espineli on 8/30/24.
//

import SwiftUI

struct OfferNewRate: View {
    init(dataService:any ProductionDataServiceProtocol,isPresented:Binding<Bool>,laborContract:RepeatingLaborContract,recurringWork:LaborContractRecurringWork){
        _VM = StateObject(wrappedValue: LaborContractViewModel(dataService: dataService))
        
        self._isPresented = isPresented
        _laborContract = State(wrappedValue: laborContract)
        _recurringWork = State(wrappedValue: recurringWork)
    }
    @StateObject var VM : LaborContractViewModel
    
    @Binding var isPresented : Bool
    @State var laborContract : RepeatingLaborContract
    @State var recurringWork : LaborContractRecurringWork
    var body: some View {
        VStack{
            HStack{
                Spacer()
                Button(action: {
                    isPresented = false
                }, label: {
                    Text("Dismiss")
                        .modifier(DismissButtonModifier())
                })
            }
            Rectangle()
                .frame(height: 1)
            Text("Current Rate: \(recurringWork.rate, format: .currency(code: "USD").precision(.fractionLength(2)))")
            HStack{
                Text("Offer New Rate")
                TextField(
                    "Rate",
                    text: $VM.offerNewRate
                )
                .keyboardType(.decimalPad)
                .modifier(TextFieldModifier())
            }
            Button(action: {
                Task{
                    do {
                        try await VM.offerNewRate(
                            laborContract: laborContract,
                            recurringWork: recurringWork
                        )
                        
                        isPresented = false
                        
                    } catch {
                        print(error)
                    }
                }
            },
                   label: {
                Text("Offer New Rate")
                    .modifier(AddButtonModifier())
            })
        }
    }
}

//#Preview {
//    OfferNewRate(isPresented: )
//}
