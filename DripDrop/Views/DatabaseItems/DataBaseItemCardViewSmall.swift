//
//  DataBaseItemCardViewSmall.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/2/24.
//


import SwiftUI

struct DataBaseItemCardViewSmall: View {
    //Enviromental
    @Environment(\.dismiss) private var dismiss
    
    //Variables Received
    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State var dataBaseItem:DataBaseItem
    //View Models Declared
    
    //Variables Declared For Use

    var body: some View {
        ZStack{
                VStack{
                    HStack{
                        Text(dataBaseItem.name)
                        Text(String(dataBaseItem.rate))
                        Text(dataBaseItem.size)
                            Text(dataBaseItem.UOM.rawValue)
     
                    }
                    HStack{
                        Text("Last Updated : \(shortDate(date:dataBaseItem.dateUpdated))")
                            .font(.footnote)
                        Spacer()
                        Text("Store : \(dataBaseItem.storeName)")
                            .font(.footnote)
                    }
                }
                .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
                .background(Color.gray)
                .foregroundColor(Color.white)
                .cornerRadius(10)
        }
    }
}
