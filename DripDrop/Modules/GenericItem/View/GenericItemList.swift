//
//  GenericItemList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/27/24.
//

import SwiftUI

struct GenericItemList: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var genericItemVM : GenericItemViewModel
    init(dataService:any ProductionDataServiceProtocol){
        _genericItemVM = StateObject(wrappedValue: GenericItemViewModel(dataService: dataService))
    }
    @State var searchTerm:String = ""
    @State var showSearch:Bool = false
    @State var showFilter:Bool = false
    @State private var selectedCategory: String? = nil

    var body: some View {
        ZStack{
            list
            icons
        }
        .navigationTitle("Product Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackground()
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await genericItemVM.getAllGenericItems(companyId: company.id)
                } catch {
                    print("Error Getting Product Catalog")
                }
            }
        }
    }
}

extension GenericItemList {
    var list: some View {
        VStack(spacing: 0){
            List{
                ForEach(displayedGenericItems) { item in
                    if UIDevice.isIPhone {
                        
                        NavigationLink(value: Route.toDoDetail(dataService: dataService), label: {
                            GenericItemCardView(genericItem: item)
                            
                        })
                    } else {
                        Button(action: {
                            masterDataManager.selectedGenericItem = item
                            masterDataManager.selectedID = item.id
                        }, label: {
                            GenericItemCardView(genericItem: item)
                        })
                    }
                }
            }
        }
    }
    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {
                        showFilter.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "slider.horizontal.3")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(Color.white)
                                )
                        }
                        
                        
                    })
                    .padding(10)
                    .sheet(isPresented: $showFilter, content: {
                        genericItemFilterSheet
                    })
                    Button(action: {
                        
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.green)
                        }
                    })
                    
                    Button(action: {
                        showSearch.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.blue)
                        }
                    })
                    .padding(10)
                    
                }
            }
            if showSearch {
                HStack{
                    TextField(
                        "Search",
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
    
    private var genericItemFilterSheet: some View {
        DripDropFilterSheet(
            title: "Product Filters",
            isPresented: $showFilter,
            isResetDisabled: selectedCategory == nil,
            onReset: resetGenericFilters
        ) {
            DripDropFilterSummaryCard(
                title: "\(displayedGenericItems.count) products",
                subtitle: selectedCategory ?? "All categories",
                systemImage: "shippingbox.fill",
                tint: .accentColor
            )

            DripDropFilterSection(
                title: "Classification",
                systemImage: "square.grid.2x2",
                tint: .poolBlue
            ) {
                DripDropFilterRow(
                    title: "Category",
                    subtitle: selectedCategory ?? "All categories",
                    systemImage: "tag",
                    tint: .poolBlue
                ) {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All categories").tag(nil as String?)

                        ForEach(genericCategoryOptions, id: \.self) { category in
                            Text(category).tag(category as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var displayedGenericItems: [GenericItem] {
        var items = genericItemVM.genericItems

        if let selectedCategory {
            items = items.filter { $0.category == selectedCategory }
        }

        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !term.isEmpty {
            items = items.filter { item in
                [
                    item.productDisplayName,
                    item.specificName,
                    item.category,
                    item.subCategory ?? "",
                    item.description,
                    item.sku,
                    item.UOM
                ]
                    .joined(separator: " ")
                    .lowercased()
                    .contains(term)
            }
        }

        return items.sorted {
            $0.productDisplayName.localizedCaseInsensitiveCompare($1.productDisplayName) == .orderedAscending
        }
    }

    private var genericCategoryOptions: [String] {
        Array(Set(genericItemVM.genericItems.map { $0.category.trimmingCharacters(in: .whitespacesAndNewlines) }))
            .filter { !$0.isEmpty }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func resetGenericFilters() {
        selectedCategory = nil
    }

}
