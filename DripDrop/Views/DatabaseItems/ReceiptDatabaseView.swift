//
//  ReceiptDatabaseView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/22/23.
//

import SwiftUI

@MainActor
struct ReceiptDatabaseView: View{
    @StateObject private var viewModel = ReceiptDatabaseViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View{
        ZStack{
            VStack{
                ReceiptDatabaseListView()
            }
        }
//        .task{
//            try? await viewModel.getAllDataBaseItems()
//        }
        .toolbar{
            ToolbarItem(){

                NavigationLink{
                    AddDataBaseFromComputer()
                } label: {
                    HStack{
                        Text("from Computer")
                    }
                }
            }
        }
        .navigationTitle("Database Items")
    }
}




