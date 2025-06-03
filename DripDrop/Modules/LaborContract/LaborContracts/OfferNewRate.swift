//
//  OfferNewRate.swift
//  DripDrop
//
//  Created by Michael Espineli on 8/30/24.
//

import SwiftUI

struct OfferNewRate: View {
    init(dataService:any ProductionDataServiceProtocol,isPresented:Binding<Bool>,laborContract:ReccuringLaborContract,recurringWork:LaborContractRecurringWork){
        _VM = StateObject(wrappedValue: RecurringLaborContractViewModel(dataService: dataService))
        
        self._isPresented = isPresented
        _laborContract = State(wrappedValue: laborContract)
        _recurringWork = State(wrappedValue: recurringWork)
    }
    @StateObject var VM : RecurringLaborContractViewModel
    
    @Binding var isPresented : Bool
    @State var laborContract : ReccuringLaborContract
    @State var recurringWork : LaborContractRecurringWork
    var body: some View {
        VStack{
            HStack{
                Spacer()
                Button(action: {
                    isPresented = false
                }, label: {
                    Image(systemName: "xmark")
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
