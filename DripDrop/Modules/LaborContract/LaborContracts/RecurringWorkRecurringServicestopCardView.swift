//
//  RecurringWorkRecurringServicestopCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/21/24.
//

import SwiftUI

struct RecurringWorkRecurringServicestopCardView: View {
    init(dataService: any ProductionDataServiceProtocol,recurringServiceStopId:String,laborContract:ReccuringLaborContract){
        _VM = StateObject(wrappedValue: RecurringWorkRecurringServicestopCardViewModel(dataService: dataService))
        _recurringServiceStopId = State(wrappedValue: recurringServiceStopId)
        _laborContract = State(wrappedValue: laborContract)
    }
    @StateObject var VM : RecurringWorkRecurringServicestopCardViewModel
    @State var recurringServiceStopId:String
    @State var laborContract:ReccuringLaborContract
    var body: some View {
        HStack{
            if let recurringServiceStop = VM.recurringServiceStop {
                Text("\(recurringServiceStop.daysOfWeek.first!)")
                    .bold()
                Text(" - ")
                Text("\(recurringServiceStop.tech)")
            }
        }
        .task {
            do {
                try await VM.onLoad(recurringServiceStopId: recurringServiceStopId, laborContract: laborContract)
            } catch {
                print("Error")
                print(error)
            }
        }
    }
}

#Preview {
    RecurringWorkRecurringServicestopCardView(dataService: MockDataService(), recurringServiceStopId: "", laborContract: MockDataService.mockRecurringLaborContracts.first!)
}
