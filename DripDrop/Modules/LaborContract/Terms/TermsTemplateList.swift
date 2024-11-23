//
//  LaborContractTermsList.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/7/24.
//

import SwiftUI

struct TermsTemplateList: View {
    //Init
    init(dataService:ProductionDataService){
        _VM = StateObject(wrappedValue: LaborContractViewModel(dataService: dataService))
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject var VM : LaborContractViewModel

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                list
            }
        }
        .task {
            Task{
                if let selectedCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.getTermsTemplates(companyId: selectedCompany.id)
                    } catch {
                        print("Error")
                        print(error)
                    }
                }
            }
        }
    }
}

//#Preview {
//    TermsTemplateList()
//}
extension TermsTemplateList {
    var list: some View {
        VStack{
            ForEach(VM.termsTemplateList){ template in
                Text("\(template.name)")
            }
        }
    }
}
