//
//  LaborContractTermsDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/7/24.
//

import SwiftUI

struct TermsTemplateDetailView: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,termsTemplate:TermsTemplate){
        _VM = StateObject(wrappedValue: RecurringLaborContractViewModel(dataService: dataService))
        _termsTemplate = State(wrappedValue: termsTemplate)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM : RecurringLaborContractViewModel

    //Variables
    @State var termsTemplate:TermsTemplate
    @State var showEditTermsTemplate:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                header
                details
            }
            .padding(8)
        }
        .task{
            if let selectedCompany = masterDataManager.currentCompany {
                do {
                    try await VM.getContractTermsForTermsTemplate(companyId: selectedCompany.id, termsTemplateId: termsTemplate.id)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
    }
}
//
//#Preview {
//    TermsTemplateDetailView()
//}
extension TermsTemplateDetailView {
    var header: some View {
        HStack{
            Text("\(termsTemplate.name)")
                .fontWeight(.bold)
            Spacer()
            Button(action: {
                showEditTermsTemplate.toggle()
            }, label: {
                Text("Edit")
                    .modifier(AddButtonModifier())
            })
            .sheet(isPresented: $showEditTermsTemplate, onDismiss: {
                
            }, content: {
                EditTermsTemplate(dataService: dataService, termsTemplate: termsTemplate)
            })
        }
    }
    var details: some View {
        VStack{
            ForEach(VM.contractTermList){ term in
                let index = VM.contractTermList.firstIndex(of: term)
                HStack{
                    Text("\((index ?? 0) + 1):")
                    Text(term.description)
                    Spacer()
                    Button(action: {
                    }, label: {
                        Image(systemName: "trash.fill")
                            .modifier(DismissButtonModifier())
                    })
                }
                
            }
        }
    }
}
