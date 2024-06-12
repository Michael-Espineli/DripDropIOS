//
//  ChemicalRow.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/22/24.
//

import SwiftUI

struct ChemicalRow: View {
    var stopData:StopData
    var readingTemplates:[ReadingsTemplate]
    var dosageTemplate:[DosageTemplate]

    var body: some View {
            HStack{
                date
//                readings
                dosages
                Button(action: {
                    print("Show Detail View For Service Stop \(stopData.serviceStopId)")
                }, label: {
                    Text("S0000000")
                        .foregroundColor(Color.clear)
                        .overlay(Text("\(stopData.serviceStopId)"))
                })
 
                Spacer()
            }
        
    }
}
extension ChemicalRow {


    var date: some View {
        Text("00-00-0000")
            .foregroundColor(Color.clear)
            .overlay( Text(fullDate(date:stopData.date)))
       
    }
    var readings: some View {
        HStack{
            ForEach(readingTemplates){ reading in
                Text("\(reading.name)")
                    .frame(minWidth: 35)
                    .foregroundColor(Color.clear)
                    .overlay(
                Text("\(stopData.readings.first(where: {$0.templateId == reading.id})?.amount ?? "0")")
                )
            }
        }
    }
    var dosages: some View {
        HStack{
            ForEach(dosageTemplate){ dosage in
                Text("\(dosage.name ?? "")")
                    .frame(minWidth: 35)
                    .foregroundColor(Color.clear)
                    .overlay(
                        Text("\(stopData.dosages.first(where: {$0.templateId == dosage.id})?.amount ?? "0")")
                )
            }
        }
    }
}
