//
//  CameraViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/24/24.
//

import Foundation
import SwiftUI
import ImageCaptureCore

@MainActor
final class CameraViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
   
}
