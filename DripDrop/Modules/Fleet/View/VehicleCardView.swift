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
                    case .car:
                        Image(systemName: "car.fill")
                            .foregroundColor(Color.accentColor)
                            .frame(width: 50, height: 50)

                    case .truck:
                        Image(systemName: "box.truck.fill")
                            .foregroundColor(Color.accentColor)
                            .frame(width: 50, height: 50)
                    case .van:
                        Image(systemName: "bus")
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
                        Text("\(Measurement(value: vehical.miles, unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))")
                            .font(.footnote)
                    }
                }
                Spacer()
            }
        }
        .modifier(ListButtonModifier())

    }
}

struct VehicleCardView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleCardView(vehical: MockDataService.mockVehical)
    }
}
