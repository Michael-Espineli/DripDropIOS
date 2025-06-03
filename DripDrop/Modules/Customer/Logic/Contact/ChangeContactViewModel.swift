//
//  ChangeContactViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/30/24.
//

import Foundation
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class ChangeContactViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var contactList:[Contact] = []
    func changeServiceLocationContact(companyId:String,serviceLocationId:String,contact:Contact) async throws {
        try await dataService.updateServiceLocationContact(companyId: companyId, serviceLocationId: serviceLocationId, contact: contact)
    }
    func getCustomerContacts(companyId:String,customerId:String,serviceLocationId:String) async throws {
        self.contactList = try await dataService.getAllContactsByCustomer(companyId: companyId, customerId: customerId)
    }
    func addNewCustomerContact(companyId:String,customerId:String,contact:Contact) async throws {
        try await dataService.uploadCustomerContact(companyId: companyId, customerId: customerId, contact: contact)
    }
    func funcDeleteCustomerContact(companyId:String,customerId:String,contactId:String) async throws {
        try await dataService.deleteCustomerContact(companyId: companyId, customerId: customerId, contactId: contactId)
    }
}
