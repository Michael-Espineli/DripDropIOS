//
//  DripDropStoredImageThumbNail.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/30/24.
//

import SwiftUI

struct DripDropStoredImageThumbNail: View {
    @State var image:DripDropStoredImage
    @Binding var selectedImage:DripDropStoredImage?
    var body: some View {
        VStack {
            Button(action: {
                selectedImage = image
            }, label: {
                if let url = URL(string: image.imageURL){
                    AsyncImage(url: url){ image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .shadow(color: .black.opacity(0.6), radius: 2, x: 2, y: 2)
                    } placeholder: {
                        Image(systemName:"photo.circle")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .shadow(color: .black.opacity(0.6), radius: 2, x: 2, y: 2)
                    }
                } else {
                    Image(systemName:"photo.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: .black.opacity(0.6), radius: 2, x: 2, y: 2)
                }
            })
        }
       
    }
}
//
//#Preview {
//    DripDropStoredImageThumbNail(image: <#DripDropStoredImage#>, selectedImage: <#Binding<DripDropStoredImage?>#>)
//}
