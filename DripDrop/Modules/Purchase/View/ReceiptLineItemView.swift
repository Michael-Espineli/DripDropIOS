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
    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State var company:Company

    @Binding var line:LineItem
    //View Models Declared
    @StateObject private var receiptDataBaseViewModel = ReceiptDatabaseViewModel()

    //Variables Declared For Use
    @State var linequantity = ""
    @State var linename = ""
    @State var linerate = ""
    @State var linetotal = ""
    
    @State private var editDataBase = false
    @State private var edit = false

    var body: some View {
        ZStack{
            VStack{

                HStack{
                    HStack{

                        if edit {
                            Text("Name : \(line.name)")
                            
                            Text("Quantity : \(line.quantityString)")
                            TextField(
                                "Quantity",
                                text: $linequantity
                            )
                            Text("Rate : \(line.price)")
                            Text("Total : \(line.total)")
                            Text("Rate : \(line.price)")
                            Button(action: {
                                line.quantityString = linequantity
                                
                            }, label: {
                                Text("Save")
                                    .foregroundColor(Color.red)
                            })
                        } else if editDataBase {
                            Text("Name : \(line.name)")
                            TextField(
                                "Quantity",
                                text: $linename
                            )
                            Text("Quantity : \(line.quantityString)")
                            TextField(
                                "Quantity",
                                text: $linequantity
                            )
                            Text("Rate : \(line.price)")
                            TextField(
                                "Rate",
                                text: $linerate
                            )
                            Text("Total : \(line.total)")
                            
                            Button(action: {
                                
                                Task{
                                    line.quantityString = linequantity
                                    let pushName = linename
                                    let pushRate = linerate
                                    
                                    try? await receiptDataBaseViewModel.editDataBaseItem(companyId: company.id, dataBaseItemId: line.itemId,
                                                                                         name:pushName,
                                                                                         rate:Double(pushRate) ?? 0, description: "")
                                    line.name = linename
                                    line.price = Double(linerate) ?? 0
                                    line.quantityString = linequantity
                                    
                                }
                            }, label: {
                                Text("Save")
                                    .foregroundColor(Color.red)
                            })
                        } else {
                            Text("\(line.quantityString)")

                            Text("of  \(line.name)")
                            Text("at  \(String(format:"%.2f",line.price))")
                            Text("totaling \(String(format:"%.2f",line.total))")
                        }
                        
                    }
                }
            }
        }
    }
}
