//
//  BankListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 8/30/24.
//

import SwiftUI

struct BankListView: View {
    @State var banks:[Bank] = [
        Bank(name: "Wells Fargo", accountNumber: "12345678", balance: 123_456_78)
    ]
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
        }
        .toolbar{
            ToolbarItem(content: {
                Button(action: {
                    
                }, label: {
                    Text("Connect New Bank")
                })
            })
        }
    }
}

#Preview {
    BankListView()
}

extension BankListView {
    var list: some View {
        ScrollView{
            ForEach(banks){ bank in
                Button(action: {
                    
                }, label: {
                    BankCardView(bank: bank)
                })
                Divider()
            }
        }
    }
    
}
