//
//  DripDropAlertCard.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/8/24.
//

import SwiftUI

struct DripDropAlertCardSmall: View {
    init(dataService:any ProductionDataServiceProtocol,alert:DripDropAlert) {
        _VM = StateObject(wrappedValue: CompanyAlertViewModel(dataService: dataService))
        _dripDropAlert = State(wrappedValue: alert)
    }
    
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject var VM : CompanyAlertViewModel

    @State var dripDropAlert:DripDropAlert
    
    var body: some View {
        Group{
            if UIDevice.isIPhone {
                NavigationLink(value: VM.route, label: {
                    card
                })
                .disabled(VM.isLoading)
                .opacity(VM.isLoading ? 0.6 : 1)
            } else {
                Button(action: {
                    if dripDropAlert.itemId != "" {
                        switch dripDropAlert.category {
                        case .taskGroups:
                            Text("Task Groups")
                        case .managementTables:
                            print(".managementTables")
                        case .profile:
                            print("reports Not Built Out Yet")
                        case .dashBoard:
                            print("dashBoard Does Not Need Item")
                        case .dailyDisplay:
                            print("dailyDisplay Does Not Need Item")
                        case .routeBuilder:
                            print("routeBuilder Need more complex Logic")
                        case .management:
                            print("Developer Make function for getting management by Id")
                        case .pnl:
                            print("PNL Not Built Out Yet")
                        case .companyProfile:
                            print("reports Not Built Out Yet")
                        case .reports:
                            print("reports Not Built Out Yet")
                        case .readingsAndDosages:
                            print("routeBuilder Need more complex Logic")
                        case .calendar:
                            print("Calendar Not Built Out Yet")
                        case .maps:
                            print("maps Not Built Out Yet")
                        case .companyAlerts:
                            print("companyAlerts Not Built Out Yet")
                        case .personalAlerts:
                            print("personalAlerts Not Built Out Yet")
                        case .marketPlace:
                            print("MarketPlace Not Built Out Yet")
                        case .jobPosting:
                            print("JobPosting Not Built Out Yet")
                        case .feed:
                            print("Feed Not Built Out Yet")
                        case .companyRouteOverView:
                            print("reports Not Built Out Yet")
                 
                        case .settings:
                            print("Settings Not Built Out Yet")
               
                        case .alerts:
                            print("alerts Not Built Out Yet")
                            //A
                        case .accountsPayable:
                            masterDataManager.selectedAccountsPayableInvoice = VM.stripeInvoice
                        case .accountsReceivable:
                            masterDataManager.selectedAccountsReceivableInvoice = VM.stripeInvoice
                            
                            //B
                        case .businesses:
                            masterDataManager.selectedBuisness = VM.associatedBusiness
                            
                            //C
                        case .customers:
                            masterDataManager.selectedCustomer = VM.customer
                        case .companyUser:
                            masterDataManager.selectedCompanyUser = VM.companyUser
                        case .contract:
                            masterDataManager.selectedContract = VM.contract
                        case .chat:
                            masterDataManager.selectedChat = VM.chat
                        case .contracts:
                            masterDataManager.selectedContract = VM.contract
                            
                            //D
                        case .databaseItems:
                            masterDataManager.selectedDataBaseItem = VM.dataBaseItem
                            
                            //E
                        case .equipment:
                            masterDataManager.selectedEquipment = VM.equipment
                            
                            //F
                        case .fleet:
                            masterDataManager.selectedVehical = VM.vehical
                            
                            //G
                        case .genericItems:
                            masterDataManager.selectedGenericItem = VM.genericItem
                            
                            //J
                        case .jobs:
                            masterDataManager.selectedJob = VM.job
                        case .jobTemplates:
                            masterDataManager.selectedJobTemplate = VM.jobTemplate
                            
                            //L
                        case .receivedLaborContracts:
                            print("labor Contract - \(VM.laborContract?.id)")
                            masterDataManager.selectedRecurringLaborContract = VM.laborContract
                            
                            //S
                        case .shoppingList:
                            masterDataManager.selectedShoppingListItem = VM.shoppingListItem
                        case .serviceStops:
                            masterDataManager.selectedServiceStops = VM.serviceStop
                            
                            //P
                        case .purchases:
                            masterDataManager.selectedPurchases = VM.purchase
                            
                            //R
                        case .repairRequest:
                            masterDataManager.selectedRepairRequest = VM.repairRequest
                        case .receipts:
                            masterDataManager.selectedReceipt = VM.receipt
                            
                            //V
                        case .vender:
                            masterDataManager.selectedVender = VM.vender
                            
                            //U
                        case .users:
                            masterDataManager.selectedCompanyUser = VM.companyUser
                        case .userRoles:
                            masterDataManager.selectedRole = VM.role
                        case .externalRoutesOverview:
                            print("externalRoutesOverview Not Built Out Yet")

                        case .sentLaborContracts:
                            print("Developer")
                        }
                    }
                    print("Category - \(dripDropAlert.category)")
                    masterDataManager.selectedCategory = dripDropAlert.category

                }, label: {
                    card
                })
                .disabled(VM.isLoading)
                .opacity(VM.isLoading ? 0.6 : 1)
            }
        }
        .task{
            if let selectedCompany = masterDataManager.currentCompany {
                do {
                    try await VM.getAlertDestination(companyId: selectedCompany.id, alert: dripDropAlert)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
    }
}
//
//#Preview {
//    DripDropAlertCardSmall(dataService: MockDataService())
//}
extension DripDropAlertCardSmall {
    var card: some View {
            VStack{
                Text("\(dripDropAlert.name)")
                    .fontWeight(.bold)
                Text("\(dripDropAlert.description)")
                    .fontWeight(.light)
            }
            .frame(maxWidth: .infinity)
            .modifier(ListButtonModifier())
        
    }
}
