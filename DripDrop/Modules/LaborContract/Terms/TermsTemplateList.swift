//
//  LaborContractTermsList.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/7/24.
//

import SwiftUI
import SwiftUI

@MainActor
final class TermsTemplateListViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var termsTemplateList:[TermsTemplate] = []
    @Published private(set) var contractTermList:[ContractTerms] = []

    @Published var showNewTermsTemplate: Bool = false

    func onLoad(companyId:String){
        Task{
            do {
                dataService.listenTermsTemplate(
                    companyId: companyId,
                ) { [weak self] route in
                    self?.termsTemplateList = route
                }
            } catch {
                print("[TermsTemplateListViewModel][onLoad] Error \(error)")
            }
        }
    }
    func getContractTermsForTermsTemplate(companyId:String,termsTemplateId:String) async throws {
        self.contractTermList = try await dataService.getTermsByTermsTemplate(companyId: companyId, termsTemplateId: termsTemplateId)
    }
    func stop() {
        dataService.removeTermsTemplateListern()
    }
}
struct TermsTemplateList: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol){
    }
    
    //Objects
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var VM : TermsTemplateListViewModel


    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                list
            }
            .padding()
            if UIDevice.isIPhone {
                icons
            }
        }
        .navigationTitle("Terms Templates")
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(companyId: currentCompany.id)
            }
        }
        .onDisappear(perform: {
            VM.stop()
        })
    }
}

//#Preview {
//    TermsTemplateList()
//}
extension TermsTemplateList {
    var list: some View {
        VStack{
            ForEach(VM.termsTemplateList){ template in
                NavigationLink(value: Route.termsTemplateDetailView(dataService: dataService, termsTemplate: template), label: {
                    Text("\(template.name)")
                        .frame(maxWidth: .infinity)
                        .modifier(ListButtonModifier())
                })
            }
        }
    }
    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {
                        VM.showNewTermsTemplate.toggle()
                    }, label: {
                        Image(systemName: "plus")
                            .modifier(PlusIconModifer())
                    })
                    .sheet(isPresented: $VM.showNewTermsTemplate, onDismiss: {
                        if let currentCompany = masterDataManager.currentCompany {
                            VM.onLoad(companyId: currentCompany.id)
                        }
                    }, content: {
                        ZStack{
                            Color.listColor.ignoresSafeArea()
                            VStack{
                                AddNewTermsTemplate(dataService: dataService)
                            }
                        }
                    })
                }
                .padding(16)
            }
        }
    }
}
