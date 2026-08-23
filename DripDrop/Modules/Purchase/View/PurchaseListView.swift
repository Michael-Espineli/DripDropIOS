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
        ZStack(alignment: .bottomTrailing) {
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

            if UIDevice.isIPhone {
                purchaseActionDock
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
            if !UIDevice.isIPhone {
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

    var purchaseActionDock: some View {
        VStack(spacing: 10) {
            Button {
                showFilerOptions.toggle()
            } label: {
                mobileDockIcon(
                    systemName: "slider.horizontal.3",
                    tint: .poolBlue,
                    isSelected: showFilerOptions
                )
            }
            .buttonStyle(.plain)

            Button {
                Task { await reloadPurchases() }
            } label: {
                mobileDockIcon(
                    systemName: "arrow.clockwise",
                    tint: .orange,
                    isSelected: false
                )
            }
            .buttonStyle(.plain)

            Button {
                showAddNewPurchase.toggle()
            } label: {
                mobileDockIcon(
                    systemName: "plus",
                    tint: .poolGreen,
                    isSelected: false
                )
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    showSearch.toggle()
                }
            } label: {
                mobileDockIcon(
                    systemName: "magnifyingglass",
                    tint: .poolBlue,
                    isSelected: showSearch
                )
            }
            .buttonStyle(.plain)
        }
        .padding(7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.trailing, 14)
        .padding(.bottom, 18)
    }

    private func mobileDockIcon(
        systemName: String,
        tint: Color,
        isSelected: Bool
    ) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : tint)
            .frame(width: 40, height: 40)
            .background(
                isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.13)),
                in: Circle()
            )
    }

    var filterSheet: some View {
        DripDropFilterSheet(
            title: "Purchase Filters",
            isPresented: $showFilerOptions,
            isResetDisabled: purchaseActiveFilterCount == 0,
            onReset: resetPurchaseFilters
        ) {
            DripDropFilterSummaryCard(
                title: "\(purchasedItems.count) purchased items",
                subtitle: "\(purchaseFilterOption.display()) from \(shortDate(date: startViewingDate)) to \(shortDate(date: endViewingDate)).",
                systemImage: "cart.fill",
                tint: .poolGreen
            )

            DripDropFilterSection(
                title: "Date Range",
                systemImage: "calendar",
                tint: .poolBlue
            ) {
                DripDropFilterRow(
                    title: "Start",
                    subtitle: shortDate(date: startViewingDate),
                    systemImage: "calendar.badge.minus",
                    tint: .poolBlue
                ) {
                    DatePicker("Start Date", selection: $startViewingDate, displayedComponents: .date)
                        .labelsHidden()
                }

                DripDropFilterRow(
                    title: "End",
                    subtitle: shortDate(date: endViewingDate),
                    systemImage: "calendar.badge.plus",
                    tint: .poolBlue
                ) {
                    DatePicker("End Date", selection: $endViewingDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }

            DripDropFilterSection(
                title: "Purchased Items",
                systemImage: "line.3.horizontal.decrease.circle",
                tint: .orange
            ) {
                DripDropFilterRow(
                    title: "Sort",
                    subtitle: "List order",
                    systemImage: "arrow.up.arrow.down",
                    tint: .poolBlue
                ) {
                    Picker("Sort", selection: $purchaseSortOption) {
                        ForEach(PurchaseSortOptions.allCases, id: \.self) { option in
                            Text(option.display()).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                DripDropFilterRow(
                    title: "Filter",
                    subtitle: "Billing state",
                    systemImage: "checkmark.seal",
                    tint: .orange
                ) {
                    Picker("Filter", selection: $purchaseFilterOption) {
                        ForEach(PurchaseFilterOptions.allCases, id: \.self) { option in
                            Text(option.display()).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }

            DripDropFilterSection(
                title: "Techs",
                systemImage: "person.2",
                tint: .poolGreen
            ) {
                DripDropFilterRow(
                    title: "Assigned Techs",
                    subtitle: purchaseTechMenuTitle,
                    systemImage: "person.crop.circle.badge.checkmark",
                    tint: .poolGreen
                ) {
                    Menu {
                        Button {
                            techIds = purchaseVM.techList.map(\.userId)
                        } label: {
                            Label("All techs", systemImage: allPurchaseTechsSelected ? "checkmark" : "circle")
                        }

                        ForEach(purchaseVM.techList) { tech in
                            Button {
                                togglePurchaseTech(tech.userId)
                            } label: {
                                Label(tech.userName ?? "", systemImage: techIds.contains(tech.userId) ? "checkmark" : "circle")
                            }
                        }

                        Button(role: .destructive) {
                            techIds = []
                        } label: {
                            Label("Clear techs", systemImage: techIds.isEmpty ? "checkmark" : "xmark")
                        }
                    } label: {
                        DripDropFilterMenuLabel(title: purchaseTechMenuTitle, tint: .poolGreen)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    var defaultPurchaseStartDate: Date {
        Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    }

    var defaultPurchaseEndDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    var purchaseActiveFilterCount: Int {
        var count = 0

        if !Calendar.current.isDate(startViewingDate, inSameDayAs: defaultPurchaseStartDate) { count += 1 }
        if !Calendar.current.isDate(endViewingDate, inSameDayAs: defaultPurchaseEndDate) { count += 1 }
        if purchaseSortOption != .purchaseDateFirst { count += 1 }
        if purchaseFilterOption != .all { count += 1 }
        if !allPurchaseTechsSelected { count += 1 }

        return count
    }

    var allPurchaseTechsSelected: Bool {
        let allTechIds = Set(purchaseVM.techList.map(\.userId))

        guard !allTechIds.isEmpty else {
            return techIds.isEmpty
        }

        return Set(techIds) == allTechIds
    }

    var purchaseTechMenuTitle: String {
        if techIds.isEmpty { return "None selected" }
        if allPurchaseTechsSelected { return "All techs" }
        if techIds.count == 1 {
            guard let firstTechId = techIds.first else { return "1 tech" }

            let techName = purchaseVM.techList.first(where: { $0.userId == firstTechId })?.userName
            return techName ?? "1 tech"
        }
        return "\(Set(techIds).count) selected"
    }

    func togglePurchaseTech(_ userId: String) {
        if techIds.contains(userId) {
            techIds.removeAll(where: { $0 == userId })
        } else {
            techIds.append(userId)
        }
    }

    func resetPurchaseFilters() {
        startViewingDate = defaultPurchaseStartDate
        endViewingDate = defaultPurchaseEndDate
        purchaseFilterOption = .all
        purchaseSortOption = .purchaseDateFirst
        techIds = purchaseVM.techList.map(\.userId)
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
                        filterSheet
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
