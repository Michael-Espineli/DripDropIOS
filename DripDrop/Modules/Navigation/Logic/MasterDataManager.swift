//
//  MasterDataManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/30/24.
//

import Foundation
import Combine
import SwiftUI
class MasterDataManager: ObservableObject {
    
    @Published var detailViewWidthMax: Int = 3000
    @Published var detailViewWidthideal: Int = 100
    
    @Published var detailViewWidthMin: Int = 700
    
    @Published var columnVisibility: NavigationSplitViewVisibility = .all
    ///Route Builder
    @Published var routeBuilderDay:String? = nil
    @Published var routeBuilderTech:CompanyUser? = nil
    @Published var reloadBuilderView:Bool? = nil
    //    @Published var selectedRandom: String? = nil
    @Published var user:DBUser? = nil
    @Published var companyUser:CompanyUser? = nil
    @Published var role:Role? = nil
    
    @Published var showSignInView:Bool = true
    @Published var modifyRoute:Bool = true
    @Published var newRoute:Bool = true
    @Published var reassignRoute:Bool = true
    @Published var recurringRoute:RecurringRoute? = nil
    @Published var vehical:Vehical? = nil
    
    @Published var accountsPayableInvoice:StripeInvoice? = nil
    @Published var accountsReceivableInvoice:StripeInvoice? = nil
    @Published var showPaymentSheet:Bool = false
    @Published var paymentSheetType:PaymentSheetType? = nil


    @Published var selectedShoppingListItem:ShoppingListItem? = nil
    @Published var selectedToDo:ToDo? = nil
    
    @Published var selectedCategory: MacCategories? = .dashBoard //DEVELOPER
    @Published var selectedMobileCategory: MobileCategories? = nil
    @Published var selectedReport: ReportType? = nil

    
    @Published var selectedDate: Date? = nil
    
    @Published var selectedTech1: DBUser? = nil
    @Published var selectedCompany: Company? = nil
    @Published var allCompanies: [Company] = []

    @Published var selectedDays: [String] = []
    
    @Published var selectedCustomer: Customer? = nil{
        didSet {
            selectedID = selectedCustomer?.id
        }
    }
    @Published var selectedServiceLocation: ServiceLocation? = nil
    @Published var selectedBodyOfWater: BodyOfWater? = nil
    @Published var selectedEquipment: Equipment? = nil

    @Published var selectedServiceStops: ServiceStop? = nil {
        didSet {
            selectedID = selectedServiceStops?.id
        }
    }
    @Published var selectedRouteServiceStop: ServiceStop? = nil {
        didSet {
            selectedID = selectedServiceStops?.id
        }
    }
    @Published var selectedServiceStopList: [ServiceStop]? = []
    
    @Published var selectedRoute: RecurringServiceStop? = nil{
        didSet {
            selectedID = selectedRoute?.id
        }
    }
    @Published var selectedLocations: [ServiceLocation] = []
    @Published var selectedMapLocations: [MapLocation] = []
    @Published var selectedMapLocation: MapLocation? = nil{
        didSet {
            selectedID = selectedMapLocation?.id
        }
    }
    @Published var selectedReceipt: Receipt? = nil{
        didSet {
            selectedID = selectedReceipt?.id
        }
    }
    @Published var selectedPurchases: PurchasedItem? = nil{
        didSet {
            selectedID = selectedPurchases?.id
        }
    }
    @Published var selectedContract: Contract? = nil{
        didSet {
            selectedID = selectedPurchases?.id
        }
    }
    @Published var selectedDataBaseItem: DataBaseItem? = nil{
        didSet {
            selectedID = selectedDataBaseItem?.id
        }
    }
    @Published var selectedGenericItem: GenericItem? = nil{
        didSet {
            selectedID = selectedGenericItem?.id
        }
    }
    @Published var selectedStore: Vender? = nil{
        didSet {
            selectedID = selectedStore?.id
        }
    }
    @Published var selectedWorkOrder: Job? = nil{
        didSet {
            selectedID = selectedWorkOrder?.id
        }
    }
    @Published var selectedActiveRoute: ActiveRoute? = nil{
        didSet {
            selectedID = selectedWorkOrder?.id
        }
    }
    @Published var selectedActiveRouteList: [ActiveRoute] = []

    @Published var selectedManagementView: String? = nil
    
    @Published var selectedPNLSummary: CustomerMonthlySummary? = nil{
        didSet {
            selectedID = selectedPNLSummary?.id
        }
    }
    @Published var selectedChat: Chat? = nil{
        didSet {
            selectedID = selectedChat?.id
        }
    }
    @Published var selectedRepairRequest: RepairRequest? = nil{
        didSet {
            selectedID = selectedRepairRequest?.id
        }
    }
    @Published var selectedWorkOrderTemplate: JobTemplate? = nil{
        didSet {
            selectedID = selectedWorkOrderTemplate?.id
        }
    }
    @Published var selectedReadingsTemplate: ReadingsTemplate? = nil{
        didSet {
            selectedID = selectedReadingsTemplate?.id
        }
    }
    @Published var selectedDosageTemplate: DosageTemplate? = nil{
        didSet {
            selectedID = selectedDosageTemplate?.id
        }
    }
    @Published var selectedTrainingTemplate: TrainingTemplate? = nil{
        didSet {
            selectedID = selectedTrainingTemplate?.id
        }
    }
    @Published var selectedBillingTemplate: BillingTemplate? = nil{
        didSet {
            selectedID = selectedBillingTemplate?.id
        }
    }
    @Published var selectedID: String? = nil
    
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        /*
        // clear selection when category changes
        $selectedCategory.sink { [weak self] _ in
            self?.selectedDate = nil
            self?.selectedTech1 = nil
            self?.selectedDays = []
            self?.selectedCustomer = nil
            self?.selectedServiceStops = nil
            self?.selectedServiceStopList = []
            self?.selectedRoute = nil
            self?.selectedLocations = []
            self?.selectedMapLocations = []
            self?.selectedMapLocation = nil
            self?.selectedReceipt = nil
            self?.selectedPurchases = nil
            self?.selectedDataBaseItem = nil
            self?.selectedStore = nil
            self?.selectedWorkOrder = nil
            self?.selectedWorkOrderTemplate = nil
            self?.selectedReadingsTemplate = nil
            self?.selectedDosageTemplate = nil
            self?.selectedTrainingTemplate = nil
            self?.selectedBillingTemplate = nil
            
            
        }
        .store(in: &subscriptions)
         */
    }
    
    func goToSettings() {
        
    }
  
}
