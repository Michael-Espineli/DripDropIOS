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

    var body: some View {
        ZStack{
            list
            icons
        }
        .navigationTitle("Generic Items")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackground()
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await genericItemVM.getAllGenericItems(companyId: company.id)
                } catch {
                    print("Error Getting Generic Items")
                }
            }
        }
    }
}

extension GenericItemList {
    var list: some View {
        VStack(spacing: 0){
            List{
                ForEach(genericItemVM.genericItems) { item in
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
                        VStack{
                            Text("Filter")
                            Text("Category")
                            Text("Sub-Category")

                        }
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
    
}
