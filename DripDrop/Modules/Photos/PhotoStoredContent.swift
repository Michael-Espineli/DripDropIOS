//
//  PhotoStoredContent.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/2/24.
//

import SwiftUI

struct PhotoStoredContent: View {
    @StateObject var vm = PhotoViewModel()
    @FocusState var nameField:Bool
    @Binding var selectedStoredImages:[DripDropStoredImage]
    @State var selectedImage:DripDropStoredImage? = nil
    @State var imageName:String = ""
    @State var curentPhotos:[DripDropStoredImage] = []
    @State var selectedPhoto:DripDropStoredImage? = nil
    @State var selectedImages:[DripDropImage] = []

    var body: some View {
        VStack {
            imageScroll
            
            VStack {
                pickerButtons
                    .sheet(isPresented: $vm.showPicker, onDismiss: {
                        if vm.selectedImage == nil {
                            if let image = vm.image {
                                vm.addMyImage(vm.imageName, image: image)
                            }
                        } else {
                            vm.updateSelected()
                            nameField = false
                        }
                    }, content: {
                        DripDropImagePicker(sourceType: vm.source == .library ? .photoLibrary : .camera, selectedImage: $vm.image)
                            .ignoresSafeArea()
                    })
            }
            .padding()
            
        }
        .task {
            if FileManager().docExist(named: fileName) {
                vm.loadMyImagesJSONFile()
            }
            vm.myImages = selectedImages
        }
//        .onDisappear(perform: {
//            selectedImages = vm.myImages
//        })
        .onChange(of: selectedImages, perform: { images in
            vm.myImages = images
        })
        .alert("Error", isPresented: $vm.showFileAlert, presenting: vm.appError, actions: { cameraError in
            cameraError.button
        }, message: { cameraError in
            Text(cameraError.message)
        })
        .onChange(of: vm.myImages.count, perform: { images in
            selectedImages = vm.myImages
        })
    }
}



extension PhotoStoredContent {
    var imageScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                /*
                 Developer work on display current Photos
                ForEach(curentPhotos) { photo in
                    VStack {
                        Button(action: {
//                            selectedPhoto = myImage
                        }, label: {
                            if let urlString = photo.imageURL,let url = URL(url:urlString) {
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
                            }
                            Text(photo.name)
                        })
                    }
                    .sheet(item: $selectedPhoto, content: { image in
                        VStack {
                            ZoomableScrollView {
                            
                                if let urlString = photo.imageURL,let url = URL(url:urlString) {
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
                                }
                            }
                            .padding(8)
                          
                            HStack {
                                Button {
                                  
                                } label: {
                                    HStack {
                                        Image(systemName: selectedPhoto == nil ? "square.and.arrow.down.fill" : "square.and.arrow.up.fill")
                                        Text(selectedPhoto == nil ? "Save" : "Update")
                                    }
                                    .modifier(EditButtonModifier())
                                    
                                }
                                .disabled(vm.buttonDisabled)
                                .opacity(vm.buttonDisabled ? 0.6 : 1)
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
                }
*/
                ForEach(vm.myImages) { myImage in
                    VStack {
                        Button(action: {
                            vm.selectedImage = myImage
                        }, label: {
                            Image(uiImage: myImage.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(color: .black.opacity(0.6), radius: 2, x: 2, y: 2)
                            Text(myImage.name)
                        })
                    }
                    .sheet(item: $vm.selectedImage, content: { image in
                        VStack {
                            ZoomableScrollView {
                                Image(uiImage: image.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(minWidth: 0, maxWidth: .infinity)
                            }
                            .padding(8)
                            TextField("Name", text: $vm.imageName, prompt:Text("Name"),axis: .vertical)
                            .focused($nameField, equals: true)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal,8)
                            HStack {
                                Button {
                                    if vm.selectedImage == nil {
                                        vm.addMyImage(vm.imageName, image: vm.image!)
                                    } else {
                                        vm.updateSelected()
                                        nameField = false
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: vm.selectedImage == nil ? "square.and.arrow.down.fill" : "square.and.arrow.up.fill")
                                        Text(vm.selectedImage == nil ? "Save" : "Update")
                                    }
                                    .modifier(EditButtonModifier())
                                    
                                }
                                .disabled(vm.buttonDisabled)
                                .opacity(vm.buttonDisabled ? 0.6 : 1)
                                if !vm.deleteButtonIsHidden {
                                    Button {
                                        vm.deleteSelected()
                                    } label: {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Delete")
                                        }
                                        .modifier(DeleteButtonModifier())
                                        
                                    }
                                }
                            }
                            .padding(8)
                        }
                    })
                }
            }
        }
        .padding(.horizontal)
    }

    var pickerButtons: some View {
        HStack {
            Button {
                vm.source = .camera
                vm.showPhotoPicker()
            } label: {
                HStack {
                    Image(systemName: "camera")
                    Text("Camera")
                }
                .modifier(EditButtonModifier())
            }
            .alert("Error", isPresented: $vm.showCameraAlert, presenting: vm.cameraError, actions: { cameraError in
                cameraError.button
            }, message: { cameraError in
                Text(cameraError.message)
            })
            Button {
                vm.source = .library
                vm.showPhotoPicker()
            } label: {
                HStack {
                    Image(systemName: "photo")
                    Text("Photos")
                }
                .modifier(EditButtonModifier())
                
            }
        }
    }
}
