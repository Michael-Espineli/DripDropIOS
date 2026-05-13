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
                Spacer()
                Text("\(equipment.type.rawValue)")
            }
            if equipment.make == "" || equipment.model == "" {
                HStack{
                    Text("\(equipment.make)")
                    Text("\(equipment.model)")
                }
            }
            HStack{
                switch equipment.status {
                case .operational:
                    Text(equipment.status.rawValue)
                        .modifier(BlueButtonModifier())
                case .nonoperational:
                    Text(equipment.status.rawValue)
                        .modifier(DismissButtonModifier())
                case .needsRepair:
                    Text(equipment.status.rawValue)
                        .modifier(OrangeButtonModifier())
                case .needsMaintenance:
                    Text(equipment.status.rawValue)
                        .modifier(YellowButtonModifier())
                }
                
                
                Spacer()
                if equipment.needsService {
                    Text("Receives Maintenance")
                        .modifier(DismissButtonModifier())
                    Image(systemName: "book.and.wrench.fill")
                }
            }
            if equipment.needsService {
                VStack{
                    if equipment.type == .filter {
                        
                        if let cleanPressure  = equipment.cleanFilterPressure  {
                            HStack{
                                Text("Clean Preasures: ")
                                    .bold()
                                Spacer()
                                Text("\(String(format: "%.0f", Double(cleanPressure ))) PSI")
                            }
                            if let currentPressure = equipment.currentPressure {
                                let difference = Double(Int(currentPressure) - cleanPressure)
                                HStack{
                                    Text("Dirty: ")
                                        .bold()
                                    Spacer()
                                    Text("\(String(format: "%.0f",(difference/15)*100)) %")
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(Color.basicFontText)
    }
}

#Preview {
    EquipmentCardView(
        equipment: Equipment(
            id: "",
            name: "",
            type: .filter,
            typeId: "",
            make: "",
            makeId: "",
            model: "",
            modelId: "",
            dateInstalled: Date(),
            status: .operational,
            needsService: false,
            notes: "",
            customerName: "",
            customerId: "",
            serviceLocationId: "",
            bodyOfWaterId: "",
            isActive: true
        )
    )
}
