//
//  JobTemplatePicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/8/24.
//

import SwiftUI

struct JobTemplatePicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var VM : JobTemplateViewModel
    @Binding var jobTemplate : JobTemplate
    
    init(dataService:any ProductionDataServiceProtocol,jobTemplate:Binding<JobTemplate>){
        _VM = StateObject(wrappedValue: JobTemplateViewModel(dataService: dataService))
        
        self._jobTemplate = jobTemplate
    }
    
    @State var search:String = ""
    @State var customers:[Customer] = []
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                HStack{
                    Spacer()
                    Button(action: {
                        dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                    })
                    .padding(16)
                }
                jobTemplateList
            }
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.getJobTemplates(companyId: company.id)
                }
            } catch {
                print("Error")
                
            }
        }
 
    }
}
extension JobTemplatePicker {
  
    var jobTemplateList: some View {
        ScrollView{
            ForEach(VM.jobTemplates){ datum in
                
                Button(action: {
                    jobTemplate = datum
                    dismiss()
                }, label: {
                    HStack{
                        Spacer()
                    
                        Text("\(datum.name)")
                     
                        Spacer()
                    }
                    .modifier(ListButtonModifier())
                    .padding(.horizontal,8)
                })
                
                Divider()
            }
        }
    }
}
