//
//  TechCardView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct TechCardView: View {
    @State var tech:DBUser
    var body: some View {
        HStack{
            VStack{
                if let urlString = tech.photoUrl,let url = URL(string: urlString){
                    AsyncImage(url: url){ image in
                        image
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(Color.white)
                            .frame(maxWidth:50 ,maxHeight:50)
                            .cornerRadius(50)
                    } placeholder: {
                        Image(systemName:"person.circle")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(Color.basicFontText)
                            .frame(maxWidth:50 ,maxHeight:50)
                            .cornerRadius(50)
                    }
                } else {
                    Image(systemName:"person.circle")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(Color.basicFontText)
                        .frame(maxWidth:50 ,maxHeight:50)
                        .cornerRadius(50)
                }
            }
            Spacer()
            Text("\(tech.firstName ?? "") \(tech.lastName ?? "")")
            Text("Position")
        }
        .padding()
    }
}
