//
//  StoreCardView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/21/23.
//

import SwiftUI

struct StoreCardView: View{
    @State var store: Vender
    @StateObject private var viewModel = StoreViewModel()
    var body: some View{
        ZStack{
            HStack{
                VStack{
                    Image(systemName: "house")
                }
                Spacer()
                VStack{
                    Text(store.name ?? "No Name")
                    Text(store.address.streetAddress)
                }
                Spacer()
            }
            .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
            .background(Color.gray)
            .foregroundColor(Color.white)
            .cornerRadius(10)
            
        }
    }
}


