//
//  ReadingsAndDosagesList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/23/24.
//

import SwiftUI

struct ReadingsAndDosagesList: View {
    @StateObject var settingsVM = SettingsViewModel()
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService

    var body: some View {
        ScrollView{
            readingTemplateList
            Divider()
            dosageTemplateList
        }
        .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))

        .task {
            if let company = masterDataManager.selectedCompany {
                do {
                    try await settingsVM.getDosageTemplates(companyId: company.id)
                    try await settingsVM.getReadingTemplates(companyId: company.id)
                    print("Sucessfully got Readings and Dosages")
                } catch {
                    print("Error")
                }
            } else {
                print("No Company Selected")
            }
        }
    }
}

struct ReadingsAndDosagesList_Previews: PreviewProvider {
    static var previews: some View {
        ReadingsAndDosagesList()
    }
}
extension ReadingsAndDosagesList {
    var readingTemplateList: some View {
        VStack{
            Text("Reading List")
                .font(.headline)
            ForEach(settingsVM.readingTemplates) { template in
                if UIDevice.isIPhone {
                    
                    NavigationLink(value: Route.readingTemplate(tempalte: template, dataService: dataService), label: {
                        ReadingTemplateCardView(template: template)

                    })
                } else {
                    Button(action: {
                        masterDataManager.selectedDosageTemplate = nil
                        
                        masterDataManager.selectedReadingsTemplate = template
                        
                    
                           }, label: {
                        ReadingTemplateCardView(template: template)
                    })
                }
            }
        }
    }
    
    var dosageTemplateList: some View {
        VStack{
            Text("Dosage List")
                .font(.headline)
            ForEach(settingsVM.dosageTemplates) { template in
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.dosageTemplate(template: template, dataService: dataService), label: {
                        DosageTemplateCardView(template: template)
                    })
                    } else {
                        Button(action: {
                            masterDataManager.selectedReadingsTemplate = nil
                            masterDataManager.selectedDosageTemplate = template
                        }, label: {
                            DosageTemplateCardView(template: template)
                        })
                    }
            }
        }
    }
}
