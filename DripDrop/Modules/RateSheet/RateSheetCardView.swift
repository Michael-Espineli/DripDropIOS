//
//  RateSheetCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/18/24.
//

import SwiftUI

struct RateSheetCardView: View {
    let rateSheets:[RateSheet]
    let jobTemplate:JobTemplate
    @State var showSheet:Bool = false
    @State var editSheet:Bool = false

    var body: some View {
        HStack{
            Text("\(jobTemplate.name)")
            Spacer()
            if let sheet = rateSheets.first(where: {$0.templateId == jobTemplate.id}) {
                Text(" -  \(sheet.rate/100, format: .currency(code: "USC").precision(.fractionLength(2)))")
                    .sheet(isPresented: $editSheet, content: {
                        EditRateSheet(template: jobTemplate, rateSheet: sheet)
                    })
                if UIDevice.isIPhone {
                    Button(action: {
                        editSheet.toggle()
                    }, label: {
                        Image(systemName: "gobackward")
                            .modifier(EditButtonModifier())
                    })
                } else {
                    Button(action: {
                        editSheet.toggle()
                    }, label: {
                        Text("Edit")
                            .modifier(EditButtonModifier())
                    })
                }
            } else {
                Button(action: {
                    showSheet = true
                }, label: {
                    Text("Offer New Rate")
                })
                .sheet(isPresented: $showSheet, content: {
                        AddNewRateSheet(template: jobTemplate)
                    .presentationDetents([.medium])
                    
                })
            }
        }
        .task{
            print("Rate Sheets \(rateSheets)")
            print("Job Templates \(jobTemplate)")
        }
    }
}

struct RateSheetCardView_Previews: PreviewProvider {
    static var previews: some View {
        RateSheetCardView(rateSheets: [], jobTemplate: JobTemplate(id: "", name: ""))
    }
}
