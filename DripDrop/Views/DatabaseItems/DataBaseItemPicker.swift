//
//  DataBaseItemSelector.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/13/24.
//

import SwiftUI

struct DataBaseItemPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var dataBaseVM = ReceiptDatabaseViewModel()
    @State var category:String
    @Binding var jobDBItem : WODBItem
    
    init(jobDBItem:Binding<WODBItem>,category:String){
        
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
                if let company = masterDataManager.selectedCompany {
                }
            } catch {
                print("Error")

            }
        }
        .onChange(of: search, perform: { term in
            if term == "" {
                Task{
                    do {
                        if let company = masterDataManager.selectedCompany {
                 
                        }
                    } catch {
                        print("Error")

                    }
                }
            } else {
                Task{
                    do {
                        if let company = masterDataManager.selectedCompany {
                       
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
        TextField(
            text: $search,
            label: {
                Text("Search: ")
            })
        .textFieldStyle(PlainTextFieldStyle())
        .font(.headline)
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .background(Color.white)
        .clipShape(Capsule())
        .foregroundColor(Color.basicFontText)
        
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
