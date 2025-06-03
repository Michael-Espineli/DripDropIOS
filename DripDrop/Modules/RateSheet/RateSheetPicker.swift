//
//  RateSheetPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/8/24.
//


import SwiftUI

struct RateSheetPicker: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject var companyUserVM = CompanyUserViewModel()
    @Binding var rateSheet:RateSheet
    @State var template:JobTemplate = JobTemplate(id: "", name: "")
    @State var rateStr:String = "0"
    @State var startDate:Date = Date()
    @State var showTemplatePicker:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                details
                form
            }
            .padding(8)
        }
        .onChange(of: rateStr, perform: { datum in
            if datum != "" {
                if let rate = Double(rateStr){
                    rateSheet.rate = rate
                } else {
                    rateStr = "0"
                }
            }
        })
    }
}

//struct RateSheetPicker_Previews: PreviewProvider {
//    static var previews: some View {
//        RateSheetPicker(template: JobTemplate(id: "", name: "", type: "", typeImage: "", dateCreated: Date(), rate: "", color: ""))
//    }
//}

extension RateSheetPicker {
    var details: some View {
        VStack{
            Button(action: {
                showTemplatePicker.toggle()
            }, label: {
                if template.id == "" {
                    Text("Select Template")
                        .modifier(AddButtonModifier())
                } else {
                    Text("\(template.name)")
                        .modifier(AddButtonModifier())
                }
            })
            .sheet(isPresented: $showTemplatePicker, onDismiss: {
                print("On Dismiss")
                rateSheet.templateId = template.id
                rateSheet.templateName = template.name
            }, content: {
                JobTemplatePicker(dataService: dataService, jobTemplate: $template)
            })
        }
    }
    var form: some View {
        VStack{
            HStack{
                HStack{
                    
                    TextField(
                        "Rate",
                        text: $rateStr
                    )
                    .keyboardType(.decimalPad)
                    Button(action: {
                        rateStr = "0"
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
                .modifier(TextFieldModifier())
                .padding(.vertical,8)
                .padding(.trailing,8)
                    Picker("Labor Type", selection: $rateSheet.laborType, content: {
                        Text("Hour").tag(RateSheetLaborType.hour)
                        Text("Job").tag(RateSheetLaborType.job)
                    })
                    .pickerStyle(.segmented)
                
            }
            HStack{
                Text("Offered Start Date:")
                DatePicker(selection: $startDate, displayedComponents: .date) {
                    
                }
            }
        }
    }
    
}
