//
//  ChatProfileIcon.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/5/24.
//

import SwiftUI

struct ChatProfileIcon: View {
    var image:URL
    var hasNewMessage:Bool
    var body: some View {
        ZStack{
            Circle()
                .stroke(Color.poolBlue, lineWidth:4)
            AsyncImage(url: image){ image in
                image
                    .resizable()
                    .scaledToFill()


            } placeholder: {
                Image(systemName:"photo.circle")
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(Color.white)
            }
            .clipShape(Circle())
            .padding(4)
        }
        .frame(width: 75,height: 75)
        .overlay(
            ZStack{
                if hasNewMessage{
                    Circle()
                        .fill(Color.white)
                    Circle()
                        .fill(Color.poolBlue)
                        .padding(2)
                }
            }
                .frame(width: 24,height: 24)
                .offset(x: 2, y: 2)
                 , alignment: .bottomTrailing)
    }
}

struct ChatProfileIcon_Previews: PreviewProvider {
    static var previews: some View {
        ChatProfileIcon(image:  URL(string: "https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.shutterstock.com%2Fsearch%2Fclient-profile&psig=AOvVaw1jhxauDRKcFu-ag-76qaX7&ust=1712458804056000&source=images&cd=vfe&opi=89978449&ved=0CBIQjRxqFwoTCLiG26fMrIUDFQAAAAAdAAAAABAE")!, hasNewMessage: false)
    }
}
