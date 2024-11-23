//
//  BuisnessManager.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct AssociatedBuisness:Identifiable, Codable,Hashable{
    
    var id : String = UUID().uuidString
    let companyId : String
    let companyName : String
    //Developer I will need to add more items to this
}
final class BuisnessManager {
    
}
