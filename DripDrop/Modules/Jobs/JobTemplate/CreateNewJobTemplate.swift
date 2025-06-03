//
//  CreateNewJobTemplate.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/14/24.
//

import SwiftUI

struct CreateNewJobTemplate: View {
    @State var showSFSymbolPicker:Bool = false
    @State var showColorPicker:Bool = false

    @State var name:String = ""
    @State var type:String = ""
    @State var color:String = ""
    @State var rate:String = ""
    @State var symbol:String = ""
    var body: some View {
        VStack{
            Text("Create New Job Template View")
            HStack{
                Spacer()
                Button(action: {
                    showColorPicker.toggle()
                }, label: {
                    Rectangle()
                        .fill(Color[color])
                        .frame(width:50,height: 50)
                        .padding(3)
                        .cornerRadius(3)
                })
                .sheet(isPresented: $showColorPicker, content: {
                    ColorStringPicker(color: $color)
                })
                Button(action: {
                    showSFSymbolPicker.toggle()

                }, label: {
                    Image(systemName: symbol)
                        .font(.title)
                        .padding(8)
                        .background(Color.darkGray)
                        .cornerRadius(8)
                })
                .sheet(isPresented: $showSFSymbolPicker, content: {
                    SFSymbolPicker(symbolName: $symbol)
                })
            }
            .padding(.horizontal,16)
            HStack{
                Text("Name")
                    .bold(true)
                TextField(
                    "name",
                    text: $name
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
            }
            HStack{
                Text("rate")
                    .bold(true)
                TextField(
                    "name",
                    text: $rate
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
            }
            HStack{
                Text("type")
                    .bold(true)
                TextField(
                    "type",
                    text: $type
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
            }
            Button(action: {
                print("Developer Create Job Template Logic")
            }, label: {
                Text("Create")
                    .padding(8)
                    .background(Color.green)
                    .cornerRadius(8)
            })
        }
    }
}

struct CreateNewJobTemplate_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewJobTemplate()
    }
}
