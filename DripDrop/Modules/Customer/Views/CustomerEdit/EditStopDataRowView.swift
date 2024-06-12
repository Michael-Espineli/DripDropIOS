//
//  EditStopDataRowView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/10/23.
//

import SwiftUI

struct EditStopDataRowView: View {
    @Binding var stopData:StopData
    var readingTemplates:[ReadingsTemplate]
    var dosageTemplate:[DosageTemplate]
    var bodyOfWaterId:String
    var body: some View {
        HStack{
            date
            readings
            dosages
            Spacer()
            
        }
    }
}
extension EditStopDataRowView {
    var date: some View {
        Text("00-00-0000")
            .foregroundColor(Color.clear)
            .overlay(Text(fullDate(date:stopData.date)))
        
    }
    var readings: some View {
        HStack{
            ForEach(readingTemplates){ reading in
                ReadingCell(stopData: $stopData, readingTemplate: reading, bodyOfWaterId: bodyOfWaterId)
                
            }
        }
    }
    var dosages: some View {
        HStack{
            ForEach(dosageTemplate){ dosage in
                DosageCell(stopData: $stopData, dosageTemplate: dosage,bodyOfWaterId: bodyOfWaterId)
            }
        }
    }
}
struct ReadingCell: View {
    @Binding var stopData:StopData
    var readingTemplate:ReadingsTemplate
    @State var reading:String = "0"
    var bodyOfWaterId:String

    var body: some View {
        HStack{
            Text(readingTemplate.name)
                .foregroundColor(Color.clear)
                .overlay(
                    TextField(
                        "readin",
                        text: $reading
                    )
                    .background(reading == "0" ? Color.gray.opacity(0.3):Color.red)
                )
        }
        .frame(minWidth: 35)
        .onAppear(perform:{
            reading = stopData.readings.first(where: {$0.templateId == readingTemplate.id})?.amount ?? "0"
        })
        .onChange(of: reading, perform: { read in
            if read != stopData.readings.first(where: {$0.templateId == readingTemplate.id})?.amount ?? "0" {
                if let dosage = stopData.readings.first(where: {$0.templateId == readingTemplate.id}) {
                    stopData.readings.removeAll(where: {$0.templateId == readingTemplate.id})
                    stopData.readings.append(Reading(id: UUID().uuidString,
                                                     templateId: readingTemplate.id,
                                                     dosageType: "",
                                                     name: readingTemplate.name,
                                                     amount: read,
                                                     UOM: readingTemplate.UOM,
                                                     bodyOfWaterId: bodyOfWaterId))
                } else {
                    stopData.readings.append(Reading(id: UUID().uuidString,
                                                     templateId: readingTemplate.id,
                                                     dosageType: "",
                                                     name: readingTemplate.name,
                                                     amount: read,
                                                     UOM: readingTemplate.UOM,
                                                     bodyOfWaterId: bodyOfWaterId))
                }
            }
        })
    }
}
struct DosageCell: View {

    @Binding var stopData:StopData
    var dosageTemplate:DosageTemplate
    @State var dosage:String = "0"
    var bodyOfWaterId:String

    var body: some View {
        HStack{
            Text(dosageTemplate.name ?? "")
                .foregroundColor(Color.clear)
                .overlay(
                    TextField(
                        "dosage",
                        text: $dosage
                    )
                    .background(dosage == "0" ? Color.gray.opacity(0.3):Color.red)
                )
        }
        .frame(minWidth: 35)
        .onAppear(perform:{
            dosage = stopData.dosages.first(where: {$0.templateId == dosageTemplate.id})?.amount ?? "0"
        })
        .onChange(of: dosage, perform: { dose in
            if dose != stopData.dosages.first(where: {$0.templateId == dosageTemplate.id})?.amount ?? "0" {
                if let dosage = stopData.dosages.first(where: {$0.templateId == dosageTemplate.id}) {
                    stopData.dosages.removeAll(where: {$0.templateId == dosageTemplate.id})
                    stopData.dosages.append(Dosage(id: UUID().uuidString,
                                                   templateId: dosageTemplate.id,
                                                   name: dosageTemplate.name,
                                                   amount: dose,
                                                   UOM: dosageTemplate.UOM,
                                                   rate: dosageTemplate.rate,
                                                   linkedItem: dosageTemplate.linkedItemId,
                                                   bodyOfWaterId: bodyOfWaterId))
                } else {
                    stopData.dosages.append(Dosage(id: UUID().uuidString,
                                                   templateId: dosageTemplate.id,
                                                   name: dosageTemplate.name,
                                                   amount: dose,
                                                   UOM: dosageTemplate.UOM,
                                                   rate: dosageTemplate.rate,
                                                   linkedItem: dosageTemplate.linkedItemId,
                                                   bodyOfWaterId: bodyOfWaterId))
                }
            }
        })
    }
}
