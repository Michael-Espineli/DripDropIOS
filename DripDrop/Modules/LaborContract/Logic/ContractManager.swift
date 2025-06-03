//
//  ContractManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/22/23.
//


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import Darwin

/// Contract - Between Client and Company
/// Recurring Contract - Between Client and Company (For Weekly Cleaning)
/// LaborContract - between Company and Sub
/// RecurringLaborContract - between Company and Sub (For Weekly Cleaning)
///

    
    // Contract - Between Client and Company
struct Contract:Identifiable, Codable, Hashable{
    var id:String
    var senderName:String
    var senderId:String
    var senderAcceptance:Bool
    var receiverName:String
    var receiverId:String
    var receiverAcceptance:Bool
    
    var dateSent:Date
    var lastDateToAccept:Date
    var dateAccepted:Date?
    var status:LaborContractStatus
    var terms:[ContractTerms]
    var notes:String
    var rate:Double
}

//subcollection
struct ContractWorkItems : Identifiable, Codable, Hashable{
    var id : String
    var name : String
    var description : String
}
    // Recurring Contract - Between Client and Company (For Weekly Cleaning)
struct RecurringContract:Identifiable, Codable, Hashable{
    var id:String = "rc_" + UUID().uuidString
    var chemType : RecurringContractChemType
    var cleaningPlan : RecurringContractCleaningPlan
    var repairType : BillingType
    var repairAmountMax : Int //Cents
    var filterServiceType : BillingType
    var companyId : String
    var companyName : String
    var internalCustomerId : String
    var internalCustomerName : String
    var clientId : String // linked Customer Id
    var email : String
    var dateSent : Date
    var dateToAccept : Date
    var laborRate : Int // Company Interanal // Cents
    var laborType : RecurringContractLaborType
    var locationCount : Int
    var internalNotes : String // Company Internal
    var rate : Int // Cents
    var rateType : RecurringContractRateType
    var serviceLocationIds : [String]
    var status : RecurringContractStatus
    var terms : String
    var priceId : String
    var productId : String
    var stripeCustomerId : String
    var connectedAccountId : String
    var subscriptionId : String
    var serviceFrequency : RecurringContractServiceFrequency
    var serviceFrequencyAmount : Int
    var companySetUp : Bool
    var atWill : Bool
    var externalNotes : String
    
        //    var listOfTasks - Stored in sub collection
        //    var adjustedListOfTasks - Stored in sub collection
    
    
    init(
        id : String,
        chemType : RecurringContractChemType,
        cleaningPlan : RecurringContractCleaningPlan,
        repairType : BillingType,
        repairAmountMax : Int,
        filterServiceType : BillingType,
        companyId : String,
        companyName : String,
        internalCustomerId : String,
        internalCustomerName : String,
        clientId : String,
        email : String,
        dateSent : Date,
        dateToAccept : Date,
        laborRate : Int,
        laborType : RecurringContractLaborType,
        locationCount : Int,
        internalNotes : String,
        rate : Int,
        rateType : RecurringContractRateType,
        serviceLocationIds : [String],
        status : RecurringContractStatus,
        terms : String,
        priceId : String,
        productId : String,
        stripeCustomerId : String,
        connectedAccountId : String,
        subscriptionId : String,
        serviceFrequency : RecurringContractServiceFrequency,
        serviceFrequencyAmount : Int,
        companySetUp : Bool,
        atWill : Bool,
        externalNotes :String

    ){
        self.id = id
        self.chemType = chemType
        self.cleaningPlan = cleaningPlan
        self.repairType = repairType
        self.repairAmountMax = repairAmountMax
        self.filterServiceType = filterServiceType
        self.companyId = companyId
        self.companyName = companyName
        self.internalCustomerId = internalCustomerId
        self.internalCustomerName = internalCustomerName
        self.clientId = clientId
        self.email = email
        self.dateSent = dateSent
        self.dateToAccept = dateToAccept
        self.laborRate = laborRate
        self.laborType = laborType
        self.locationCount = locationCount
        self.internalNotes = internalNotes
        self.rate = rate
        self.rateType = rateType
        self.serviceLocationIds = serviceLocationIds
        self.status = status
        self.terms = terms
        self.priceId = priceId
        self.productId = productId
        self.stripeCustomerId = stripeCustomerId
        self.connectedAccountId = connectedAccountId
        self.subscriptionId = subscriptionId
        self.serviceFrequency = serviceFrequency
        self.serviceFrequencyAmount = serviceFrequencyAmount
        self.companySetUp = companySetUp
        self.atWill = atWill
        self.externalNotes = externalNotes

    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case chemType = "chemType"
            case cleaningPlan = "cleaningPlan"
            case repairType = "repairType"
            case repairAmountMax = "repairAmountMax"
            case filterServiceType = "filterServiceType"
            case companyId = "companyId"
            case companyName = "companyName"
            case internalCustomerId = "internalCustomerId"
            case internalCustomerName = "internalCustomerName"
            case clientId = "clientId"
            case email = "email"
            case dateSent = "dateSent"
            case dateToAccept = "dateToAccept"
            case laborRate = "laborRate"
            case laborType = "laborType"
            case locationCount = "locationCount"
            case internalNotes = "internalNotes"
            case rate = "rate"
            case rateType = "rateType"
            case serviceLocationIds = "serviceLocationIds"
            case status = "status"
            case terms = "terms"
            case priceId = "priceId"
            case productId = "productId"
            case stripeCustomerId = "stripeCustomerId"
            case connectedAccountId = "connectedAccountId"
            case subscriptionId = "subscriptionId"
            case serviceFrequency = "serviceFrequency"
            case serviceFrequencyAmount = "serviceFrequencyAmount"
            case companySetUp = "companySetUp"
            case atWill = "atWill"
            case externalNotes = "externalNotes"

        }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(internalCustomerId)
    }
}


// LaborContract - between Company and Sub
struct LaborContract:Identifiable, Codable, Hashable{
    var id: String = "lc_" + UUID().uuidString
    var senderName: String
    var senderId: String
    var senderAcceptance: Bool
    var receiverName: String
    var receiverId: String
    var receiverAcceptance: Bool

    var type: LaborContractType
    var dateSent: Date
    var lastDateToAccept: Date
    var dateAccepted: Date?
    var status: LaborContractStatus
    var terms: [ContractTerms]
    var notes: String
    var rate: Int // Cents
    var senderJobId : IdInfo //senderCompanyJobId

    var customerId:String
    var customerName:String
    var serviceLocationId:String
    var serviceLocationName:String
    var jobTemplateId:String
    var jobTemplateName:String
    var isInvoiced:Bool
    var invoiceRef: IdInfo?
}


//ReccuringLabor Contract exists in seperate Manager
//struct ReccuringLaborContract:Identifiable, Codable, Hashable{

//Contract and Job Probably Have some Overlay

struct TermsTemplate:Identifiable, Codable, Hashable{
    var id:String = UUID().uuidString
    var name:String
}

struct ContractTerms:Identifiable, Codable, Hashable{
    var id:String = UUID().uuidString
    var description:String
}
