//
//  JobTemplateSettingsView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI

struct JobTemplateSettingsView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var JobTemplateVM = SettingsViewModel()
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                VStack{
                    ForEach(JobTemplateVM.jobTemplates){ job in
                        NavigationLink(destination: {
                            JobTemplateDetailView(template: job)
                        }, label: {
                            JobTemplateCardView(template: job)
                        })
                    }
                }
                .padding(.horizontal,10)
            }
        }
        .task {
            if let company = masterDataManager.selectedCompany {
                do {
                    try await JobTemplateVM.getWorkOrderTemplates(companyId: company.id)
                } catch {
                    print(error)
                }
            }
        }
    }
}
