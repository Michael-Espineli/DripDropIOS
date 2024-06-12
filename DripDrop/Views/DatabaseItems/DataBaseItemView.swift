//
//  DataBaseItemView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/20/23.
//


import SwiftUI
import Combine

struct DataBaseItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var viewModel = ReceiptDatabaseViewModel()
    let dataBaseItem: DataBaseItem
    
    
    @State var name = ""
    @State var rate = ""
    @State var storeName = ""
    @State var storeId = ""
    @State var category = ""
    @State var description = ""
    @State var dateUpdated = Date()
    
    @State var sku = ""
    @State var billable:Bool = false
    @State var color = ""
    @State var size = ""
    
    @State var showEdit:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                VStack(alignment: .leading){
                    HStack{
                        Spacer()
                        
                        Button(action: {
                            showEdit.toggle()
                        }, label: {
                            Text("Edit")
                                .padding(5)
                                .background(Color.accentColor)
                                .foregroundColor(Color.black)
                                .cornerRadius(5)
                        })
                        .sheet(isPresented: $showEdit, content: {
                            EditDataBaseItemView(dataBaseItem: dataBaseItem)
                        })
                    }
                    HStack{
                        Text("Name: ")
                        Text("\(dataBaseItem.name)")
                        
                    }
                    HStack{
                        Text("Description: ")
                        Text("\(dataBaseItem.description)")
                        
                    }
                    HStack{
                        Text("Billable: ")
                        Text("\(dataBaseItem.billable.description)")
                    }
                    HStack{
                        Text("Rate: ")
                        Text("$ \(String(dataBaseItem.rate))")
                    }
                    HStack{
                        Text("Category: ")
                        Text("\(dataBaseItem.category)")
                        
                    }
                    HStack{
                        Text("Sub-Category: ")
                        Text("\(dataBaseItem.subCategory.rawValue)")
                    }
                    
                }
                .padding(.horizontal,16)
            }
        }
    }
}

