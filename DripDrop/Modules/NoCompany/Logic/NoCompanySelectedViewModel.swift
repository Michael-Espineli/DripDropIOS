//
//  SubscriptionPickerViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//


import Foundation
import SwiftUI
import StripePaymentSheet
import FirebaseFunctions

@MainActor
final class SubscriptionPickerViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }