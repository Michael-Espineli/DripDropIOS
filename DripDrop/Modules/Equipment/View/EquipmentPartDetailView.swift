//
//  RepairHistoryDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/10/24.
//

import SwiftUI

struct EquipmentPartDetailView: View {
    let equipmentPart:EquipmentPart
    var body: some View {
        VStack{
            Text("Name: \(equipmentPart.name)")
            Text("Date Installed: \(fullDate(date:equipmentPart.date))")
            Text("Notes: \(equipmentPart.notes)")
        }
    }
}

