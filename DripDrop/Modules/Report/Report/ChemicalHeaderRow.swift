//
//  ChemicalHeaderRow.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/22/24.
//

import SwiftUI

struct ChemicalHeaderRow: View {
    let readingTemplates:[ReadingsTemplate]
    let dosageTemplates:[DosageTemplate]

    var body: some View {
        titleRow
    }
}
extension ChemicalHeaderRow {
    var titleRow: some View {
        HStack{
            Text("00-00-0000")
                .foregroundColor(Color.clear)
                .overlay(Text("Date"))
            dosages
            Text("S0000000")
                .foregroundColor(Color.clear)
                .overlay(Text("Stop Id"))
            Spacer()
        }
    }
    var readings: some View {
        HStack{
            ForEach(readingTemplates){ template in
                Text("\(template.name)")
                    .frame(minWidth: 35)
            }
        }
    }
    var dosages: some View {
        HStack{
            ForEach(dosageTemplates){ template in
                Text("\(template.name ?? "")")
                    .frame(minWidth: 35)
            }
        }
    }
}
