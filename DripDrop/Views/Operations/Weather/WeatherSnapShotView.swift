//
//  WeatherSnapShotView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/3/23.
//

import SwiftUI

struct WeatherSnapShotView: View {
    var weather:Weather
    var body: some View {
        Button(action: {
#if os(iOS)
            let url = URL(string: "Weather://?saddr")
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            }
#endif
        }, label: {
            HStack{
                weather.weatherCode.image
                    .frame(width: 20)
                    .foregroundColor(Color.black)
                VStack{
                    Text("\(String(weather.weatherCode.title))")
                        .foregroundColor(Color.black)
                    Text("\(String(weather.temperature)) °F")
                        .foregroundColor(Color.black)
                }
            }
            .modifier(ListButtonModifier())
            .modifier(OutLineButtonModifier())
        })
    }
}

struct WeatherSnapShotView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherSnapShotView(weather: Weather(temperature: 87, weatherCode: .cloudy))
    }
}
