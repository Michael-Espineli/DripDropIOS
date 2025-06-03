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
    @State var iamgeName:String = ""
    var body: some View {
        
        ScrollView(.horizontal){
            HStack{
                ForEach(images){ image in
                    DripDropStoredImageThumbNail(image: image, selectedImage: $selectedImage)
                }
            }
        }
        .sheet(item: $selectedImage, content: { image in
            VStack {
                ZoomableScrollView {
                    if let url = URL(string: image.imageURL){
                        AsyncImage(url: url){ image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(minWidth: 0, maxWidth: .infinity)
                        } placeholder: {
                            Image(systemName:"photo.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(minWidth: 0, maxWidth: .infinity)
                        }
                    } else {
                        Image(systemName:"photo.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(minWidth: 0, maxWidth: .infinity)
                    }
                }
                .padding(8)
                TextField("Image Name", text: $iamgeName) { isEditing in
                        //                    vm.isEditing = isEditing
                }
                    //                .focused($nameField)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal,8)
                HStack {
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: selectedImage == nil ? "square.and.arrow.down.fill" : "square.and.arrow.up.fill")
                            Text(selectedImage == nil ? "Save" : "Update")
                        }
                        .modifier(EditButtonModifier())
                        
                    }
                        //                    .disabled(vm.buttonDisabled)
                        //                    .opacity(vm.buttonDisabled ? 0.6 : 1)
                    Button {
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .modifier(DeleteButtonModifier())
                        
                    }
                    
                }
                .padding(8)
            }
        })
        .onChange(of: selectedImage, perform: { image in
            if let image {
                iamgeName = image.description
            }
        })
    }
}

#Preview {
    DripDropStoredImageRow(images:[])
}
