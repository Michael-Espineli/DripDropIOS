//
//  EditLaborContractTerms.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/7/24.
//

import SwiftUI

struct EditTermsTemplate: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,termsTemplate:TermsTemplate){
        _VM = StateObject(wrappedValue: LaborContractViewModel(dataService: dataService))
        _termsTemplate = State(wrappedValue: termsTemplate)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject var VM : LaborContractViewModel

    //Variables
    @State var termsTemplate:TermsTemplate    
    var body: some View {
        Text("Developer Add Edit \(termsTemplate.name)")
    }
}
//
//#Preview {
//    EditTermsTemplate(laborContractTerms: )
//}
