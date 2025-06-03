//
//  BodyOfWaterViewModel.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class BodyOfWaterViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //----------------------------------------------------
    //                    VARIABLES
    //----------------------------------------------------
    
    //SINGLES
    @Published private(set) var bodyOfWater: BodyOfWater? = nil
    @Published private(set) var bodyOfWaterCount: Int? = nil

    //ARRAYS
    @Published private(set) var bodiesOfWater: [BodyOfWater] = []
    @Published private(set) var filteredBodiesOfWater: [BodyOfWater] = []

    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------

    func createBodiesOfWaterForCustomer(customer:Customer,serviceLocation:ServiceLocation,bodyOfWater:BodyOfWater,companyId: String) async throws {
        try await dataService.uploadServiceLocationBodyOfWater(companyId: companyId,bodyOfWater: bodyOfWater)
    }
    func createBodiesOfWaterForServiceLocation(serviceLocation:ServiceLocation,bodyOfWater:BodyOfWater,companyId: String) async throws {
        try await dataService.uploadBodyOfWaterByServiceLocation(companyId: companyId, bodyOfWater: bodyOfWater)
    }
    func addBOWToLocationWithValidation(serviceLocation:ServiceLocation,companyId: String,name: String, gallons: String, material: String, customerId: String, serviceLocationId: String, notes: String?, shape: String?, length: [String]?, depth: [String]?, width: [String]?,lastFilled:Date) async throws {
        //AddValidation
        if customerId == "" {
            throw BodyOfWaterError.invalidCustomerId
        }
        let id = UUID().uuidString
        
        let bodyOfWater = BodyOfWater(
            id:id ,
            name: name,
            gallons: gallons,
            material: material,
            customerId: customerId,
            serviceLocationId: serviceLocationId,
            notes: notes,
            shape: shape,
            length: length,
            depth: depth,
            width: width,
            lastFilled: lastFilled
        )
        //DEVELOPER ADD UPdated serviceLocation Id list view
        try await dataService.uploadBodyOfWaterByServiceLocation(companyId: companyId, bodyOfWater: bodyOfWater)
    }
    func editBOWToLocationWithValidation(companyId: String,bodyOfWater:BodyOfWater,bodyOfWaterId:String,name: String, gallons: String, material: String, notes: String?, shape: String?, length: [String]?, depth: [String]?, width: [String]?,lastFilled:Date) async throws {
        
        let id = UUID().uuidString
        if bodyOfWater.name == name  {
            print("Did not Update Body Of Water Name, it was the same")
        } else {
            print("Updating Body Of Water Name :\(bodyOfWaterId) ")
            try await dataService.editBodyOfWaterName(companyId: companyId, bodyOfWater: bodyOfWater, name: name)
        }
        if bodyOfWater.gallons == gallons  {
            print("Did not Update Body Of Water gallons, it was the same")
        } else {
            print("Updating Body Of Water gallons :\(bodyOfWaterId) ")
            try await  dataService.editBodyOfWaterGallons(companyId: companyId, bodyOfWater: bodyOfWater, gallons: gallons)
        }
        if bodyOfWater.material == material  {
            print("Did not Update Body Of Water material, it was the same")
        } else {
            print("Updating Body Of Water material :\(bodyOfWaterId) ")
            try await  dataService.editBodyOfWaterMaterial(companyId: companyId, bodyOfWater: bodyOfWater, material: material)
        }
        if let notes = notes {
            if bodyOfWater.notes == notes  {
                print("Did not Update Body Of Water notes, it was the same")
            } else {
                print("Updating Body Of Water notes :\(bodyOfWaterId) ")
                try  await dataService.editBodyOfWaterNotes(companyId: companyId, bodyOfWater: bodyOfWater, notes: notes)
            }
        } else {
            print("Notes is Nil")
        }
        if let shape = shape {
            if bodyOfWater.shape == shape  {
                print("Did not Update Body Of Water Shape, it was the same")
            } else {
                print("Updating Body Of Water Shape :\(bodyOfWaterId) ")
                try  await dataService.editBodyOfWaterShape(companyId: companyId, bodyOfWater: bodyOfWater, shape: shape)
            }
        } else {
            print("shape is Nil")
        }
        if let length = length {
            if bodyOfWater.length == length  {
                print("Did not Update Body Of Water length, it was the same")
            } else {
                print("Updating Body Of Water length :\(bodyOfWaterId) ")
                try  await dataService.editBodyOfWaterLength(companyId: companyId, bodyOfWater: bodyOfWater, length: length)
            }
        } else {
            print("Length is Nil")
        }
        if let depth = depth {
            if bodyOfWater.depth == depth  {
                print("Did not Update Body Of Water Depth, it was the same")
            } else {
                print("Updating Body Of Water Depth :\(bodyOfWaterId) ")
                try  await dataService.editBodyOfWaterDepth(companyId: companyId, bodyOfWater: bodyOfWater, depth: depth)
            }
        } else {
            print("Depth is Nil")
        }
        if let width = width {
            if bodyOfWater.width == width  {
                print("Did not Update Body Of Water Width, it was the same")
            } else {
                print("Updating Body Of Water Width :\(bodyOfWaterId) ")
                try  await dataService.editBodyOfWaterWidth(companyId: companyId, bodyOfWater: bodyOfWater, width: width)
            }
        } else {
            print("Width is Nil")
        }
        
        if bodyOfWater.lastFilled == lastFilled  {
            print("Did not Update Body Of Water Last Filled, it was the same")
        } else {
            print("Updating Body Of Water Width :\(bodyOfWaterId) ")
            try  await dataService.updateBodyOfWaterLastFilledDate(companyId: companyId, bodyOfWaterId: bodyOfWater.id, lastFilled: lastFilled)
        }
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
 
    func getAllBodiesOfWaterByServiceLocation(companyId: String,serviceLocation:ServiceLocation) async throws {
        
        self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocation(companyId: companyId, serviceLocation: serviceLocation)
        
    }
    func getAllBodiesOfWaterByServiceLocationId(companyId:String,serviceLocationId:String) async throws {
        self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)

    }
    func getAllBodiesOfWaterByServiceLocation(serviceLocationId:String,customerId:String,companyId: String) async throws {
        
        self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocationIdAndCustomerId(serviceLocationId: serviceLocationId, customerId: customerId, companyId: companyId)
        
    }
    func getBodiesOfWaterCount(serviceLocationId:String,customerId:String,companyId: String) async throws {
        self.bodyOfWaterCount = try? await dataService.getBodiesOfWaterCount(serviceLocationId: serviceLocationId, customerId: customerId, companyId: companyId)
    }
    func getSpecificBodyOfWater(companyId: String,bodyOfWaterId:String) async throws {
        self.bodyOfWater = try await dataService.getSpecificBodyOfWater(companyId: companyId, bodyOfWaterId: bodyOfWaterId)
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func editBodyOfWaterGallons(companyId: String,bodyOfWater:BodyOfWater,gallons:String) async throws {
        try  await dataService.editBodyOfWaterGallons(companyId: companyId, bodyOfWater: bodyOfWater,gallons: gallons)
        
    }
    func editBodyOfWater(companyId: String,bodyOfWater:BodyOfWater,updatedBodyOfWater:BodyOfWater) async throws {
        try  await dataService.editBodyOfWater(companyId: companyId, bodyOfWater: bodyOfWater,updatedBodyOfWater: updatedBodyOfWater)
        
    }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    FUNCTIONS
    //----------------------------------------------------
    func filterBodiesOfWater(bodiesOfWaterList:[BodyOfWater],term:String){
        self.filteredBodiesOfWater = bodiesOfWaterList
    }
}

