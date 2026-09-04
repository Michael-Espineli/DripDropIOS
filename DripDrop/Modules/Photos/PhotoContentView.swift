//
//  PhotoContentView.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/25/24.
//

import SwiftUI

struct PhotoContentView: View {
    @StateObject var vm = PhotoViewModel()
    @FocusState var nameField: Bool

    @Binding var selectedImages: [DripDropImage]

    @State var selectedImage: DripDropImage? = nil
    @State var imageName: String = ""
    @State var curentPhotos: [DripDropStoredImage] = []
    @State var selectedPhoto: DripDropStoredImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            pickerButtons

            if !vm.myImages.isEmpty {
                imageScroll
            }
        }
        .task {
            if FileManager().docExist(named: fileName) {
                vm.loadMyImagesJSONFile()
            }

            vm.myImages = selectedImages
        }
        .onChange(of: selectedImages) { images in
            vm.myImages = images
        }
        .onChange(of: vm.myImages) { images in
            selectedImages = images
        }
        .alert("Error", isPresented: $vm.showFileAlert, presenting: vm.appError, actions: { cameraError in
            cameraError.button
        }, message: { cameraError in
            Text(cameraError.message)
        })
        .sheet(isPresented: $vm.showPicker, onDismiss: {
            if vm.selectedImage == nil {
                if let image = vm.image {
                    vm.addMyImage(vm.imageName, image: image)
                }
            } else {
                vm.updateSelected()
                nameField = false
            }
        }) {
            DripDropImagePicker(
                sourceType: vm.source == .library ? .photoLibrary : .camera,
                selectedImage: $vm.image
            )
            .ignoresSafeArea()
        }
    }
}

struct DripDropPhotoUploadIndicator: View {
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            ProgressView()
                .controlSize(.small)

            Text("\(count) photo\(count == 1 ? "" : "s") uploading")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
    }
}

struct DripDropCompactPhotoEmptyState: View {
    var title: String = "No photos uploaded yet"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PhotoViewModel())
    }
}

// MARK: - Views

extension PhotoContentView {

    var pickerButtons: some View {
        HStack(spacing: 8) {
            Button {
                vm.source = .camera
                vm.showPhotoPicker()
            } label: {
                photoActionLabel(
                    title: "Camera",
                    systemImage: "camera"
                )
            }
            .buttonStyle(.plain)
            .alert("Error", isPresented: $vm.showCameraAlert, presenting: vm.cameraError, actions: { cameraError in
                cameraError.button
            }, message: { cameraError in
                Text(cameraError.message)
            })

            Button {
                vm.source = .library
                vm.showPhotoPicker()
            } label: {
                photoActionLabel(
                    title: "Photos",
                    systemImage: "photo"
                )
            }
            .buttonStyle(.plain)

            if !vm.myImages.isEmpty {
                Text("\(vm.myImages.count) photo\(vm.myImages.count == 1 ? "" : "s") added")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
            }
        }
    }

    func photoActionLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var imageScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(vm.myImages) { myImage in
                    Button {
                        vm.selectedImage = myImage
                        vm.imageName = myImage.name
                    } label: {
                        imageThumbnail(myImage)
                    }
                    .buttonStyle(.plain)
                    .sheet(item: $vm.selectedImage) { image in
                        imageDetailSheet(image)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    func imageThumbnail(_ myImage: DripDropImage) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(uiImage: myImage.image)
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

            Text(myImage.name.isEmpty ? "Photo" : myImage.name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: 74, alignment: .leading)
        }
        .padding(5)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func imageDetailSheet(_ image: DripDropImage) -> some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Photo")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("Review or update this image.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        vm.selectedImage = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 34, height: 34)
                            .background(.thinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 14)
                .padding(.top, 12)

                ZoomableScrollView {
                    Image(uiImage: image.image)
                        .resizable()
                        .scaledToFit()
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                .padding(8)
                .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Image Name", systemImage: "text.cursor")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextField("Image Name", text: $vm.imageName) { isEditing in
                        vm.isEditing = isEditing
                    }
                    .focused($nameField)
                    .font(.subheadline)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 14)

                Spacer()

                bottomImageActions
            }
        }
        .toolbar {
            if nameField {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    KeyboardDismissButton {
                        nameField = false
                    }
                }
            }
        }
    }

    var bottomImageActions: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.35)

            HStack(spacing: 12) {
                if !vm.deleteButtonIsHidden {
                    Button(role: .destructive) {
                        vm.deleteSelected()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    if vm.selectedImage == nil {
                        if let image = vm.image {
                            vm.addMyImage(vm.imageName, image: image)
                        }
                    } else {
                        vm.updateSelected()
                        nameField = false
                    }
                } label: {
                    Label(vm.selectedImage == nil ? "Save" : "Update", systemImage: vm.selectedImage == nil ? "square.and.arrow.down.fill" : "square.and.arrow.up.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(vm.buttonDisabled)
                .opacity(vm.buttonDisabled ? 0.55 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }
}
