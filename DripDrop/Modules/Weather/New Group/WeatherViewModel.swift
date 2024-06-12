//
//  WeatherViewModel.swift
//  The Pool App
//
//  Created by Michael Espineli on 10/5/23.
//

import SwiftUI

import Foundation
@MainActor
final class WeatherViewModel:ObservableObject{
    @Published var currentWeather: Weather?

    
    func fetchWeather(address:Address) async throws{
        self.currentWeather = try await WeatherManager.shared.fetchWeather(address: address)
    }
}
