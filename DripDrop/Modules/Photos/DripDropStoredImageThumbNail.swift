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
        Button {
            selectedImage = image
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                thumbnail

                Text(image.description.isEmpty ? "Photo" : image.description)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(width: 74, alignment: .leading)
            }
            .padding(5)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = URL(string: image.imageURL) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 74, height: 74)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "magnifyingglass")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(.black.opacity(0.35), in: Circle())
                            .padding(5)
                    }
            } placeholder: {
                placeholderThumbnail
            }
        } else {
            placeholderThumbnail
        }
    }

    private var placeholderThumbnail: some View {
        Image(systemName: "photo.circle")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
            .padding(18)
            .frame(width: 74, height: 74)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "magnifyingglass")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(.black.opacity(0.35), in: Circle())
                    .padding(5)
            }
    }
}
//
//#Preview {
//    DripDropStoredImageThumbNail(image: <#DripDropStoredImage#>, selectedImage: <#Binding<DripDropStoredImage?>#>)
//}
