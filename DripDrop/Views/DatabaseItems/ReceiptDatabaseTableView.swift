//
//  ReceiptDatabaseTableView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 9/8/23.
//

import SwiftUI

struct ReceiptDatabaseTableView: View{
    @StateObject private var viewModel = ReceiptDatabaseViewModel()
    @EnvironmentObject var masterDataManager : MasterDataManager

    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State var company:Company

    @State private var selected = Set<DataBaseItem.ID>()
    @State var dataBaseItemList:[DataBaseItem] = []
    @State var showItemView:Bool = false
    @State private var selection: DataBaseItem.ID? = nil

    @State var searchTerm = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View{
        ZStack{

            VStack{
                HStack{
                    Spacer()
                    Button(action: {
                        dismiss()
                        
                    }, label: {
                        Image(systemName: "xmark")
                            .modifier(DismissButtonTextModifier())
                    })
                    .modifier(DismissButtonModifier())
                }
                HStack{
                    Text("Search")
                    TextField(
                        "Item Name, Sku, Description",
                        text: $searchTerm
                    )
                    .cornerRadius(5)
                }
                HStack{
                    Spacer()
                    Button(action: {
                                    Task{
                                        try? await viewModel.getAllDataBaseItemsByName(companyId: company.id)
                                        dataBaseItemList = viewModel.dataBaseItems
                                    }
                    }, label: {
                        Text("Load next Page")

                    })
                }

                Table(of: DataBaseItem.self, selection: $selection){
                    
                    
                    TableColumn("Name"){
                        Text($0.name)
                    }
                    TableColumn("Sku"){
                        Text($0.sku )
                    }
                    TableColumn("Cost"){
                        Text($0.rate, format: .currency(code: "USD").precision(.fractionLength(2)))
                    }
                    TableColumn("Sell Rate"){
                        if $0.sellPrice == nil {
                            Text("NA")
                        } else {
                            Text($0.sellPrice ?? 0, format: .currency(code: "USD").precision(.fractionLength(2)))
                        }
                    }
                    TableColumn("Updated"){
                        if $0.dateUpdated == nil {
                            Text("NA")
                        } else {
                            Text(fullDate(date: $0.dateUpdated) )
                        }
                    }
                    TableColumn("Store Name"){
                        Text($0.storeName )
                    }
                    TableColumn("category"){
                        Text($0.category.rawValue)
                    }
                    TableColumn("Billable"){
                        Text($0.billable ? "Yes" : "No")
                    }
                    TableColumn("Description"){
                        Text($0.description )
                    }
                    
                }rows: {
                    ForEach(dataBaseItemList) { dbItem in
                        TableRow(dbItem)
                            .contextMenu {
                                Button(action: {
//                                    showItemView = true
//                                    selection = dbItem
                                    
                                }, label: {
                                    Image(systemName: "pencil")
                                        .modifier(EditButtonTextModifier())
                                })
                                .modifier(EditButtonModifier())
                                
                                Button(action: {
                                    
                                }, label: {
                                    Text("See Details")
                                })
                                
                                Divider()
                                
                                Button("Delete", role: .destructive) {
                                    //                                            delete(customer)
                                }
                            }

                    }
                }
                HStack{
                    Spacer()
                    Button(action: {
                                    Task{
                                        try? await viewModel.getAllDataBaseItemsByName(companyId: company.id)
                                        dataBaseItemList = viewModel.dataBaseItems
                                    }
                    }, label: {
                        Text("Load next Page")

                    })
                }
            }
//            if showItemView {
//                VStack{
//                    EditDataBaseItemView(dataBaseItem: selection!, user: user)
//                }
//                .frame(width: 300,height: 300)
//                .background(Color.blue)
//                .cornerRadius(20)
//                .padding(20)
//            }
        }
        .onChange(of: searchTerm){ term in
            if searchTerm == "" {
                
                dataBaseItemList = viewModel.dataBaseItems
            } else {
                Task{
                    try? await viewModel.filterDataBaseList(filterTerm: term, items: viewModel.dataBaseItems)
                    dataBaseItemList = viewModel.dataBaseItemsFiltered
                }
            }
        }
        .onChange(of: selection) { selected in
            print("selected Customer")
            if selection != nil {
                let dataBaseItemObject = dataBaseItemList.filter{ $0.id == selected }.first
                masterDataManager.selectedDataBaseItem = dataBaseItemObject
            }
        }
        .toolbar{
            NavigationLink(destination: {
                UploadDataBaseItemsFromComputer(showSignInView: $showSignInView, user: user, company: company)
            }, label: {
                Text("Upload From Computer")
            })
        }
        .task{
            
            try? await viewModel.getAllDataBaseItemsByName(companyId: company.id)
            dataBaseItemList = viewModel.dataBaseItems
            
        }
    }
    
}
