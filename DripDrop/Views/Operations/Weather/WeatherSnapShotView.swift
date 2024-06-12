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
        VStack{
            VStack{
                weather.weatherCode.image
                    .frame(width: 20)
                    .foregroundColor(Color.white)
//                    .foregroundColor(weather.weatherCode.color)
                Spacer()
                Text("\(String(weather.weatherCode.title))")
                    .foregroundColor(Color.white)
                Spacer()
                Text("\(String(weather.temperature)) °F")
                    .foregroundColor(Color.white)
            }
            .padding(5)
            .background(Color.gray)

//            .background(weather.weatherCode.color)
            .cornerRadius(10)
        }
    }
}

struct WeatherSnapShotView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherSnapShotView(weather: Weather(temperature: 87, weatherCode: .cloudy))
    }
}
