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
    let templateId :String
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
