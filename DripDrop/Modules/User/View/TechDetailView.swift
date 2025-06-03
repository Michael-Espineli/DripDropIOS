//
//  TechDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct TechDetailView: View {
    @EnvironmentObject var dataService: ProductionDataService
    @State var tech:DBUser
    @State var showSheet:Bool = false
    var body: some View {
        VStack{
            ScrollView {
                ZStack{
                    if let urlString = tech.photoUrl,let url = URL(string: urlString){
                        AsyncImage(url: url){ image in
                            image
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.white)
                                .frame(maxWidth:100 ,maxHeight:100)
                                .cornerRadius(100)
                        } placeholder: {
                            Image(systemName:"person.circle")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.white)
                                .frame(maxWidth:100 ,maxHeight:100)
                                .cornerRadius(100)
                        }
                    } else {
                        Image(systemName:"person.circle")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(Color.white)
                            .frame(maxWidth:100 ,maxHeight:100)
                            .cornerRadius(100)
                    }

                }
                Text("\(tech.firstName ?? "") \(tech.lastName ?? "")")
                Text("Position: ")
                Text("Date Created: \(fullDate(date:tech.dateCreated))")
                Text("Company: ")
                Text("Tech: \(tech.email ?? "")")
                Text("Role: ")
                NavigationLink(value: Route.rateSheet(user: tech, dataService:dataService), label: {
                    Text("Rate Sheet")
                        .foregroundColor(Color.basicFontText)
                        .padding(5)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                })
                .sheet(isPresented: $showSheet, content: {
                    EditTechView(dataService: dataService, tech: tech)
                })
            }
        }
        .toolbar{
            ToolbarItem(content: {
                Button(action: {
                    showSheet.toggle()
                }, label: {
                    Text("Edit")
                        .modifier(EditButtonModifier())
                })
            })
        }
    }
}
