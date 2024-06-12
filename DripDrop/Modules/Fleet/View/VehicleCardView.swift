//
//  VehicleCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import SwiftUI

struct VehicleCardView: View {
    @Environment(\.locale) var locale

    let vehical: Vehical

    var body: some View {
        VStack(alignment: .leading){
            HStack{
                ZStack{
                    Circle()
                        .foregroundColor(Color.white)
                        .frame(width: 50, height: 50)
                    switch vehical.vehicalType {
                    case "Car":
                        Image(systemName: "car.fill")
                            .foregroundColor(Color.accentColor)
                            .frame(width: 50, height: 50)

                    case "Truck":
                        Image(systemName: "box.truck.fill")
                            .foregroundColor(Color.accentColor)
                            .frame(width: 50, height: 50)
                    case "Van":
                        Image(systemName: "bus")
                            .foregroundColor(Color.accentColor)
                            .frame(width: 50, height: 50)
                    default:
                        Image(systemName: "car.fill")
                            .foregroundColor(Color.accentColor)
                            .frame(width: 50, height: 50)
                    }
                }
                VStack{
                    Text("\(vehical.nickName)")
                    
                    HStack{
                        Text("\(vehical.color)")
                        Text("\(vehical.make)")
                        Text("\(vehical.model)")
                        Text("\(vehical.plate)")

                    }
                    HStack{
                        Text("\(fullDate(date:vehical.datePurchased))")
                            .font(.footnote)
                        Text("\(Measurement(value: vehical.miles, unit: UnitLength.kilometers).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))")
                            .font(.footnote)
                    }
                }
                Spacer()
            }
        }
    }
}

struct VehicleCardView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleCardView(vehical: Vehical(id: "", nickName: "", vehicalType: "", year: "", make: "", model: "", color: "Green",plate: "8UAWQHF", datePurchased: Date(), miles: 23503.1))
    }
}
