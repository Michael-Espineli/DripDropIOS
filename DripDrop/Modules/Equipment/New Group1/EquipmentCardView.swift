//
//  EquipmentCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/21/24.
//

import SwiftUI

struct EquipmentCardView: View {
    let equipment: Equipment
    var body: some View {
            VStack{
                HStack{
                    Text("\(equipment.customerName)")
                }
                HStack{
                    Text("\(equipment.make)")
                    Text("\(equipment.model)")
                    Text("\(equipment.category.rawValue)")
                }
                HStack{
                    Text("\(fullDate(date:equipment.dateInstalled))")
                    Text("\(equipment.status)")
                }
                if equipment.needsService {
                    Text("Needs Service")
                        .modifier(DismissButtonModifier())
                }
            }
            .frame(maxWidth: .infinity)
        .foregroundColor(Color.basicFontText)
    }
}

#Preview {
    EquipmentCardView(equipment: Equipment(id: "", name: "", category: .filter, make: "", model: "", dateInstalled: Date(), status: .operational, needsService: false, notes: "",customerName: "", customerId: "", serviceLocationId: "", bodyOfWaterId: "", isActive: true))
}
