//
//  Models.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//



import Foundation
import MapKit
import SwiftUI

//A

struct FeatureFlag: Identifiable, Codable, Hashable {
    var id: String
    var key: String
    var name: String
    var description: String?
    var enabled: Bool
    var index: Int
    var createdAt: Date?
    var updatedAt: Date?

    var displayName: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? key : trimmedName
    }

    static func id(for index: Int) -> String {
        "feature_flag_\(String(format: "%03d", index))"
    }

    static func defaultFlags(count: Int = 100) -> [FeatureFlag] {
        (1...count).map { index in
            let flagId = FeatureFlag.id(for: index)

            return FeatureFlag(
                id: flagId,
                key: flagId,
                name: FeatureFlag.defaultName(for: index),
                description: FeatureFlag.defaultDescription(for: index),
                enabled: false,
                index: index,
                createdAt: nil,
                updatedAt: nil
            )
        }
    }

    static func defaultName(for index: Int) -> String {
        switch index {
        case 1:
            return "iOS Messages"
        case 2:
            return "Company User Profile History"
        case 3:
            return "Management Technician Performance History"
        case 4:
            return "Sales"
        case 5:
            return "Turn on real emails"
        case 6:
            return "Payroll"
        default:
            return ""
        }
    }

    static func defaultDescription(for index: Int) -> String {
        switch index {
        case 1:
            return "Enables the iOS Messages experience."
        case 2:
            return "Enables company user profile history views."
        case 3:
            return "Enables management technician performance history."
        case 4:
            return "Enables the Sales slice: dashboard, catalog items, service agreements, and sales billing workflows."
        case 5:
            return "When off, service agreement and invoice emails are routed to the internal test inbox instead of homeowners."
        case 6:
            return "Enables Payroll and Payroll Setup under company Finance."
        default:
            return ""
        }
    }
}

enum FeatureFlagKey: String, CaseIterable {
    case iosMessages = "feature_flag_001"
    case companyUserProfileHistory = "feature_flag_002"
    case managementTechnicianPerformanceHistory = "feature_flag_003"
    case sales = "feature_flag_004"
    case realEmails = "feature_flag_005"
    case payroll = "feature_flag_006"
}

enum SalesAgreementStatus: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case draft = "draft"
    case sent = "sent"
    case revised = "revised"
    case accepted = "accepted"
    case rejected = "rejected"
    case expired = "expired"
    case canceled = "canceled"
}

enum SalesAgreementSourceType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case recurringService = "recurringService"
    case oneOffJob = "oneOffJob"
    case workOffer = "workOffer"
    case manual = "manual"
}

enum SalesBillingSubscriptionStatus: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case notStarted = "notStarted"
    case pendingPaymentMethod = "pendingPaymentMethod"
    case pendingStripe = "pendingStripe"
    case active = "active"
    case pastDue = "pastDue"
    case paused = "paused"
    case canceled = "canceled"
}

enum SalesInvoiceStatus: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case draft = "draft"
    case open = "open"
    case partiallyPaid = "partiallyPaid"
    case paid = "paid"
    case overdue = "overdue"
    case void = "void"
    case uncollectible = "uncollectible"
}

enum SalesInvoiceType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case subscription = "subscription"
    case oneTime = "oneTime"
    case manual = "manual"
    case adjustment = "adjustment"
}

enum SalesInvoiceDeliveryMethod: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case customerPortal = "customerPortal"
    case stripeHostedInvoice = "stripeHostedInvoice"
    case email = "email"
    case print = "print"
    case none = "none"
}

enum SalesPaymentStatus: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case pending = "pending"
    case posted = "posted"
    case failed = "failed"
    case refunded = "refunded"
    case void = "void"
}

enum SalesPaymentMethod: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case stripeCard = "stripeCard"
    case stripeAch = "stripeAch"
    case cash = "cash"
    case check = "check"
    case externalCard = "externalCard"
    case bankTransfer = "bankTransfer"
    case other = "other"
}

enum SalesBillingMode: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case connectedAccountDirectCharge = "connectedAccountDirectCharge"
    case connectedAccountDestinationCharge = "connectedAccountDestinationCharge"
}

enum SalesCatalogItemType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case service = "service"
    case recurringService = "recurringService"
    case labor = "labor"
    case material = "material"
    case fee = "fee"
    case discount = "discount"
    case tax = "tax"
    case manual = "manual"
}

enum SalesCatalogBillingBehavior: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case oneTime = "oneTime"
    case recurring = "recurring"
    case manualOnly = "manualOnly"
}

enum SalesCatalogSourceType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case manual = "manual"
    case serviceStopType = "serviceStopType"
    case workType = "workType"
    case task = "task"
    case databaseItem = "databaseItem"
    case shoppingListItem = "shoppingListItem"
    case stripeProductPrice = "stripeProductPrice"
}

struct SalesCatalogItem: Identifiable, Codable, Hashable {
    var id: String = "sci_" + UUID().uuidString
    var companyId: String
    var name: String
    var description: String
    var type: SalesCatalogItemType
    var billingBehavior: SalesCatalogBillingBehavior
    var sourceType: SalesCatalogSourceType
    var sourceId: String
    var unitAmountCents: Int
    var unitCostCents: Int
    var defaultQuantity: Int
    var taxable: Bool
    var active: Bool
    var currency: String
    var stripeConnectedAccountId: String
    var stripeProductId: String
    var stripePriceId: String
    var stripeRecurringInterval: String
    var stripeRecurringIntervalCount: Int
    var metadata: [String: String]?
    var createdAt: Date?
    var updatedAt: Date?
}

struct SalesBillingProfile: Identifiable, Codable, Hashable {
    var id: String = "sbp_" + UUID().uuidString
    var companyId: String
    var customerId: String
    var customerUserId: String?
    var relationshipId: String? = nil
    var customerCompanyRelationshipId: String? = nil
    var customerName: String
    var email: String
    var phoneNumber: String
    var serviceLocationIds: [String]
    var stripeConnectedAccountId: String
    var stripeCustomerId: String
    var defaultPaymentMethodId: String
    var invoiceDeliveryMethod: String
    var paymentTerms: String
    var currency: String
    var taxExempt: String
    var status: String
    var createdAt: Date?
    var updatedAt: Date?
}

struct SalesAgreementServiceLocationSnapshot: Identifiable, Codable, Hashable {
    var id: String
    var nickName: String?
    var streetAddress: String?
    var address02: String?
    var city: String?
    var state: String?
    var zip: String?
}

struct SalesAgreementEmailDelivery: Codable, Hashable {
    var provider: String?
    var templateId: String?
    var to: String?
    var intendedTo: String?
    var from: String?
    var replyTo: String?
    var messageId: String?
    var agreementUrl: String?
    var customerActionUrl: String?
    var customerPortalUrl: String?
    var claimAccountUrl: String?
    var homeownerSignInUrl: String?
    var homeownerSignUpUrl: String?
    var primaryCustomerUrl: String?
    var hasLinkedCustomerAccount: Bool?
    var shouldShowClaimAccountLink: Bool?
    var testMode: Bool?
    var realEmailsFeatureFlagId: String?
    var realEmailsEnabled: Bool?
    var lastSentAt: Date?
}

struct SalesAgreement: Identifiable, Codable, Hashable {
    var id: String = "sa_" + UUID().uuidString
    var companyId: String
    var companyName: String
    var customerId: String
    var customerUserId: String?
    var relationshipId: String? = nil
    var customerCompanyRelationshipId: String? = nil
    var customerName: String
    var email: String
    var serviceLocationIds: [String]
    var sourceType: SalesAgreementSourceType
    var sourceId: String
    var title: String
    var description: String
    var terms: String
    var termsTemplateId: String?
    var termsTemplateName: String?
    var termsTemplateDescription: String?
    var termsList: [String]?
    var lineItems: [SalesInvoiceLineItem]?
    var serviceLocationSnapshots: [SalesAgreementServiceLocationSnapshot]?
    var status: SalesAgreementStatus
    var billingProfileId: String
    var billingSubscriptionId: String
    var rateAmountCents: Int
    var subtotalAmountCents: Int?
    var taxAmountCents: Int?
    var totalAmountCents: Int?
    var rateType: String
    var serviceCadence: String
    var serviceCadenceCount: Int
    var paymentTerms: String?
    var invoiceDeliveryMethod: SalesInvoiceDeliveryMethod?
    var includedServices: [String]
    var excludedServices: [String]
    var startDate: Date?
    var endDate: Date?
    var expiresAt: Date?
    var atWill: Bool
    var createdByUserId: String
    var createdAt: Date?
    var updatedAt: Date?
    var sentAt: Date?
    var sentByUserId: String?
    var emailDelivery: SalesAgreementEmailDelivery?
    var acceptedAt: Date?
    var acceptedByUserId: String?
    var acceptedByUserName: String?
    var acceptedByEmail: String?
    var acceptedSource: String?
    var acceptedNote: String?
    var acceptedSnapshot: [String: String]?
}

struct SalesBillingSubscription: Identifiable, Codable, Hashable {
    var id: String = "sbs_" + UUID().uuidString
    var companyId: String
    var customerId: String
    var customerUserId: String?
    var relationshipId: String? = nil
    var customerCompanyRelationshipId: String? = nil
    var customerName: String? = nil
    var email: String? = nil
    var serviceLocationIds: [String]? = nil
    var agreementId: String
    var billingProfileId: String
    var stripeConnectedAccountId: String
    var stripeCustomerId: String
    var stripeProductId: String
    var stripePriceId: String
    var stripeSubscriptionId: String
    var stripeSubscriptionItemId: String
    var stripeLatestInvoiceId: String
    var stripeDefaultPaymentMethodId: String
    var billingMode: SalesBillingMode
    var status: SalesBillingSubscriptionStatus
    var stripeStatus: String
    var amountCents: Int
    var currency: String
    var interval: String
    var intervalCount: Int
    var currentPeriodStart: Date?
    var currentPeriodEnd: Date?
    var cancelAtPeriodEnd: Bool
    var canceledAt: Date?
    var applicationFeePercent: Double?
    var createdAt: Date?
    var updatedAt: Date?
}

struct SalesInvoiceLineItem: Identifiable, Codable, Hashable {
    var id: String = "sili_" + UUID().uuidString
    var catalogItemId: String?
    var sourceType: String
    var sourceId: String
    var description: String
    var name: String?
    var quantity: Int
    var unitAmountCents: Int
    var totalAmountCents: Int
    var taxable: Bool
    var type: String?
    var stripeProductId: String?
    var stripePriceId: String?
    var metadata: [String: String]?
}

struct SalesInvoice: Identifiable, Codable, Hashable {
    var id: String = "si_" + UUID().uuidString
    var companyId: String
    var companyName: String? = nil
    var customerId: String
    var customerUserId: String?
    var relationshipId: String? = nil
    var customerCompanyRelationshipId: String? = nil
    var customerName: String? = nil
    var email: String? = nil
    var serviceLocationIds: [String]? = nil
    var serviceLocationSnapshots: [SalesAgreementServiceLocationSnapshot]? = nil
    var agreementId: String
    var jobId: String
    var billingSubscriptionId: String
    var stripeConnectedAccountId: String
    var stripeInvoiceId: String
    var stripePaymentIntentId: String
    var stripeHostedInvoiceUrl: String?
    var stripeInvoicePdfUrl: String?
    var invoiceNumber: String
    var type: SalesInvoiceType?
    var status: SalesInvoiceStatus
    var deliveryMethod: SalesInvoiceDeliveryMethod?
    var currency: String
    var billingPeriodStart: Date?
    var billingPeriodEnd: Date?
    var dueDate: Date?
    var subtotalAmountCents: Int
    var discountAmountCents: Int
    var taxAmountCents: Int
    var totalAmountCents: Int
    var amountPaidCents: Int?
    var amountDueCents: Int?
    var writeOffAmountCents: Int?
    var memo: String?
    var lineItems: [SalesInvoiceLineItem]
    var createdAt: Date?
    var updatedAt: Date?
    var sentAt: Date?
    var paidAt: Date?
    var lastPaymentAt: Date?
}

struct SalesPayment: Identifiable, Codable, Hashable {
    var id: String = "sp_" + UUID().uuidString
    var companyId: String
    var customerId: String
    var customerUserId: String?
    var relationshipId: String? = nil
    var customerCompanyRelationshipId: String? = nil
    var customerName: String? = nil
    var email: String? = nil
    var invoiceId: String
    var billingProfileId: String
    var billingSubscriptionId: String
    var stripeConnectedAccountId: String
    var stripePaymentIntentId: String
    var stripeChargeId: String
    var stripeInvoiceId: String
    var method: SalesPaymentMethod
    var status: SalesPaymentStatus
    var amountCents: Int
    var currency: String
    var referenceNumber: String
    var memo: String
    var receiptUrl: String
    var recordedByUserId: String
    var receivedAt: Date?
    var createdAt: Date?
    var updatedAt: Date?
    var voidedAt: Date?
}

struct SalesPaymentEvent: Identifiable, Codable, Hashable {
    var id: String = "spe_" + UUID().uuidString
    var companyId: String
    var customerId: String
    var customerUserId: String?
    var relationshipId: String? = nil
    var customerCompanyRelationshipId: String? = nil
    var customerName: String? = nil
    var email: String? = nil
    var invoiceId: String
    var billingSubscriptionId: String
    var stripeConnectedAccountId: String
    var stripeEventId: String
    var stripeObjectId: String
    var type: String
    var amountCents: Int
    var currency: String
    var status: String
    var receivedAt: Date?
    var processedAt: Date?
}


struct Address:Codable, Hashable{
    var streetAddress :String
    var city : String
    var state : String
    var zip : String
    var latitude : Double
    var longitude : Double
    var coordinates : CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    init(
        streetAddress: String,
        city: String,
        state: String,
        zip: String,
        latitude: Double,
        longitude: Double
    ){
        self.streetAddress = streetAddress
        self.city = city
        self.state = state
        self.zip = zip
        self.latitude = latitude
        self.longitude = longitude
    }
        enum CodingKeys:String, CodingKey {
            case streetAddress = "streetAddress"
            case city = "city"
            case state = "state"
            case zip = "zip"
            case latitude = "latitude"
            case longitude = "longitude"
        }
}
//B
struct BillingTemplate:Identifiable, Codable{
    var id:String
    var title:String
    var defaultSelected:Bool
    var laborType:String //per Stop, Weekly, Monthly
    var chemType:String //All inclusive, Without Chems, Includes specific Chems, Excludes Specific Chems
    var notes:String

}
struct CustomerArray: Codable{
    let serviceStops: [ServiceStop]
    let total, skip, limit : Int
}
struct Contact:Identifiable, Codable,Hashable{
    var id:String
    var name:String //DEVELOPER DEVENTUALLY LOWERCASE
    var phoneNumber:String
    var email:String
    var notes:String?
    init(
        id: String,
        name :String,
        phoneNumber :String,
        email :String,
        notes: String? = nil
    ){
        
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.notes = notes
    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case name = "name"
            case phoneNumber = "phoneNumber"
            case email = "email"
            case notes = "notes"
        }
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.phoneNumber == rhs.phoneNumber &&
        lhs.email == rhs.email &&
        lhs.notes == rhs.notes
    }
}
struct CheckListItems:Identifiable, Codable{
    var id:String
    var Name:String
    var completed:Bool
    var description:String
    var season:String
    
}
struct CheckListTemplate:Identifiable, Codable{
    var id:String
    var Name:String
    var email:String
    var notes:String?
}


struct ChartData:Identifiable, Codable,Hashable{
    var id:String
    var date: Date
    var amount:Double
}
struct ChartDataArray: Codable,Hashable{
    let name :String
    let chartData: [ChartData]
    
}
struct CustomerMonthlySummary:Identifiable, Codable,Hashable{
    var id:String
    var date: Date
    var customerId:String
    var customerDisplayName:String

    var serviceLocationId:String

    var monthlyRate:Double

    var chemicalCost:Double
    var laborCost:Double
    
    var loss:Double {
        chemicalCost + laborCost
    }
    var profit:Double {
        monthlyRate - chemicalCost - laborCost
    }
    var serviceStops:Double
    var profitable:Bool {
        profit > loss
    }
    
}
//D
struct Dosage:Identifiable, Codable,Hashable{
    
    let id :String
    let templateId :String //Locaal Template Id
    let universalTemplateId: String
//    let itemId :String
    
    let name: String?
    let amount : String?
    let UOM : String?
    let rate : String?
    let linkedItem : String?//DB Item
    let bodyOfWaterId:String
    //add Chemical Type?
    
    // Chemical types
    //--Raising Ph --
    //  Soda Ash / Washing Soda
    //  Borax (20 Mule)
    
    //--Lowering Ph --
    //    15.7% - 10 Baume
    //    28.3% - 18 Baume
    //    31.45% - 20 Baume
    //    34.6% - 22 Baume
    //    14.5% Muriatic Acid
    //    29% Muriatic Acid
    //    29% Dry Acid
    
    //--Sanitier--
    //  Bleach + bleach chlorine %
    //Others I have to add
    
    //--Stabilizer--
    //  Dry Stabilizer
    //  Liquid Stabilizer
    
    //--Alkalinity--
    //  Baking Soda
}
struct DosageTemplate:Identifiable, Codable,Hashable{
    
    let id :String
    let name: String?
    let amount : [String]?
    let UOM : String?
    let rate : String?
    let linkedItemId:String?
    let strength :Double
    let editable :Bool
    let chemType :String
    let order : Int

}
struct SavedDosageTemplate:Identifiable, Codable,Hashable{
    
    let id :String
    let dosageTemplateId: String //Universal Template Id
    let name: String?
    let amount : [String]?
    let UOM : String?
    let rate : String?
    let linkedItemId:String?
    let strength :Double
    let editable :Bool
    let chemType :String
    let order : Int

}
struct DataBaseItem:Identifiable,Codable,Hashable{
    var id : String
    var name: String
    var rate: Double
    var storeName : String
    var venderId : String
    var category : DataBaseItemCategory
    var subCategory : DataBaseItemSubCategory
    var description : String
    var dateUpdated : Date
    var sku : String
    var billable : Bool
    var color : String
    var size : String
    var UOM : UnitOfMeasurment
    var tracking : String?
    var sellPrice:Double? //What to charge customer
    var timesPurchased:Int?
    var universalEquipmentId: String?
    var equipmentTypeId: String?
    var equipmentType: String?
    var equipmentMakeId: String?
    var equipmentMake: String?
    var equipmentModelId: String?
    var equipmentModel: String?
    var manualPdfLink: String?

}
struct CSVDataBaseItem{
    var name:String = ""
    var rate:String = ""
    var storeName:String = ""
    var venderId:String = ""
    var category:String = ""
    var subCategory:String = ""

    var description:String = ""
    var sku:String = ""
    var billable:String = ""
    var color:String = ""
    var size:String = ""
    var UOM:String = ""
    var tracking:String = ""
    var sellPrice:String = ""
    var lastUpdated:String = ""

    init(raw:[String]){
        name = raw[0]
        rate = raw[1]
        category = raw[2]
        subCategory = raw[3]
        description = raw[4]
        sku = raw[5]
        billable = raw[6]
        sellPrice = raw[7]
        color = raw[8]
        size = raw [9]
        UOM = raw[10]
        lastUpdated = raw[11]

    }

}
//DEVELOPER MAYBE DELETE
struct DataBaseCategories:Identifiable,Codable{
    var id : String
    var name: String
    var store : String

}
struct DataBaseSubCategories:Identifiable,Codable,Hashable{
    var id : String
    var name: String
    var category : String
    static func == (lhs: DataBaseSubCategories, rhs: DataBaseSubCategories) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.category == rhs.category


    }
}

//E

//F
//G

//H
struct History:Identifiable, Codable{
    var id:String
    var date:Date
    var tech:String
    var changes:[String]
    
}
//I
struct Increment:Codable{
    let category:String
    let increment:Int
}
struct Invoice:Identifiable, Codable{
    
    let id :String
    let storeId: String?
    let customerId : String?
    let purchasedItem: [PurchasedItem]?
    let datePurchased : Date?
    let total : Int?
    let tech: String?
}
struct InvoiceArray: Codable{
    let invoices: [Invoice]
    let total, skip, limit : Int
    
}
//J
struct JobChat:Identifiable, Codable{
    var id:String
    var participants:[String]
    var sameCompany:Bool
    var jobId:String

}
struct PublicJob:Identifiable, Codable{
    var id:String
    var title:String
    var tags:[String]
    var jobDescription:String
    var rate:String
    var serviceLocation:ServiceLocation
    var customer:Customer
    var status:String //open,pending,accepted,workFinished,closed
    var userPosted:String
    var userPostedId:String

    var datePosted:Date
    var doneBy:Date
    var chatIds:[String]
    var userAccepted:String
    var userAcceptedId:String

}
struct JSONWorkOrderTemplate:Identifiable, Codable{
    
    let id :String
    let type: String?
    let dateCreated : String
    let rate : String?
    let color: String?
}
//K
//L
//M


struct MapLocation:Identifiable, Codable,Equatable{
    static func == (lhs: MapLocation, rhs: MapLocation) -> Bool {
        return lhs.id == rhs.id &&
        lhs.customerId == rhs.customerId &&
        lhs.name == rhs.name &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
    }
    
    var id = UUID().uuidString
    let customerId: String
    let name: String
    let latitude: Double
    let longitude: Double
    let address: Address
    var color: String
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
}

//Rename to Simple Map Location
struct MapLocation2:Identifiable{
    var id = UUID().uuidString
    let name: String
    var coordinate: CLLocationCoordinate2D
    
}
//N
//O
//P

struct PurchasedItem:Identifiable,Codable,Equatable,Hashable{
    var id : String
    var receiptId: String
    var invoiceNum: String
    var venderId: String
    var venderName: String
    var techId : String
    var techName : String
    var itemId: String
    var name : String
    var price : Double
    var quantityString : String
    var date : Date	
    var billable : Bool
    var invoiced : Bool
    var returned : Bool?

    var customerId : String
    var customerName : String
    var sku : String
    var notes : String
    var jobId: String
    var workOrderId: String?
    var assignedJobId: String?
    var assignedToJob: Bool?
    var assignmentStatus: String?
    var billingOwner: String?
    var jobBillingStatus: String?
    var jobBillable: Bool?
    var jobBillingRate: Double?
    var universalEquipmentId: String?
    var installedEquipmentId: String?
    var installationJobId: String?
    var installationTaskId: String?
    var installedAt: Date?
    
    var quantity : Double{
        Double(quantityString) ?? 0.00
    }
    
    var total : Double{
        price * quantity
    }
    var totalAfterTax : Double{
        total * 1.085
    }
    var billingRate:Double? //What to charge customer
    var isAssignedToJob: Bool {
        assignedToJob ?? !jobId.isEmpty || !(workOrderId ?? "").isEmpty || assignmentStatus == "assignedToJob"
    }
    var isJobBillable: Bool {
        jobBillable ?? billable
    }
    var jobMaterialBillingRate: Double {
        jobBillingRate ?? billingRate ?? price
    }
    static func == (lhs: PurchasedItem, rhs: PurchasedItem) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.invoiceNum == rhs.invoiceNum &&
        lhs.receiptId == rhs.receiptId &&
        lhs.itemId == rhs.itemId
    }
}
struct LineItem:Identifiable,Codable,Equatable{
    
    var id : String
    
    var receiptId: String
    var invoiceNum: String
    var storeId: String
    var storeName: String
    var techId : String
    var techName : String
    var itemId: String
    var name : String
    var price : Double
    var quantityString : String
    var date : Date
    var billable : Bool
    var invoiced : Bool
    var customerId : String
    var customerName : String
    var sku : String
    var notes : String
    var sellPrice: Double?
    var quantity : Double{
        Double(quantityString) ?? 0.00
    }
    
    var total : Double{
        price * quantity
    }
    var totalAfterTax : Double{
        total * 1.085
    }
    //    var soldPrice : Double
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(invoiceNum)
        hasher.combine(receiptId)
        hasher.combine(itemId)
    }
    static func == (lhs: LineItem, rhs: LineItem) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.invoiceNum == rhs.invoiceNum &&
        lhs.receiptId == rhs.receiptId &&
        lhs.itemId == rhs.itemId
    }
}
struct PurchasedItemSummary:Identifiable,Codable{
    var id : String
    var purchasedItemId: String
    var purchasedItemName: String
    var purchasedItemRate: Double
    var quantityPurchased: Double
    var totalCost: Double {
        purchasedItemRate * quantityPurchased
    }
    var totalCostAfterTax: Double {
        purchasedItemRate * quantityPurchased
    }
}

struct PNLChem:Identifiable, Codable,Hashable{
    var id:String
    var chemName:String
    var date: Date
    var amount:Double
    var rate:Double
    var serviceStopId:String
    var totalCost:Double {
        amount * rate
    }
}
struct PNLDataPointArray: Codable,Hashable{
    let id :String

    let date :Date
    let techId : String
    let tech : String
    let laborCost : Double
    let PNLDataPoint: [PNLChem]
    
}
//Q
//R
struct ReceiptItemArray: Codable{
    let purchasedItems: [PurchasedItem]
    let total, skip, limit : Int
    
}
struct Receipt:Identifiable,Codable,Equatable{
    var id :String
    var invoiceNum :String?
    var date : Date?
    var storeId : String?
    var storeName : String?
    var tech : String?
    var techId : String?
    var purchasedItemIds : [String]?
    var numberOfItems : Int
    var cost : Double
    var costAfterTax : Double
    var pdfUrlList : [String]?
    
    init(
        id: String,
        invoiceNum :String? = nil,
        date : Date? = nil,
        storeId : String? = nil,
        storeName: String? = nil,
        tech: String? = nil,
        techId: String? = nil,
        purchasedItemIds: [String]? = nil,
        numberOfItems: Int,
        cost: Double,
        costAfterTax: Double,
        pdfUrlList: [String]? = nil

    ){
        self.id = id
        self.invoiceNum = invoiceNum
        self.date = date
        self.storeId = storeId
        self.storeName = storeName
        self.tech = tech
        self.techId = techId
        self.purchasedItemIds = purchasedItemIds
        self.numberOfItems = numberOfItems
        self.cost = cost
        self.costAfterTax = costAfterTax
        self.pdfUrlList = pdfUrlList

        
    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case invoiceNum = "invoiceNum"
            case date = "date"
            case storeId = "storeId"
            case storeName = "storeName"
            case tech = "tech"
            case techId = "techId"
            case purchasedItemIds = "purchasedItemIds"
            case numberOfItems = "numberOfItems"
            case cost = "cost"
            case costAfterTax = "costAfterTax"
            case pdfUrlList = "pdfUrlList"

        }
    static func == (lhs: Receipt, rhs: Receipt) -> Bool {
        return lhs.id == rhs.id &&
        lhs.invoiceNum == rhs.invoiceNum &&
        lhs.storeId == rhs.storeId &&
        lhs.techId == rhs.techId
    }
}
struct RecurringServiceStopArray: Codable{
    let recurringServiceStop: [RecurringServiceStop]
    let total, skip, limit : Int
    
}

struct Recording:Identifiable, Codable,Hashable{
    var id :String
    var techId: String
    var techName: String
    var itemId: String
    var itemName: String
    var date : Date
    var amount : Double
}

struct idealRoute:Identifiable, Codable,Hashable{
    
    let id :String
    let name: String?
    let day :String
    let standardFrequencyNumber : Int
    let customFrequencyType : String
    let customFrequency : String
    let daysOfWeek : [String]

    let startDate : Date
    let endDate : Date?
    let noEndDate : Bool
    let tech : String
    let techId : String
    let customerList : [String]
    let description : String
    let workOrderType : String
    let workOrderId : String
}
/*
struct RecurringRoute:Identifiable, Codable,Hashable{
    static func == (lhs: RecurringRoute, rhs: RecurringRoute) -> Bool {
        return lhs.id == rhs.id &&
        lhs.tech == rhs.tech &&
        lhs.techId == rhs.techId &&
        lhs.day == rhs.day &&
        lhs.description == rhs.description
    }
    
    var id :String // DEVELOPER CHANGE ID TO NOT BE DAY + TECHID THIS IS GOING TO CREATE ISSUES WHEN CREATED AND MODIFYING ROUTES
    var tech: String
    var techId: String
    var day:String
    var order:[recurringRouteOrder]
    var description: String
    //Start Date
    //DEVELOPER ADD END DATE ? if NEEDED
    // DEVELOPER ADD STATUS
    //R124-R126
}
 */
struct RateSheetItem:Identifiable, Codable,Hashable{
    var id :String
    var name: String
    var workOrderTemplateId: String
    var contractDate: Date
    var hourlyRate: Double
    var contractedRate : Double
    var description: String
}
//S
struct StopHistoryDisplay:Identifiable, Codable,Hashable{
    var id:String
    var serviceStopId:String
    var date: Date
    var readings:[Double]
    var dosages:[Double]

}

struct StopHistoryDisplayArray: Codable,Hashable{
    let id : String
    let PNLDataPoint: [StopHistoryDisplay]
}




struct ServiceStopArray: Codable{
    let serviceStops: [ServiceStop]
    let total, skip, limit : Int
    
}
struct StopDataArray: Codable{

    
    let readings: [StopData]
    let total, skip, limit : Int
    
}

//T
//U
//V
//W
struct Warning:Identifiable,Codable{
    var id : String
    var category: String //parts equipment messages chems

    var userIDCreated : String
    var userNameCreated : String
    var details : String
    var dateCreated : Date
    var Status : String //Unresolved, In Progress, Resolved

}
struct WasteSummary:Identifiable, Codable,Hashable{
    
    
    var id:String
    var techId:String
    var techName:String
    var total:Double
    var used:Double
    var waste:Double {
        total - used
    }

}


struct WorkOrderArray: Codable{
    let serviceStops: [ServiceStop]
    let total, skip, limit : Int
    
}

struct WODBItem:Identifiable, Codable{ // work order data base item
    var id:String
    var name:String
    var quantity:Double
    var cost:Double
    var genericItemId:String
    var total: Double {
        quantity * cost
    }
}

//X
//Y
//Z

//Mac app Specific Models

struct CSVCustomer{
    
    var firstName:String = ""
    var lastName:String = ""
    var tech:String = ""
    var streetAddress:String = ""
    var city:String = ""
    var state:String = ""
    var zip:String = ""
    var phone:String = ""
    var rate:String = ""
    var email:String = ""
    var hireDate:String = ""
    var gateCode:String = ""
    var notes:String = ""

    init(raw:[String?]){
        firstName = raw[0] ?? ""
        lastName = raw[1] ?? ""
        tech = raw[2] ?? ""
        streetAddress = raw[3] ?? ""
        city = raw[4] ?? ""
        state = raw[5] ?? ""
        zip = raw[6] ?? ""
        phone = raw[7] ?? ""
        rate = raw[8] ?? ""
        email = raw[9] ?? ""
        hireDate = raw[10] ?? ""
    }
}

struct mapCoordinates{
    var lat:Double
    var long:Double
}
//??
