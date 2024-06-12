//
//  WeatherModel.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/3/23.
//

import Foundation
import SwiftUI
struct Weather: Identifiable {
    let id = UUID()
    
    let temperature: Int
    let weatherCode: WeatherCode
}

struct WeatherModel: Codable {
    let data: WeatherData
}

struct WeatherData: Codable {
    let timelines: [WeatherTimelines]
}

struct WeatherTimelines: Codable {
    let intervals: [WeatherIntervals]
}

struct WeatherIntervals: Codable {
    let startTime: String
    let values: WeatherValue
}

struct WeatherValue: Codable {
    var temperature: Double
    var weatherCode: Int
}

enum WeatherCode: String, Codable {
    case clear = "1000"
    case mostlyClear = "1100"
    case partlyCloudy = "1101"
    case mostlyCloudy = "1102"
    case cloudy = "1001"
    case fog = "2000"
    case lightFog = "2100"
    case lightWind = "3000"
    case wind = "3001"
    case strongWind = "3002"
    case drizzle = "4000"
    case rain = "4001"
    case lightRain = "4200"
    case heavyRain = "4201"
    case snow = "5000"
    case flurries = "5001"
    case lightSnow = "5100"
    case heavySnow = "5101"
    case freezingDrizzle = "6000"
    case freezingRain = "6001"
    case lightFreezingRain = "6200"
    case heavyFreezingRain = "6201"
    case icePellets = "7000"
    case heavyIcePellets = "7101"
    case lightIcePellets = "7102"
    case thunderstorm = "8000"
    
    var description: String {
        switch self {
        case .clear:
            return "It's very sunny!\n Don't forget your hat!"
        case .cloudy, .mostlyCloudy:
            return "Cloudy today!\n Watch out for some rain"
        case .mostlyClear, .partlyCloudy:
            return "Enjoy your day!"
        case .fog, .lightFog:
            return "Drive safe and make sure to turn on your low-beam headlights!"
        case .lightWind:
            return "Enjoy some light breeze today!"
        case .wind, .strongWind:
            return "Very windy today!"
        case .drizzle, .lightRain:
            return "A bit of rain,\n don't forget your umbrella!"
        case .rain, .heavyRain:
            return "Rainy today,\n don't forget your umbrella!"
        case .snow, .flurries, .lightSnow, .heavySnow:
            return "What a beautiful day!\n Don't forget your mittens!"
        case .freezingDrizzle:
            return "So cold brrr! Keep warm!"
        case .freezingRain, .lightFreezingRain, .heavyFreezingRain:
            return "Drive safe, the roads might be slippery!"
        case .icePellets:
            return "Ice Pellets"
        case .heavyIcePellets:
            return "Take cover!\n Heavy hail alert!"
        case .lightIcePellets:
            return "Light Ice Pellets"
        case .thunderstorm:
            return "Try to stay inside!\n Thunderstorm alert!"
        }
    }
    var title: String {
        switch self {
        case .clear:
            return "Clear"
        case .cloudy:
            return "Cloudy"
        case .mostlyCloudy:
            return "Mostly Cloudy"
        case .mostlyClear:
            return "Mostly Clear"
        case .partlyCloudy:
            return "Partly Cloudy"
        case .fog:
            return "Fog"
        case .lightFog:
            return "Light Fog"
        case .lightWind:
            return "Light Wind"
        case .wind :
            return "Wind"
        case .strongWind:
            return "Strong Wind"
        case .drizzle:
            return "Drizzle"
        case .lightRain:
            return "Light Rain"
        case .rain:
            return "Rain"
        case .heavyRain:
            return "Heavy Rain"
        case .snow:
            return "Snow"
        case .flurries:
            return "Flurries"
        case .lightSnow:
            return "Light Snow"
        case .heavySnow:
            return "Heavy Snow"
        case .freezingDrizzle:
            return "Freezing Drizzle"
        case .freezingRain:
            return "Freezing Rain"
        case .lightFreezingRain:
            return "Light Freezing Rain"
        case .heavyFreezingRain:
            return "Heavy Freezing Rain"
        case .icePellets:
            return "Heavy Ice Pellets"
        case .heavyIcePellets:
            return "Heavy Ice Pellets"
        case .lightIcePellets:
            return "Light Ice Pellets"
        case .thunderstorm:
            return "Thunderstorm"
        }
    }

    var image: Image {
        switch self {
        case .clear:
            return Image(systemName: "sun.max.fill")
        case .cloudy:
            return Image(systemName: "cloud.fill")
        case .mostlyClear, .partlyCloudy, .mostlyCloudy:
            return Image(systemName: "cloud.sun.fill")
        case .fog, .lightFog:
            return Image(systemName: "cloud.fog.fill")
        case .lightWind, .wind:
            return Image(systemName: "wind")
        case .strongWind:
            return Image(systemName: "tornado")
        case .drizzle:
            return Image(systemName: "cloud.drizzle.fill")
        case .lightRain, .rain:
            return Image(systemName: "cloud.rain.fill")
        case .heavyRain:
            return Image(systemName: "cloud.heavyrain.fill")
        case .snow, .flurries, .lightSnow, .heavySnow:
            return Image(systemName: "cloud.snow.fill")
        case .freezingDrizzle:
            return Image(systemName: "thermometer.snowflake")
        case .freezingRain, .lightFreezingRain, .heavyFreezingRain:
            return Image(systemName: "cloud.rain.fill")
        case .icePellets, .heavyIcePellets, .lightIcePellets:
            return Image(systemName: "cloud.hail.fill")
        case .thunderstorm:
            return Image(systemName: "cloud.bolt.rain.fill")
        }
    }
    var color: Color {
        switch self {
        case .clear:
            return Color.realYellow
        case .cloudy:
            return Color.gray
        case .mostlyClear, .partlyCloudy, .mostlyCloudy:
            return Color.white
        case .fog, .lightFog:
            return Color.white
        case .lightWind, .wind:
            return Color.realYellow
        case .strongWind:
            return Color.gray
        case .drizzle:
            return Color.gray
        case .lightRain, .rain:
            return Color.blue
        case .heavyRain:
            return Color.blue
        case .snow, .flurries, .lightSnow, .heavySnow:
            return Color.blue
        case .freezingDrizzle:
            return Color.blue
        case .freezingRain, .lightFreezingRain, .heavyFreezingRain:
            return Color.blue
        case .icePellets, .heavyIcePellets, .lightIcePellets:
            return Color.blue
        case .thunderstorm:
            return Color.red
        }
    }
    var foreGround: Color {
        switch self {
        case .clear:
            return Color.basicFontText
        case .cloudy:
            return Color.white
        case .mostlyClear, .partlyCloudy, .mostlyCloudy:
            return Color.basicFontText
        case .fog, .lightFog:
            return Color.white
        case .lightWind, .wind:
            return Color.basicFontText
        case .strongWind:
            return Color.white
        case .drizzle:
            return Color.white
        case .lightRain, .rain:
            return Color.white
        case .heavyRain:
            return Color.white
        case .snow, .flurries, .lightSnow, .heavySnow:
            return Color.white
        case .freezingDrizzle:
            return Color.white
        case .freezingRain, .lightFreezingRain, .heavyFreezingRain:
            return Color.white
        case .icePellets, .heavyIcePellets, .lightIcePellets:
            return Color.white
        case .thunderstorm:
            return Color.white
        }
    }
}
