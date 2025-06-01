//
//  DataBaseItemPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/26/25.
//

import SwiftUI

struct DataBaseItemPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var dataBaseVM : ReceiptDatabaseViewModel
    @State var category:String
    @Binding var jobDBItem : WODBItem
    
    init(
        dataService:any ProductionDataServiceProtocol,
        jobDBItem:Binding<WODBItem>,
        category:String
    ){
        _dataBaseVM = StateObject(wrappedValue: ReceiptDatabaseViewModel(dataService: dataService))
        self._jobDBItem = jobDBItem
        _category = State(wrappedValue: category)
    }
    
    @State var search:String = ""
    @State var dataBaseItems:[DataBaseItem] = []
    var body: some View {
        VStack{
            
         dataBaseList
            searchBar
        }
        .padding()
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                }
            } catch {
                print("Error")

            }
        }
        .onChange(of: search, perform: { term in
            if term == "" {
                Task{
                    do {
                        if let company = masterDataManager.currentCompany {
                 
                        }
                    } catch {
                        print("Error")

                    }
                }
            } else {
                Task{
                    do {
                        if let company = masterDataManager.currentCompany {
                       
                        }
                    } catch {
                        print("Error")
                    }
                }
            }
        })
    }
}
extension DataBaseItemPicker {
    var searchBar: some View {
        HStack{
            TextField(
                text: $search,
                label: {
                    Text("Search: ")
                })
            Button(action: {
                search = ""
            }, label: {
                Image(systemName: "xmark")
            })
        }
        .modifier(SearchTextFieldModifier())
        .padding(8)
    }
    var dataBaseList: some View {
        ScrollView{
            ForEach(dataBaseItems){ datum in
                Button(action: {
                    dismiss()
                }, label: {
                   
                    Text("\(datum.name)")
                
                })
                .padding(5)
                .background(Color.accentColor)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
            }
        }
    }
}

