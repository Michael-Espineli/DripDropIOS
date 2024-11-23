//
//  ColorPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/13/24.
//

import SwiftUI

struct ColorStringPicker: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var color:String
    let rows = [
         GridItem(.fixed(50)),
         GridItem(.fixed(50)),
         GridItem(.fixed(50)),
         GridItem(.fixed(50)),
         GridItem(.fixed(50))
     ]
    @State var colors: [String] = [
        "black",
        "blue",
        "brown",
        "cyan",
        "gray",
        "green",
        "indigo",
        "mint",
        "orange",
        "pink",
        "purple",
        "red",
        "teal",
        "white",
        "yellow"
    ]
    var body: some View {
        VStack{
            HStack{
                Spacer()
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Dismiss")
                })
            }
            .padding()
            ScrollView(.horizontal, content: {
                // 3
                LazyHGrid(rows: rows) {
                        ForEach(colors,id:\.self) { i in
                            Button(action: {
                                color = i
                            }, label: {
                                Rectangle()
                                    .fill(Color[color])
                                    .frame(width:10,height: 10)
                                    .padding(3)
                                    .background(color == i ? .white.opacity(0.5) : .gray.opacity(0.5))
                                    .cornerRadius(3)
                                    .padding(3)
                            })
                        }
                
                }
            })
            Spacer()
        }
    }
}


