//
//  DataBaseItemCardView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 9/8/23.
//

import SwiftUI

struct DataBaseItemCardView: View {
    //Enviromental
    @Environment(\.dismiss) private var dismiss
    
    //Variables Received
    @State var dataBaseItem:DataBaseItem
    //View Models Declared
    
    //Variables Declared For Use

    var body: some View {
        ZStack{
                VStack{
                    HStack{
                        Text(dataBaseItem.name)
                        Spacer()
                        Text("\(dataBaseItem.category)")
                            .font(.footnote)
                        Text("\(dataBaseItem.subCategory)")
                            .font(.footnote)
                    }
                    HStack{
                        Text("\(dataBaseItem.rate, format: .currency(code: "USD").precision(.fractionLength(2)))")

                        Text(dataBaseItem.size)
                        Text(dataBaseItem.UOM.rawValue)
                  
                        Spacer()
                    }
                    HStack{
                        Text("Store : \(dataBaseItem.storeName)")

                        Spacer()

                        Text("Last Updated : \(shortDate(date:dataBaseItem.dateUpdated))")
                    }
                    .font(.footnote)
                }
                .modifier(ListButtonModifier())
        }
    }
}
