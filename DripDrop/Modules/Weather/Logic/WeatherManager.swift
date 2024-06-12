//
//  WeatherManager.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/3/23.
//

import Foundation
import CoreLocation

final class WeatherManager {
    static let shared = WeatherManager()

    private init(){}
    private let dateFormatter = ISO8601DateFormatter()
    var currentWeather: WeatherValue?

    func fetchWeather(address:Address) async throws -> Weather{
            let url = URL(string: "https://api.tomorrow.io/v4/timelines?location=\(address.latitude),\(address.longitude)&fields=temperature&fields=weatherCode&units=metric&timesteps=1h&startTime=\(dateFormatter.string(from: Date()))&endTime=\(dateFormatter.string(from: Date().addingTimeInterval(60 * 60)))&apikey=eQow9ahTOeX53kVUo7oCY9GsamPTgwqv")

 
            let (data, _) = try await URLSession.shared.data(from: url!)
            if let weatherResponse = try? JSONDecoder().decode(WeatherModel.self, from: data) {
                currentWeather = weatherResponse.data.timelines.first?.intervals.first?.values
                let weatherCode:WeatherCode = WeatherCode(rawValue: "\(currentWeather!.weatherCode)") ?? .thunderstorm
print()
                let fahrenheit = ((currentWeather?.temperature ?? 16) * ( 9 / 5 )) + 32
                return Weather(temperature: Int(fahrenheit), weatherCode: weatherCode)
            }
        let weatherCode:WeatherCode = .lightSnow
        let fahrenheit = ((25) * ( 9 / 5 )) + 32

        return Weather(temperature: Int(fahrenheit), weatherCode: weatherCode)
    }
}
