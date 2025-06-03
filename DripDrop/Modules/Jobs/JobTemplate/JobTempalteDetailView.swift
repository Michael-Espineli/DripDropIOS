//
//  JobTemplateDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI

struct JobTemplateDetailView: View {
    var template:JobTemplate
    @State var showSFSymbolPicker:Bool = false
    @State var symbol:String = "questionmark"
    @State var edit:Bool = false

    var body: some View {
        ZStack{
            ScrollView{
                VStack{
                    ZStack{
                        Rectangle()
                            .fill(Color[template.color ?? "blue"])
                            .frame(height: 4)
                        HStack{
                            Image(systemName: symbol)
                                .font(.title)
                                .padding(8)
                                .background(Color.darkGray)
                                .cornerRadius(8)
                            Button(action: {
                                showSFSymbolPicker.toggle()
                            }, label: {
                                Image(systemName: "gobackward")
                                    .font(.title)
                                    .padding(8)
                                    .background(Color.darkGray)
                                    .cornerRadius(8)
                                    .foregroundColor(Color.white)
                            })
                            .sheet(isPresented: $showSFSymbolPicker, content: {
                                SFSymbolPicker(symbolName: $symbol)
                            })
                            Spacer()
                            Text("\(template.name)")
                                .font(.title)
                                .padding(8)
                                .background(Color.darkGray)
                                .cornerRadius(8)
                            Spacer()
                            if let locked = template.locked {
                                if !locked {
                                    Button(action: {
                                        edit.toggle()
                                    }, label: {
                                        Text("Edit")
                                            .font(.title)
                                            .padding(8)
                                            .background(Color.poolBlue)
                                            .cornerRadius(8)
                                            .foregroundColor(Color.white)
                                    })
                                    .sheet(isPresented: $edit, content: {
                                        JobTemplateEditView(jobTemplate: template)
                                    })
                                }
                            }
                        }
                        .padding(.horizontal,8)
                    }
                    Text("\(template.type ?? "")")
                    Text("\(fullDate(date:template.dateCreated) )")
                    Text("\(template.rate ?? "")")
                    Text("\(template.type ?? "")")
                    Text("\(template.color ?? "")")
                }
            }
        }
        .onAppear(perform: {
            symbol = template.typeImage ?? "questionmark"
        })
        .onChange(of: template, perform: { temp in
            symbol = temp.typeImage ?? "questionmark"
        })
    }
}

struct JobTemplateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        JobTemplateDetailView(template:JobTemplate(id: "",
                                                 name: "",
                                                 type: "Repair",
                                                 typeImage:"gear",
                                                 dateCreated: Date(),
                                                 rate: "150",
                                                 color: "red"))
    }
}
