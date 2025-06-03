//
//  WorkLogSheet+DS+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/11/24.
//

import Foundation
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

struct WorkLogSheet:Identifiable, Codable,Hashable{
 
    var id:String
    var nickName:String
    init(
        id: String,
        nickName :String
    ){
        self.id = id
        self.nickName = nickName
    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case nickName = "nickName"
        }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(nickName)

    }
    static func == (lhs: WorkLogSheet, rhs: WorkLogSheet) -> Bool {
        return lhs.id == rhs.id &&
        lhs.nickName == rhs.nickName
    }
}

extension ProductionDataService {
    func WorkLogSheetCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/workLogsSheet")
    }
    func WorkLogSheetDocument(companyId:String,workLogId:String)-> DocumentReference{
        WorkLogCollection(companyId: companyId).document(workLogId)
    }
    //CREATE
    //READ
    //UPDATE
    //DELETE
}
