//
//  JobTemplateSettingsView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI

struct JobTemplateSettingsView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    init(dataService:any  ProductionDataServiceProtocol) {
        
    }
    @StateObject var JobTemplateVM = SettingsViewModel(dataService: ProductionDataService())
    @State var showCreateNewJobTemplate:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                VStack{
                    ForEach(JobTemplateVM.jobTemplates){ job in
                        if UIDevice.isIPhone {
                            NavigationLink(destination: {
                                JobTemplateDetailView(template: job)
                            }, label: {
                                JobTemplateCardView(template: job)
                            })
                        } else {
                            Button(action: {
                                masterDataManager.selectedJobTemplate = job
                            }, label: {
                                JobTemplateCardView(template: job)
                            })
                        }
                        Divider()
                    }
                }
                .padding(.horizontal,10)
                .sheet(isPresented: $showCreateNewJobTemplate, content: {
                    CreateNewJobTemplate()
                })
            }
        }
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await JobTemplateVM.getWorkOrderTemplates(companyId: company.id)
                } catch {
                    print(error)
                }
            }
        }
        .toolbar{
            ToolbarItem(content: {
                Button(action: {
                    showCreateNewJobTemplate.toggle()
                }, label: {
                    Text("Create")
                })
            })
        }
    }
}
