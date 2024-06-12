//
//  PurchaseListView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 9/7/23.
//

import SwiftUI

struct PurchaseListView: View{
    //VMs
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService
    @StateObject private var purchaseVM = PurchasesViewModel()
    @StateObject private var receiptViewModel = ReceiptViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var techVM = TechViewModel()

    @State private var showEditView : Bool = false
    @State private var showDetailsView : Bool = false
    
    @State private var selected: PurchasedItem.ID?
    @State private var purchasedItems:[PurchasedItem] = []
    @State private var sortOrder = [KeyPathComparator(\PurchasedItem.invoiceNum, order: .reverse)]
    @State private var serviceStopDetail: PurchasedItem? = nil
    
    @State var workOrderTemplate:JobTemplate = JobTemplate(id: "", name: "sum",type: "all")
    
    @State var startViewingDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    
    @State var endViewingDate: Date =  Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    
    @State private var selection: PurchasedItem.ID? = nil
    
    @State var purchaseFilterOption:PurchaseFilterOptions = .all
    @State var purchaseSortOption:PurchaseSortOptions = .purchaseDateFirst
    @State var techIds:[String] = []
    @State var showSummary = false
    
    
    @State var showFilerOptions = false
    @State var showAddNew = false
    @State var showSearch = false
    @State var searchTerm:String = ""
    
    var body: some View{
        ZStack{
            list
            icons
        }
        //Initial Loading of the purchase Items
        .task{
            if let company = masterDataManager.selectedCompany {
                do {
                    try await techVM.getAllCompanyTechs(companyId: company.id)
                    for tech in techVM.techList {
                        techIds.append(tech.id)
                    }
                    try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: techIds)
                    purchasedItems = purchaseVM.purchasedItems

                } catch {
                    print(error)
                    
                }
            }
            
        }
        //Loading new Purchase Items with Change in sorting Options

        .onChange(of: purchaseSortOption, perform: { sort in
            Task{
                if let company = masterDataManager.selectedCompany {
                    do {
                        try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: sort, startDate: startViewingDate, endDate: endViewingDate, techIds: techIds)
                        purchasedItems = purchaseVM.purchasedItems

                    } catch {
                        print(error)
                    }
                    
                }
            }
        })
        //Loading new Purchase Items with Change in Filter Options

        .onChange(of: purchaseFilterOption, perform: { filter in
            Task {
                if let company = masterDataManager.selectedCompany {
                    do {
                        try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: filter, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: techIds)
                        purchasedItems = purchaseVM.purchasedItems

                    } catch {
                        print(error)
                        
                    }
                }
            }
        })
        //Loading new Purchase Items with Change in Start Date
        .onChange(of: startViewingDate) { date in
            Task {
                if let company = masterDataManager.selectedCompany {
                    do {
                        try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: date, endDate: endViewingDate, techIds: techIds)
                        purchasedItems = purchaseVM.purchasedItems

                    } catch {
                        print(error)
                        
                    }
                }
            }
        }
        //Loading new Purchase Items with Change in End Date

        .onChange(of: endViewingDate) { date in
            Task {
                if let company = masterDataManager.selectedCompany {
                    do {
                        try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: date, techIds: techIds)
                        purchasedItems = purchaseVM.purchasedItems

                    } catch {
                        print(error)
                        
                    }
                }
            }
        }
        //Loading New Purchase Items with Change in Tech
        .onChange(of: techIds, perform: { techs in
            Task {
                if let company = masterDataManager.selectedCompany {
                    do {
                        try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: techs)
                        purchasedItems = purchaseVM.purchasedItems

                    } catch {
                        print(error)
                        
                    }
                }
            }
        })
        //Searches through the purchase item list
        .onChange(of: searchTerm){ term in
            if searchTerm == "" {
                purchasedItems = purchaseVM.purchasedItems
            } else {
                purchaseVM.filterPurchaseList(filterTerm: searchTerm, purchasedItems: purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.filteredPurchasedItems
            }
        }

        
        .onChange(of: selection) { selected in
            print("selected Purchase")
            let purchasesObject = purchasedItems.filter{ $0.id == selected }.first
            masterDataManager.selectedPurchases = purchasesObject
            
        }
        .onChange(of: selected) { selected in
            print(selected)
            if selected != nil {
                showEditView = true
            }
        }
        .onChange(of: purchasedItems){ purchasedItemsList in
            purchaseVM.summaryOfPurchasedItems(purchasedItems: purchasedItemsList)
        }

    }
    
}
extension PurchaseListView {
    var list: some View{
        VStack{
        
            List(selection:$masterDataManager.selectedID){
                ForEach(purchasedItems) { item in
                    if UIDevice.isIPhone {
                        NavigationLink(value: Route.purchase(purchasedItem: item,dataService: dataService), label: {
                            PurchasesCardView(item: item)
                        })
                    } else {
                        Button(action: {
                            masterDataManager.selectedPurchases = item
                        
                               }, label: {
                            PurchasesCardView(item: item)
                        })
                    }
                }
            }
            .textSelection(.enabled)
                     .refreshable {
                         if let company = masterDataManager.selectedCompany {
                             do {
                                 try await techVM.getAllCompanyTechs(companyId: company.id)
                                 for tech in techVM.techList {
                                     techIds.append(tech.id)
                                 }
                                 try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: techIds)
                                 purchasedItems = purchaseVM.purchasedItems

                             } catch {
                                 print(error)
                                 
                             }
                         }
                     }
        }

    }
    var icons: some View{
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack(alignment: .trailing,spacing: 20){
                    Button(action: {
                        showFilerOptions.toggle()
                    }, label: {
                        
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.orange)
                            .background(
                                Circle()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.white)
                                )
                    })
                    .padding(.trailing,30)

                    .sheet(isPresented: $showFilerOptions, content: {
                        ZStack{
                            Color.listColor.ignoresSafeArea()
                            VStack{
                                HStack{
                                    Spacer()
                                    Text("Filters")
                                        .font(.title)
                                    Spacer()
                                    Button(action: {
                                        showFilerOptions = false
                                    }, label: {
                                        Text("Dismiss")
                                            .foregroundColor(Color.red)
                                    })
                                }
                                HStack{
                                    Text("Start Date: ")
                                    DatePicker(selection: $startViewingDate, displayedComponents: .date) {
                                    }
                                }
                                HStack{
                                    Text("End Date: ")
                                    
                                    DatePicker(selection: $endViewingDate, displayedComponents: .date) {
                                    }
                                }
                                   
                                    
                                HStack{
                                    Text("Sort: ")
                                    Picker("Sort: ", selection: $purchaseSortOption) {
                                        ForEach(PurchaseSortOptions.allCases,id:\.self) {
                                            Text($0.display()).tag($0)
                                        }
                                    }
                                    Spacer()
                                }
                                HStack{
                                    Text("Filter: ")
                                    Picker("Filter:", selection: $purchaseFilterOption) {
                                        ForEach(PurchaseFilterOptions.allCases,id:\.self) {
                                            Text($0.display()).tag($0)
                                        }
                                    }
                                    Spacer()
                                }
                                HStack{
                                    Text("Techs: ")
                                    Menu("Techs") {
                                        Button(action: {
                                            print("All Selected")
                                            for tech in techVM.techList {
                                                techIds.append(tech.id)
                                            }

                                        }, label: {
                                            Text("All \(techIds.count == techVM.techList.count ? "✓" : "")")
                                        })
                                        
                                        ForEach(techVM.techList) { tech in
                                            Button(action: {
                                                if techIds.contains(tech.id) {
                                                    techIds.removeAll(where: {$0 == tech.id})
                                                    print("Removed \((tech.firstName ?? "") + " " + (tech.lastName ?? ""))")
                                                } else {
                                                    print("Added \((tech.firstName ?? "") + " " + (tech.lastName ?? ""))")

                                                    techIds.append(tech.id)
                                                }
                                            }, label: {
                                                Text("\(tech.firstName ?? "") \(tech.lastName ?? "") \(techIds.contains(tech.id) ? "✓" : "")")
                                            })
                                        }
                                        Button(action: {
                                            techIds = []
                                        }, label: {
                                            Text("Clear \(techIds == [] ? "✓" : "")")
                                        })
                                    }
                                    Spacer()
                                }
                                Spacer()
                            }
                            .padding(10)
                        }
                        
                    })
                    
                     NavigationLink{
                        AddNewReceipt()

                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.green)
                            .background(
                                Circle()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.white)
                                )
                    }
                    .padding(.trailing,75)

                    Button(action: {
                        showSearch.toggle()
                    }, label: {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.blue)
                            .background(
                                Circle()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.white)
                                )
                    })
                    .padding(.trailing,100)

                }
                .padding(.trailing,20)

//                .background(Color.pink)
            }
            if showSearch {
                    HStack{
                     
                        TextField(
                            "Search...",
                            text: $searchTerm
                        )
                        .padding()
                        .background(Color.gray)
                        Button(action: {
                            searchTerm = ""
                        }, label: {
                            Image(systemName: "xmark")
                        })
                    }
                    .cornerRadius(10)
                
            }
        }

    }
}
