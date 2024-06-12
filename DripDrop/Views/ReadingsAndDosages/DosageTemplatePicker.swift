//
//  DosageTemplatePicker.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/18/24.
//

import SwiftUI

struct DosageTemplatePicker: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var template:DosageTemplate
    @StateObject var settingsVM = SettingsViewModel()
    @EnvironmentObject var masterDataManager: MasterDataManager
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                list
                search
            }
        }
        .task {
            if let company = masterDataManager.selectedCompany {
                do {
                    try await settingsVM.getDosageTemplates(companyId: company.id)
                } catch {
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    DosageTemplatePicker()
//}
extension DosageTemplatePicker {
    var list: some View {
        
        ScrollView{
            ForEach(settingsVM.dosageTemplates){ dosageTemplate in
                Button(action: {
                    template = dosageTemplate
                    dismiss()
                }, label: {
                    HStack{
                        Text("\(dosageTemplate.name ?? "")")
                    }
                    .frame(maxWidth: .infinity)
                })
                Divider()
            }
        }
    }
    var search: some View {
        HStack{
            
        }
    }
}
