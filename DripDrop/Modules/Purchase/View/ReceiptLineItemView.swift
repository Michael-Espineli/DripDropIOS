//
//  ReceiptLineItemView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 9/5/23.
//

import SwiftUI

struct ReceiptLineItemView: View {
    //Enviromental
    @Environment(\.dismiss) private var dismiss
    
    //Variables Received
    @Binding var line:LineItem
    
    //Variables Declared For Use
    @State var linequantity = ""
    @State var linename = ""
    @State var linerate = ""
    @State var linetotal = ""
    
    @State private var editDataBase = false
    @State private var edit = false
    
    var body: some View {
        ZStack{
            HStack{
                ZStack{
                    Text("000")
                        .foregroundColor(Color.clear)
                    Text("\(line.quantityString)")
                }
                Rectangle()
                    .frame(width: 1,height: 10)
                Text("\(line.name)")
                Spacer()
                Rectangle()
                    .frame(width: 1,height: 10)
                ZStack{
                    Text("0,000.00")
                        .foregroundColor(Color.clear)
                    Text("\(String(format:"%.2f",line.price))")
                }
                Rectangle()
                    .frame(width: 1,height: 10)
                ZStack{
                    Text("0,000.00")
                        .foregroundColor(Color.clear)
                    Text("\(String(format:"%.2f",line.total))")
                }
            }
        }
    }
}
