//
//  ReceiptDatabaseListView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 9/8/23.
//

import SwiftUI
enum NewDatabaseItemPickerType:Identifiable{
    case manual, upload
    var id:Int {
        hashValue
    }
}
struct ReceiptDatabaseListView: View{
    @Environment(\.dismiss) private var dismiss
    @State var selectedDocumentUrl:URL? = nil

    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService

    @StateObject private var viewModel = ReceiptDatabaseViewModel()

    @State private var selected = Set<DataBaseItem.ID>()
    @State var dataBaseItemList:[DataBaseItem] = []
    @State var showItemView:Bool = false
    @State var selectedItem:DataBaseItem? = nil
    @State var searchTerm = ""
    
    @State private var pickerType:NewDatabaseItemPickerType? = nil
    @State private var selectedPickerType:NewDatabaseItemPickerType? = nil
    
    @State var showAddNew = false
    @State var showSearch = false
    @State var showFilter = false
    @State var loadingNewProducts = false

    @State var showFileComfirmation = false

    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            if UIDevice.isIPhone {
                databaseItems
            } else {
                macDatabaseItems
            }
          icons
        }
        .onChange(of: selectedDocumentUrl, perform: { doc in
            showFileComfirmation = true
        })
        .onChange(of: searchTerm){ term in
            if searchTerm == "" {
                dataBaseItemList = viewModel.dataBaseItems
            } else {
                            viewModel.filterDataBaseList(filterTerm: term, items: viewModel.dataBaseItems)
                            dataBaseItemList = viewModel.dataBaseItemsFiltered
            }
        }
        .task{
            if let company = masterDataManager.selectedCompany {
                do {
                    try await viewModel.getAllDataBaseItemsByName(companyId: company.id)
                    dataBaseItemList = viewModel.dataBaseItems
                } catch {
                    print(error)
                }
            }
        }
    }
    
}
extension ReceiptDatabaseListView {
    var databaseItems: some View {
            ScrollView{
                LazyVStack{

                ForEach(dataBaseItemList) { item in
                        NavigationLink(value: Route.dataBaseItem(dataBaseItem: item,dataService:dataService), label: {
                            DataBaseItemCardView(dataBaseItem: item)
                        })
                    Divider()
                    if item == dataBaseItemList.last{
                            HStack{
                                if loadingNewProducts {
                                    
                                    ProgressView()
                                }
                            }
                            .onAppear{
                                print("Loading New Prodcuts")
                                Task{
                                    loadingNewProducts = true
                                    if let company = masterDataManager.selectedCompany {
                                        do {
                                            try await viewModel.getAllDataBaseItemsByName(companyId: company.id)
                                            if searchTerm == "" {
                                                dataBaseItemList = viewModel.dataBaseItems
                                            } else {
                                                viewModel.filterDataBaseList(filterTerm: searchTerm, items: viewModel.dataBaseItems)
                                                dataBaseItemList = viewModel.dataBaseItemsFiltered
                                            }
                                        } catch {
                                            print(error)
                                        }
                                    }
                                    loadingNewProducts = false

                            }
                        }
                    }
                }
            }
        }
    }
    var macDatabaseItems: some View {
        List(selection:$masterDataManager.selectedID){
                ForEach(dataBaseItemList) { item in
                    if UIDevice.isIPhone {
                        NavigationLink(value: Route.dataBaseItem(dataBaseItem: item,dataService:dataService), label: {
                            DataBaseItemCardView(dataBaseItem: item)
                        })
                    } else {
                        Button(action: {
                            masterDataManager.selectedDataBaseItem = item
                        }, label: {
                            DataBaseItemCardView(dataBaseItem: item)
                        })
                    }
//                        NavigationLink(value: Route.dataBaseItem(dataBaseItem: item), label: {
//                            DataBaseItemCardView(showSignInView: $showSignInView, user: user, dataBaseItem: item)
//                        })

                    if item == viewModel.dataBaseItems.last{
                        HStack{
                            ProgressView()
                        }
                        .onAppear{
                            print("Loading New Prodcuts")
                            Task{
                                if let company = masterDataManager.selectedCompany {
                                    do {
                                        try await viewModel.getAllDataBaseItemsByName(companyId: company.id)
                                        dataBaseItemList = viewModel.dataBaseItems
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        }
                    }
                }
        }
        .padding()
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
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.orange)
                        }
                    })
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    .sheet(isPresented: $showFilter, content: {
                        VStack{
                            Text("Filter Information")
                            Spacer()
                        }
                        .presentationDetents([.medium])
                    })
                    Button(action: {
                        showAddNew.toggle()
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
                    .padding(10)
                    .confirmationDialog("Select Type", isPresented: self.$showAddNew, actions: {
                        Button(action: {
                            self.pickerType = .manual
                            self.selectedPickerType = .manual
                        }, label: {
                            Text("Manual")
                        })
                        Button(action: {
                            self.pickerType = .upload
                            self.selectedPickerType = .upload
                            
                        }, label: {
                            Text("Upload")
                        })
                    })
                    .sheet(item: self.$pickerType,onDismiss: {
                        print("dismiss")
                        
                    }){ item in
                        switch item {
                        case .manual:
                            NavigationView{
                                AddNewDatabaseItem()
                            }
                        case .upload:
                            NavigationView{
                                DocumentPicker(filePath: self.$selectedDocumentUrl)
                            }

                        }
                    }
                    .sheet(isPresented: $showFileComfirmation, content: {
                        if let doc = selectedDocumentUrl {
                            UploadXLSXFileForDataBaseItem(selectedDocumentUrl: doc)
                        } else {
                            DocumentPicker(filePath: self.$selectedDocumentUrl)

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
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                }
            }
            if showSearch {
                HStack{
                    TextField(
                        "Search",
                        text: $searchTerm
                    )
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(Color.black)
                    .cornerRadius(10)
                }
            }
        }
    }
}
