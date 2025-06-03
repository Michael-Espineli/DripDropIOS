//
//  BankingViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 8/30/24.
//

import Foundation
struct Bank:Identifiable{
    var id:String = UUID().uuidString
    var name:String
    var accountNumber:String
    var balance:Int
}
struct Transaction:Identifiable{
    var id:String = UUID().uuidString
    var name:String
    var date:Date
    var amount:Int //Cents
}
