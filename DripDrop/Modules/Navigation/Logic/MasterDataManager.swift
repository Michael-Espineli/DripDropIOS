//f
//  MasterDataManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/30/24.
//

import Foundation
import Combine
import SwiftUI
class MasterDataManager: ObservableObject {
    @Published var selectedCategory: MacCategories? = .businesses //DEVELOPER
    @Published var selectedMobileCategory: MobileCategories? = nil
    @Published var mobileHomeScreen: MobileHomeScreenCategories = .all

    //Login Flow
    @Published var showSignInView:Bool = true
    
    @Published var modifyRoute:Bool = true
    @Published var newRoute:Bool = true
    @Published var reassignRoute:Bool = true
    @Published var reloadBuilderView:Bool? = nil

    //Formatting
    @Published var detailViewWidthMax: Int = 3000
    @Published var detailViewWidthideal: Int = 100
    @Published var detailViewWidthMin: Int = 700
    @Published var columnVisibility: NavigationSplitViewVisibility = .all
    @Published var showPaymentSheet:Bool = false
    @Published var mainScreenDisplayType:MainScreenDisplayType = .compactList
    @Published var tabViewSelection : String = "Dashboard"
    
    
    // User, Role, and Permission Verification
    @Published var user:DBUser? = nil
    @Published var companyUser:CompanyUser? = nil
    @Published var role:Role? = nil
    @Published var allCompanies: [Company] = []
    @Published var currentCompany: Company? = nil

    
    //For Details and List Flow

    //Selected Items
    
    //A
    @Published var selectedActiveRoute: ActiveRoute? = nil
    @Published var selectedActiveRouteList: [ActiveRoute] = []
    @Published var selectedAccountsReceivableInvoice:StripeInvoice? = nil

    //B
    @Published var selectedBuisness: AssociatedBusiness? = nil
    @Published var selectedAccountsPayableInvoice:StripeInvoice? = nil

    //C
    @Published var selectedCompanyUser: CompanyUser? = nil
    @Published var selectedCustomer: Customer? = nil
    @Published var selectedContract: RecurringContract? = nil
    @Published var selectedChat: Chat? = nil
    @Published var selectedCompany1: Company? = nil
    @Published var customerSearchTerm: String? = nil

    //B
    @Published var selectedBodyOfWater: BodyOfWater? = nil
    @Published var selectedBillingTemplate: BillingTemplate? = nil

    //D
    @Published var selectedDate: Date? = nil
    @Published var selectedDays: [String] = []
    @Published var selectedDataBaseItem: DataBaseItem? = nil
    @Published var selectedDosageTemplate: SavedDosageTemplate? = nil

    //E
    @Published var selectedEquipment: Equipment? = nil
    
    //G
    @Published var selectedGenericItem: GenericItem? = nil

    //J
    @Published var selectedJobTemplate: JobTemplate? = nil
    @Published var selectedJob: Job? = nil

    //M
    @Published var selectedMapLocations: [MapLocation] = []
    @Published var selectedMapLocation: MapLocation? = nil
    @Published var selectedManagementView: String? = nil

    //L
    @Published var selectedRecurringLaborContract:ReccuringLaborContract? = nil
    @Published var selectedLaborContract:LaborContract? = nil

    //P
    @Published var selectedPurchases: PurchasedItem? = nil
    @Published var selectedPNLSummary: CustomerMonthlySummary? = nil//DEVELOPER
    @Published var selectedPaymentSheetType:PaymentSheetType? = nil

    //R
    @Published var selectedReport: ReportType? = nil
    @Published var selectedRole:Role? = nil
    @Published var selectedRouteServiceStop: ServiceStop? = nil
    @Published var selectedRoute: RecurringServiceStop? = nil
    @Published var selectedReceipt: Receipt? = nil
    @Published var selectedRepairRequest: RepairRequest? = nil
    @Published var selectedReadingsTemplate: SavedReadingsTemplate? = nil
    @Published var selectedRouteBuilderDay:String? = nil
    @Published var selectedRouteBuilderTech:CompanyUser? = nil
    @Published var selectedRecurringRoute:RecurringRoute? = nil
    //S
    @Published var selectedShoppingListItem:ShoppingListItem? = nil
    @Published var selectedServiceLocation: ServiceLocation? = nil
    @Published var selectedServiceStops: ServiceStop? = nil
    @Published var selectedServiceStopList: [ServiceStop]? = []
    @Published var selectedLocations: [ServiceLocation] = []

    //T
    @Published var selectedTech1: DBUser? = nil
    @Published var selectedToDo:ToDo? = nil
    @Published var selectedTrainingTemplate: TrainingTemplate? = nil
    @Published var selectedTaskGroup: JobTaskGroup? = nil

    
    //V
    @Published var selectedVender: Vender? = nil
    @Published var selectedVehical:Vehical? = nil
//    {
//            didSet {
//                selectedID = selectedWorkOrder?.id
//            }
//        }
    
    @Published var selectedID: String? = nil
    
    var subscriptions = Set<AnyCancellable>()
    init() {
        // clear selection when category changes
        $currentCompany.sink { [weak self] _ in
            //A
            self?.selectedActiveRoute = nil
            self?.selectedActiveRouteList = []
            self?.selectedAccountsReceivableInvoice = nil

            //B
            self?.selectedBuisness = nil
            self?.selectedAccountsPayableInvoice = nil

            //C
            self?.selectedCompanyUser = nil
            self?.selectedCustomer = nil
            self?.selectedContract = nil
            self?.selectedChat = nil
            self?.selectedCategory = nil
            
            //B
            self?.selectedBodyOfWater = nil
            self?.selectedBillingTemplate = nil

            //D
            self?.selectedDate = nil
            self?.selectedDays = []
            self?.selectedDataBaseItem = nil
            self?.selectedDosageTemplate = nil

            //E
            self?.selectedEquipment = nil
            
            //G
            self?.selectedGenericItem = nil

            //J
            self?.selectedJobTemplate = nil
            self?.selectedJob = nil

            //M
            self?.selectedMapLocations = []
            self?.selectedMapLocation = nil
            self?.selectedManagementView = nil

            //L
            self?.selectedRecurringLaborContract = nil

            //P
            self?.selectedPurchases = nil
            self?.selectedPNLSummary = nil//DEVELOPER
            self?.selectedPaymentSheetType = nil

            //R
            self?.selectedReport = nil
            self?.selectedRole = nil
            self?.selectedRouteServiceStop = nil
            self?.selectedRoute = nil
            self?.selectedReceipt = nil
            self?.selectedRepairRequest = nil
            self?.selectedReadingsTemplate = nil
            self?.selectedRouteBuilderDay = nil
            self?.selectedRouteBuilderTech = nil
            self?.selectedRecurringRoute = nil
            //S
            self?.selectedShoppingListItem = nil
            self?.selectedServiceLocation = nil
            self?.selectedServiceStops = nil
            self?.selectedServiceStopList = []
            self?.selectedLocations = []

            //T
            self?.selectedTech1 = nil
            self?.selectedToDo = nil
            self?.selectedTrainingTemplate = nil

            //V
            self?.selectedVender = nil
            self?.selectedVehical = nil
        }
        .store(in: &subscriptions)
         
    }
    func goToSettings() {
        
    }
  
}
enum MainScreenDisplayType:String, CaseIterable {
    case compactList = "Compact"
    case preview = "Preview"
    case fullPreview = "Full Preview"

}
