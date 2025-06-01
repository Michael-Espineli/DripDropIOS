//
//  Chat+DS+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/12/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

extension ProductionDataService {
    //Refrences
    func chatCollection() -> CollectionReference{
        db.collection("chats")
    }
    func messageCollection() -> CollectionReference{
        db.collection("messages")
    }
    func chatDocument(chatId:String)-> DocumentReference{
        chatCollection().document(chatId)
    }
    func messageDocument(messageId:String)-> DocumentReference{
        messageCollection().document(messageId)
    }
}
