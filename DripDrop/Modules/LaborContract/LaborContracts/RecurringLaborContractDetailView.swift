//
//  RecurringLaborContractDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/16/24.
//

import SwiftUI

struct RecurringLaborContractDetailView: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,laborContract:ReccuringLaborContract){
        _VM = StateObject(wrappedValue: RecurringLaborContractViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : RecurringLaborContractViewModel

    //Form
    @State var laborContract:ReccuringLaborContract
    @State var selectedLaborContract:ReccuringLaborContract? = nil

    @State var showEditLaborContract:Bool = false
    @State var generateLaborContract:Bool = false

    @State var notes:String = ""

    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    var body: some View {
        ZStack{
            if let currentCompany = masterDataManager.currentCompany{
                if currentCompany.id == laborContract.senderId {
                    SentLaborContractDetailView(dataService: dataService, laborContract: laborContract)
                } else if currentCompany.id == laborContract.receiverId {
                    ReceivedLaborContractDetailView(dataService: dataService, laborContract: laborContract)
                } else {
                    Text("Not Your Labor Contract")
                }
            }
        }
        .fontDesign(.monospaced)

        .task{
            notes = laborContract.notes
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoadDetailView(companyId: currentCompany.id, laborContract: laborContract)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
        .onChange(of: masterDataManager.selectedRecurringLaborContract, perform: { datum in
            Task{
                if let datum {
                    print("Change In Labor Contract")
                    laborContract = datum
                    notes = laborContract.notes
                    if let currentCompany = masterDataManager.currentCompany {
                        do {
                            try await VM.onLoadDetailView(companyId: currentCompany.id, laborContract: laborContract)
                        } catch {
                            print("Error")

                            print(error)
                        }
                    }
                } else {
                    print("Optional")
                }
            }
        })
    }
}
