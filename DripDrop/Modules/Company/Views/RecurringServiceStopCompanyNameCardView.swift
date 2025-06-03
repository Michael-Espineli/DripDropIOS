//
//  RecurringServiceStopCompanyNameCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/20/24.
//


import SwiftUI

struct RecurringServiceStopCompanyNameCardView: View {
    init(dataService: any ProductionDataServiceProtocol,recurringServiceStopId:String){
        _VM = StateObject(wrappedValue: RecurringServiceStopCompanyNameCardViewModel(dataService: dataService))
        _recurringServiceStopId = State(wrappedValue: recurringServiceStopId)
    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : RecurringServiceStopCompanyNameCardViewModel

    @State var recurringServiceStopId:String
    var body: some View {
        ZStack{
            if let recurringServiceStop = VM.recurringServiceStop, let contractedCompanyId = recurringServiceStop.contractedCompanyId {
                if contractedCompanyId != "" {
                    CompanyNameCardView(dataService: dataService, companyId: contractedCompanyId)
                }
            }
        }
            .task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.onLoad(companyId: currentCompany.id,recurringServiceStopId: recurringServiceStopId)
                    } catch {
                        print(error)
                        print("error")
                    }
                }
            }
    }
}

