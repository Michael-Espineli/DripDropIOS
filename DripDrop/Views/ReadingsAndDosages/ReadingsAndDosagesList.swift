//
//  ReadingsAndDosagesList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/23/24.
//

import SwiftUI

struct ReadingsAndDosagesList: View {
    @StateObject var settingsVM = SettingsViewModel(dataService: ProductionDataService())
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService
    @State var templateType:String = "Readings"
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Picker("Customer", selection: $templateType) {
                    Text("Readings").tag("Readings")
                    Text("Dosages").tag("Dosages")
                    
                }
                .pickerStyle(.segmented)
                if templateType == "Readings" {
                    readingTemplateList
                } else if templateType == "Dosages" {
                    dosageTemplateList
                }
            }
            .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
        }
        .task {
            if let company = masterDataManager.currentCompany {
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
            ForEach(settingsVM.savedReadingTemplates) { template in
                HStack{
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
                .padding(.horizontal,8)
                .padding(.vertical,3)
                Divider()
            }
        }
    }
    
    var dosageTemplateList: some View {
        VStack{
            ForEach(settingsVM.savedDosageTemplates) { template in
                HStack{
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
                .padding(.horizontal,8)
                .padding(.vertical,3)
                Divider()
            }
        }
    }
}
