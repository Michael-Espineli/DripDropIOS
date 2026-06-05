//
//  LaborContractTermsDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/7/24.
//

import SwiftUI

struct TermsTemplateDetailView: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,termsTemplateId:String){
        _termsTemplateId = State(wrappedValue: termsTemplateId)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var VM : TermsTemplateListViewModel

    //Variables
    @State var termsTemplateId:String
    @State var showEditTermsTemplate:Bool = false
    private var termsTemplate: TermsTemplate? {
        VM.termsTemplateList.first { $0.id == termsTemplateId }
    }
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
                    try await VM.getContractTermsForTermsTemplate(companyId: selectedCompany.id, termsTemplateId: termsTemplateId)
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
            if let termsTemplate {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(termsTemplate.name)")
                        .fontWeight(.bold)
                    if !termsTemplate.description.isEmpty {
                        Text(termsTemplate.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
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
