    //
    //  PhotoContentView.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 6/25/24.
    //

import SwiftUI

struct PhotoContentView: View {
    @StateObject var vm = PhotoViewModel()
    @FocusState var nameField:Bool
    @Binding var selectedImages:[DripDropImage]
    @State var selectedImage:DripDropImage? = nil
    @State var imageName:String = ""
    @State var curentPhotos:[DripDropStoredImage] = []
    @State var selectedPhoto:DripDropStoredImage? = nil
    
    var body: some View {
        VStack {
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
            .padding(4)
//            imageScroll
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PhotoViewModel())
    }
}




extension PhotoContentView {
    var imageScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                
                ForEach(vm.myImages) { myImage in
                    VStack {
                        Button(action: {
                            vm.selectedImage = myImage
                        }, label: {
                            Image(uiImage: myImage.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
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
                            TextField("Image Name", text: $vm.imageName) { isEditing in
                                vm.isEditing = isEditing
                            }
                            .focused($nameField)
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
