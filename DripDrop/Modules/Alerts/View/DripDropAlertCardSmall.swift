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
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .managementTables:
                            print(".managementTables")
                        case .profile:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .dashBoard:
                            print("dashBoard Does Not Need Item")
                        case .dailyDisplay:
                            print("dailyDisplay Does Not Need Item")
                        case .routeBuilder:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .management:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .pnl:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .companyProfile:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .reports:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .readingsAndDosages:
                            print("routeBuilder Need more complex Logic")
                        case .calendar:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .maps:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .companyAlerts:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .personalAlerts:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .marketPlace:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .jobPosting:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .feed:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .companyRouteOverView:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                 
                        case .settings:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
               
                        case .alerts:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
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
                            print("labor Contract - \(String(describing: VM.laborContract?.id))")
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
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .emailConfirguration:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .companyInfo:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .manageSubscriptions:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
                        case .stripeConfiguration:
                            print(" please build out")
            #warning("Update 2.5   please build out")
                            
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
            let companyId = dripDropAlert.relatedEntity?.companyId
                ?? dripDropAlert.share?.companyId
                ?? masterDataManager.currentCompany?.id
            if let companyId, !companyId.isEmpty {
                do {
                    try await VM.getAlertDestination(companyId: companyId, alert: dripDropAlert)
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
            VStack(alignment: .leading, spacing: 6){
                Text("\(dripDropAlert.name)")
                    .fontWeight(.bold)
                Text("\(dripDropAlert.description)")
                    .fontWeight(.light)
                HStack(spacing: 8) {
                    if let status = dripDropAlert.status, !status.isEmpty {
                        Text(status.capitalized)
                    }
                    if let type = dripDropAlert.relatedEntity?.type ?? dripDropAlert.share?.type, !type.isEmpty {
                        Text(type)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .modifier(ListButtonModifier())
        
    }
}
