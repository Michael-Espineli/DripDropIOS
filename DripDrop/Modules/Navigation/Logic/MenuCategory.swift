//
//  MenuCategory.swift
//  PoolAppForHomeOwners
//
//  Created by Michael Espineli on 12/15/23.
//
//DEVELOPER GO THROUGH AND MAKE SURE THAT THE ROUTE AND THE MACCATEGORIES USE THE SAME NAMING CONVETION
import Foundation
enum MacCategories: String, Hashable, CaseIterable, Identifiable,Codable{
    
    case profile//
    case dashBoard//

    case dailyDisplay//
    case customers//
    case serviceStops//
    case managementTables//

    case routeBuilder//
    case management
    case fleet//
    case jobs //
    case repairRequest//
    case contract//

    case purchases//
    case receipts//
    case databaseItems//
    case genericItems//
    case vender//
    
    case pnl //Remove
    
    case users //
    case userRoles//
    case companyProfile//
    case reports//
    case readingsAndDosages//
    case calendar//
    case maps//
    case companyAlerts
    case personalAlerts
    case receivedLaborContracts
    case sentLaborContracts

    //Private
    case chat//

    //Public
    case marketPlace//
    case jobPosting//
    case feed//
    //New
    case companyRouteOverView//
    case externalRoutesOverview//

    case accountsPayable//
    case accountsReceivable//
    case equipment//
    case settings
    case jobTemplates
    case contracts
    case alerts
    case shoppingList
    case businesses
    case companyUser
    case taskGroups

    var id: String{
        return self.rawValue
    }
    func title() -> String{
        switch self{
        case .managementTables:
            return "Management Tables"
        case .dashBoard:
            return "Dashboard"
            
        case .customers:
            return "Customers"
            
        case .serviceStops:
            return "Service Stops"
            
        case .databaseItems:
            return "Vender Items"
            
        case .routeBuilder:
            return "Route Builder"
            
        case .maps:
            return "Maps"
            
        case .dailyDisplay:
            return "Daily Route"
            
        case .calendar:
            return "Calendar"
            
        case .profile:
            return "Profile"
            
        case .contract:
            return "Contract"
            
        case .pnl:
            return "P.N.L."
            
        case .vender:
            return "Vender"
            
        case .purchases:
            return "Purchases"
            
        case .receipts:
            return "Receipts"
            
        case .jobs:
            return "Jobs"
            
        case .management:
            return "Route Managment"
            
        case .userRoles:
            return "User Roles"
            
        case .users:
            return "Users"
            
        case .companyProfile:
            return "Company Profile"
            
        case .repairRequest:
            return "Repair Request"
            
        case .chat:
            return "Chat"
            
        case .marketPlace:
            return "Market Place"
            
        case .jobPosting:
            return "Job Posting"
            
        case .feed:
            return "Feed"
            
        case .reports:
            return "Reports"
            
        case .fleet:
            return "Fleet"
            
        case .readingsAndDosages:
            return "Reading And Dosages"
            
        case .genericItems:
            return "Generic Items"
        case .companyRouteOverView:
            return "Company Route OverView"
        case .accountsPayable:
            return "Accounts Payable"
        case .accountsReceivable:
            return "Accounts Receivable"
        case .equipment:
            return "Equipment"
        case .settings:
            return "Settings"
        case .jobTemplates:
            return "Job Templates"
        case .contracts:
            return "Contracts"
        case .companyUser:
            return "Company User"
        case .alerts:
            return "Alerts"
        case .shoppingList:
            return "Shopping List"
        case .businesses:
            return "Businesses"
        case .companyAlerts:
            return "company Alerts"
        case .personalAlerts:
            return "personal Alerts"
        case .receivedLaborContracts:
            return "labor Contracts"
        case .externalRoutesOverview:
            return "External Labor Contracts"
        case .taskGroups:
            return "Task Groups"
        case .sentLaborContracts:
            return "Sent Labor Contracts"
        }
    }
    func imageName() -> String{
        switch self{
        case .receipts:
            return "doc.richtext.fill"
            
        case .dashBoard:
            return "terminal"
            
        case .customers:
            return "person.3.fill"
            
        case .serviceStops:
            return "testtube.2"
            
        case .databaseItems:
            return "archivebox"
            
        case .routeBuilder:
            return "point.topleft.down.curvedto.point.filled.bottomright.up"
            
        case .maps:
            return "map"
            
        case .dailyDisplay:
            return "fuelpump.fill"
            
        case .calendar:
            return "calendar"
            
        case .profile:
            return "person.circle"
            
        case .vender:
            return "basket"
            
        case .contract:
            return "doc.text"
            
        case .pnl:
            return "dollarsign"
            
        case .purchases:
            return "dollarsign"
            
        case .jobs:
            return "spigot.fill"
            
        case .management:
            return "checkerboard.shield"
            
        case .users:
            return "person.fill"
            
        case .userRoles:
            return "checkerboard.shield"
            
        case .companyProfile:
            return "checkerboard.shield"
            
        case .repairRequest:
            return "wrench.adjustable.fill"
            
        case .chat:
            return "message.fill"

        case .marketPlace:
            return "globe.americas.fill"
            
        case .jobPosting:
            return "rectangle.3.group.bubble.left"
            
        case .feed:
            return "door.french.open"
            
        case .reports:
            return "doc.text"
            
        case .fleet:
            return "car.2.fill"
            
        case .readingsAndDosages:
            return "testtube.2"
            
        case .genericItems:
            return "book"

        case .companyRouteOverView:
            return "book" //DEVELOPER FIX
        case .accountsPayable:
            return "book" //DEVELOPER FIX

        case .accountsReceivable:
            return "book" //DEVELOPER FIX

        case .equipment:
            return "book" //DEVELOPER FIX
        case .settings:
            return "testtube.2"
        case .jobTemplates:
            return "terminal"
        case .contracts:
            return "terminal"
        case .companyUser:
            return "testtube.2"

        case .alerts:
            return "testtube.2"
        case .shoppingList:
            return "testtube.2"
        case .businesses:
            return "doc.richtext.fill"
        case .companyAlerts:
            return "testtube.2"
        case .personalAlerts:
            return "testtube.2"
        case .receivedLaborContracts:
            return "testtube.2"
        case .externalRoutesOverview:
            return "testtube.2"
        case .managementTables:
            return "archivebox"
        case .taskGroups:
            return "archivebox"
        case .sentLaborContracts:
            return "archivebox"
        }
    }
    
}

enum MobileCategories: String, Hashable, CaseIterable, Identifiable,Equatable{
    case profile
    
    case operations
    case finace
    case administrative
    case inventory
    case marketPlace
    case settings
    
    var id: String{
        return self.rawValue
    }
    
    func title() -> String{
        switch self{
        case .profile:
            return "Profile"
        case .operations:
            return "Operations"
        case .finace:
            return "Finace"
        case .administrative:
            return "Administrative"
        case .inventory:
            return "Inventory"
        case .marketPlace:
            return "Market Place"
        case .settings:
            return "Settings"
        }
    }
    func imageName() -> String{
        switch self{
        case .profile:
            return "profile"
        case .operations:
            return "speedometer"
        case .finace:
            return "dollarsign.square.fill"
        case .administrative:
            return "calendar"
        case .inventory:
            return "books.vertical"
        case .marketPlace:
            return "cart"
        case .settings:
            return "gear"
        }
    }
}
//enum PersonalCategories: String, Hashable, CaseIterable, Identifiable,Equatable{
//
//    case profile
//    case marketPlace
//    case settings
//
//    var id: String{
//        return self.rawValue
//    }
//
//    func title() -> String{
//        switch self{
//        case .profile:
//            return "Profile"
//        case .marketPlace:
//            return "Market Place"
//        case .settings:
//            return "Settings"
//        }
//    }
//    func imageName() -> String{
//        switch self{
//        case .profile:
//            return "profile"
//        case .marketPlace:
//            return "cart"
//        case .settings:
//            return "gear"
//        }
//    }
//}

enum MenuCategory: Int, CaseIterable, Identifiable {
    
    var id: Int { rawValue }
    case profile
    case chat
//Operations
    case dailyRoute
    case serviceStops
    case customers

    case routeBuilder
    case routeManagment
     
//Build out Finace
    //Case Admin
    case jobs
    case techRoles
    case calendar
    case companyProfile
    //Case inventory
    case receipts
    case purchases
    case databaseItems
    case venders
    case invoice
    case estimate
    
    //Build out Market
    
    case market

}

extension MenuCategory {
    
    var title: String {
        switch self {
        case .profile:
            return "Profile"
        case .jobs:
            return "Jobs"
        case .chat:
            return "Chat"
        case .invoice:
            return "Invoice"
        case .customers:
            return "Service Location"
        case .market:
            return "Market"
        case .estimate:
            return "Estimates"
        case .dailyRoute:
            return "Daily Route"
        case .serviceStops:
            return "Service Stops"
        case .routeBuilder:
            return "Route Builder"
        case .routeManagment:
            return "Route Managment"
        case .techRoles:
            return "Tech Roles"
        case .calendar:
            return "Calendar"
        case .companyProfile:
            return "Company Profile"
        case .receipts:
            return "Receipts"
        case .purchases:
            return "Purchases"
        case .databaseItems:
            return "Database Items"
        case .venders:
            return "Venders"
        }
    }
    
    var systemImage: String {
        switch self {
        case .profile:
            return "person"
        case .jobs:
            return "wrench.adjustable"
        case .chat:
            return "message"
        case .invoice:
            return "doc.text"
        case .customers:
            return "house.fill"
        case .market:
            return "globe.americas"
        case .estimate:
            return "dollarsign"
        case .dailyRoute:
            return "exclamationmark.triangle.fill"

        case .serviceStops:
            return "exclamationmark.triangle.fill"

        case .routeBuilder:
            return "exclamationmark.triangle.fill"

        case .routeManagment:
            return "exclamationmark.triangle.fill"

        case .techRoles:
            return "exclamationmark.triangle.fill"

        case .calendar:
            return "exclamationmark.triangle.fill"

        case .companyProfile:
            return "exclamationmark.triangle.fill"

        case .receipts:
            return "exclamationmark.triangle.fill"

        case .purchases:
            return "exclamationmark.triangle.fill"

        case .databaseItems:
            return "exclamationmark.triangle.fill"

        case .venders:
            return "exclamationmark.triangle.fill"

        }
    }
}
