//
//  TermsTemplatePicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/7/24.
//


import SwiftUI

struct TermsTemplatePicker: View {
    //Init
    init(dataService:ProductionDataService,selectedTemplate:Binding<TermsTemplate>,termsList:Binding<[ContractTerms]>){
        _VM = StateObject(wrappedValue: LaborContractViewModel(dataService: dataService))
        self._selectedTemplate = selectedTemplate
        self._termsList = termsList
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : LaborContractViewModel

    //Variables
    @Binding var selectedTemplate:TermsTemplate
    @Binding var termsList:[ContractTerms]

    @State var detailTemplates:TermsTemplate? = nil
    @State var addNewTemplate:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                list
            }
            .padding(8)
            Text("")
                .sheet(isPresented: $addNewTemplate, onDismiss: {
                    print("On Dismiss")
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
                }, content: {
                    AddNewTermsTemplate(dataService: dataService)
                })
        }
        .task {
                if let selectedCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.getTermsTemplates(companyId: selectedCompany.id)
                    } catch {
                        print("Error")
                        print(error)
                    }
                }
            
        }
        .onChange(of: selectedTemplate, perform: { template in
            if template.id == "" {
                termsList = []
            } else {
                Task{
                    
                    if let selectedCompany = masterDataManager.currentCompany {
                        do {
                            try await VM.getContractTermsForTermsTemplate(companyId: selectedCompany.id, termsTemplateId: template.id)
                            termsList = VM.contractTermList
                            
                        } catch {
                            print("Error")
                            print(error)
                        }
                    }
                }
            }
        })
    }
}

//#Preview {
//    TermsTemplateList()
//}
extension TermsTemplatePicker {
    var list: some View {
        VStack{
            Button(action: {
                addNewTemplate.toggle()
            }, label: {
                Text("Add New")
                    .modifier(AddButtonModifier())
            })
            ForEach(VM.termsTemplateList){ template in
                HStack{
                    Button(action: {
                        if selectedTemplate == template {
                            selectedTemplate = TermsTemplate(id: "", name: "")
                            
                        } else {
                            selectedTemplate = template
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            Text("\(template.name)")
                            Spacer()
                            if selectedTemplate == template {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.poolGreen)
                            }
                        }
                    })
                    .modifier(ListButtonModifier())
                    Button(action: {
                        detailTemplates = template
                    }, label: {
                        Text("See Details")
                            .foregroundColor(Color.red)
                    })
                }
            }
        }
        .sheet(item: $detailTemplates, onDismiss: {
            print("On Dismiss")
        }, content: { template in
            TermsTemplateDetailView(dataService: dataService, termsTemplate: template)
        })
    }
}
