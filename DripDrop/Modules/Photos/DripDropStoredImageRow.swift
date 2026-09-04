//
//  DripDropStoredImageRow.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/30/24.
//

import SwiftUI

struct DripDropStoredImageRow: View {
    var images:[DripDropStoredImage]
    @State var selectedImage:DripDropStoredImage?

    @ViewBuilder
    var body: some View {
        if !images.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(images) { image in
                        DripDropStoredImageThumbNail(image: image, selectedImage: $selectedImage)
                    }
                }
                .padding(.vertical, 2)
            }
            .sheet(item: $selectedImage) { image in
                NavigationStack {
                    ZStack {
                        Color.listColor.ignoresSafeArea()

                        VStack(spacing: 14) {
                            ZoomableScrollView {
                                storedImageView(image)
                            }
                            .padding(8)
                            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .padding(.horizontal, 14)
                            .padding(.top, 12)

                            if !image.description.isEmpty {
                                Text(image.description)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .padding(.horizontal, 14)
                            }

                            Spacer()
                        }
                    }
                    .navigationTitle("Photo")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                selectedImage = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .accessibilityLabel("Close")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func storedImageView(_ image: DripDropStoredImage) -> some View {
        if let url = URL(string: image.imageURL) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(minWidth: 0, maxWidth: .infinity)
            } placeholder: {
                placeholderImage
            }
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        Image(systemName: "photo.circle")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(48)
    }
}

#Preview {
    DripDropStoredImageRow(images:[])
}
