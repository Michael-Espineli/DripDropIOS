//
//  PurchaseListView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 9/7/23.
//

import SwiftUI

struct PurchaseListView: View{
    //VMs
    init(dataService:any ProductionDataServiceProtocol){
        _purchaseVM = StateObject(wrappedValue: PurchasesViewModel(dataService: dataService))
        
    }
    @StateObject var purchaseVM : PurchasesViewModel
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject private var receiptViewModel = ReceiptViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel(dataService: ProductionDataService())
    @StateObject private var techVM = TechViewModel()
    
    @State private var showEditView : Bool = false
    @State private var showDetailsView : Bool = false
    
    @State private var selected: PurchasedItem.ID?
    @State private var purchasedItems:[PurchasedItem] = []
    @State private var sortOrder = [KeyPathComparator(\PurchasedItem.invoiceNum, order: .reverse)]
    @State private var serviceStopDetail: PurchasedItem? = nil
    
    @State var workOrderTemplate:JobTemplate = JobTemplate(companyId: "", name: "", createdByUserId: "")
    
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
    @State var showAddNewPurchase = false
    
    var body: some View{
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                listHeader

                if showSearch {
                    searchBar
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }

                ScrollView {
                    LazyVStack(spacing: 10) {
                        if purchasedItems.isEmpty {
                            ContentUnavailableView(
                                "No Purchases",
                                systemImage: "cart",
                                description: Text("Adjust filters or reload purchases.")
                            )
                            .padding(.top, 60)
                        } else {
                            ForEach(purchasedItems) { item in
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.purchase(purchasedItem: item,dataService: dataService), label: {
                                        PurchasesCardView(item: item)
                                    })
                                    .buttonStyle(.plain)
                                } else {
                                    Button(action: {
                                        masterDataManager.selectedPurchases = item
                                    }, label: {
                                        PurchasesCardView(item: item)
                                    })
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await reloadPurchases()
                }
            }
        }
        //Initial Loading of the purchase Items
        .task{
            if let company = masterDataManager.currentCompany {
                do {
                    try await purchaseVM.getTechs(companyId: company.id)
                    print("Received \(purchaseVM.techList.count) techs \(purchaseVM.techList)")
                    for tech in purchaseVM.techList {
                        techIds.append(tech.userId)
                    }
                    try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: techIds)
                    purchasedItems = purchaseVM.purchasedItems
                } catch {
                    print(error)
                    
                }
            }
        }
        /*
         //Loading new Purchase Items with Change in sorting Options
         
         .onChange(of: purchaseSortOption, perform: { sort in
         Task{
         if let company = masterDataManager.currentCompany {
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
         if let company = masterDataManager.currentCompany {
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
         if let company = masterDataManager.currentCompany {
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
         if let company = masterDataManager.currentCompany {
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
         if let company = masterDataManager.currentCompany {
         do {
         try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: techs)
         purchasedItems = purchaseVM.purchasedItems
         
         } catch {
         print(error)
         
         }
         }
         }
         })
         */
        //Searches through the purchase item list
        .onChange(of: searchTerm){ term in
            if searchTerm == "" {
                purchasedItems = purchaseVM.purchasedItems
            } else {
                purchaseVM.filterPurchaseList(filterTerm: searchTerm, purchasedItems: purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.filteredPurchasedItems
            }
        }
        
        //
        //        .onChange(of: selection) { selected in
        //            print("selected Purchase")
        //            let purchasesObject = purchasedItems.filter{ $0.id == selected }.first
        //            masterDataManager.selectedPurchases = purchasesObject
        //
        //        }
        //        .onChange(of: selected) { selected in
        //            print(selected)
        //            if selected != nil {
        //                showEditView = true
        //            }
        //        }
        .onChange(of: purchasedItems){ purchasedItemsList in
            purchaseVM.summaryOfPurchasedItems(purchasedItems: purchasedItemsList)
        }
        .sheet(isPresented: $showFilerOptions, onDismiss: {
            Task { await reloadPurchases() }
        }, content: {
            filterSheet
        })
        .sheet(isPresented: $showAddNewPurchase, onDismiss: {
            Task { await reloadPurchases() }
        }, content: {
            AddNewReceipt(dataService: dataService)
        })
        .toolbar{
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showSearch.toggle()
                } label: {
                    Image(systemName: "magnifyingglass")
                }

                Button {
                    showFilerOptions.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }

                Button {
                    Task { await reloadPurchases() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

                Button {
                    showAddNewPurchase.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

extension PurchaseListView {
    var listHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Purchased Items")
                        .font(.title2.weight(.bold))
                    Text("\(purchasedItems.count) items from \(shortDate(date: startViewingDate)) to \(shortDate(date: endViewingDate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let total = purchaseVM.totalSpentOnBillables {
                    Text(total, format: .currency(code: "USD"))
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }
            }

            HStack(spacing: 8) {
                filterPill(purchaseFilterOption.display(), systemImage: "line.3.horizontal.decrease.circle")
                filterPill(purchaseSortOption.display(), systemImage: "arrow.up.arrow.down")
                filterPill("\(techIds.count) techs", systemImage: "person.2")
            }
        }
        .padding(14)
    }

    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search purchases...", text: $searchTerm)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchTerm.isEmpty {
                Button {
                    searchTerm = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func filterPill(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
    }

    var filterSheet: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("Start Date", selection: $startViewingDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endViewingDate, displayedComponents: .date)
                }

                Section("Sort & Filter") {
                    Picker("Sort", selection: $purchaseSortOption) {
                        ForEach(PurchaseSortOptions.allCases,id:\.self) {
                            Text($0.display()).tag($0)
                        }
                    }

                    Picker("Filter", selection: $purchaseFilterOption) {
                        ForEach(PurchaseFilterOptions.allCases,id:\.self) {
                            Text($0.display()).tag($0)
                        }
                    }
                }

                Section("Techs") {
                    Button("Select All") {
                        techIds = purchaseVM.techList.map(\.userId)
                    }

                    ForEach(purchaseVM.techList) { tech in
                        Button {
                            if techIds.contains(tech.userId) {
                                techIds.removeAll(where: {$0 == tech.userId})
                            } else {
                                techIds.append(tech.userId)
                            }
                        } label: {
                            HStack {
                                Text(tech.userName ?? "")
                                Spacer()
                                if techIds.contains(tech.userId) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Button("Clear Techs", role: .destructive) {
                        techIds = []
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showFilerOptions = false
                    }
                }
            }
        }
    }

    @MainActor
    func reloadPurchases() async {
        guard let company = masterDataManager.currentCompany else { return }

        do {
            try await techVM.getAllCompanyTechs(companyId: company.id)
            if techIds.isEmpty {
                techIds = techVM.techList.map(\.id)
            }
            try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: Array(Set(techIds)))
            purchasedItems = purchaseVM.purchasedItems
        } catch {
            print(error)
        }
    }

    var list: some View{
        VStack{
            if showSearch && !UIDevice.isIPhone{
                HStack{
                    TextField(
                        "Search...",
                        text: $searchTerm
                    )
                    .modifier(TextFieldModifier())
                    .modifier(OutLineButtonModifier())
                    
                    Button(action: {
                        searchTerm = ""
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
                .modifier(ListButtonModifier())
                .padding(8)
            }
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
//            .refreshable {
//                if let company = masterDataManager.currentCompany {
//                    do {
//                        try await techVM.getAllCompanyTechs(companyId: company.id)
//                        for tech in techVM.techList {
//                            techIds.append(tech.id)
//                        }
//                        try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: techIds)
//                        purchasedItems = purchaseVM.purchasedItems
//                        
//                    } catch {
//                        print(error)
//                        
//                    }
//                }
//            }
        }
        
    }
    var icons: some View{
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack(alignment: .trailing,spacing: 20){
                    if UIDevice.isIPhone {
                        NavigationLink{
                            AddNewReceipt(dataService: dataService)
                            
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
                        .padding(.trailing,30)
                        .sheet(isPresented: $showAddNewPurchase,onDismiss: {
                            Task{
                                if let company = masterDataManager.currentCompany {
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
                        }, content: {
                            AddNewReceipt(dataService: dataService)
                        })
                    } else {
                        Button(action: {
                            showAddNewPurchase.toggle()
                        }, label: {
                            
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.green)
                                .background(
                                    Circle()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(Color.white)
                                )
                        })
                        .padding(.trailing,30)
                        .sheet(isPresented: $showAddNewPurchase, onDismiss: {
                            Task{
                                if let company = masterDataManager.currentCompany {
                                    do {
                                        try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: techIds)
                                        purchasedItems = purchaseVM.purchasedItems
                                        
                                    } catch {
                                        print(error)
                                    }
                                    
                                }
                            }
                        }, content: {
                            AddNewReceipt(dataService: dataService)
                        })
                    }
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
                    .sheet(isPresented: $showFilerOptions,onDismiss: {
                        Task{
                            if let company = masterDataManager.currentCompany {
                                do {
                                    try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: techIds)
                                    purchasedItems = purchaseVM.purchasedItems
                                    
                                } catch {
                                    print(error)
                                }
                                
                            }
                        }
                    }, content: {
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
                                        Image(systemName: "xmark")
                                            .modifier(DismissButtonModifier())
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
                                            for tech in purchaseVM.techList {
                                                techIds.append(tech.userId)
                                            }
                                            
                                        }, label: {
                                            Text("All \(techIds.count == purchaseVM.techList.count ? "✓" : "")")
                                        })
                                        
                                        ForEach(purchaseVM.techList) { tech in
                                            Button(action: {
                                                if techIds.contains(tech.userId) {
                                                    techIds.removeAll(where: {$0 == tech.userId})
                                                    print("Removed \((tech.userName ?? ""))")
                                                } else {
                                                    print("Added \((tech.userName ?? ""))")
                                                    
                                                    techIds.append(tech.userId)
                                                }
                                            }, label: {
                                                Text("\(tech.userName ?? "") \(techIds.contains(tech.userId) ? "✓" : "")")
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
                    .padding(.trailing,30)
                }
                .padding(.trailing,20)
                .padding(.bottom,20)
                
                //                .background(Color.pink)
            }
            if showSearch && UIDevice.isIPhone{
                HStack{
                    
                    TextField(
                        "Search...",
                        text: $searchTerm
                    )
                    
                    Button(action: {
                        searchTerm = ""
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
                .modifier(SearchTextFieldModifier())
                .padding(8)
                
            }
        }
        
    }
}
