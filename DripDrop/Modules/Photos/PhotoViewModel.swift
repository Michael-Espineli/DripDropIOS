//
//  PhotoViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/25/24.
//


import SwiftUI

class PhotoViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var showPicker = false
    @Published var source: DripDropPicker.Source = .library
    @Published var showCameraAlert = false
    @Published var cameraError: DripDropPicker.CameraErrorType?
    @Published var imageName: String = ""
    @Published var isEditing = false
    @Published var selectedImage: DripDropImage?
    @Published var myImages: [DripDropImage] = []
    @Published var showFileAlert = false
    @Published var appError: DripDropImageError.ErrorType?
    
    init() {
        print(FileManager.docDirURL.path)
    }
    
    var buttonDisabled: Bool {
        imageName.isEmpty || image == nil
    }
    
    var deleteButtonIsHidden: Bool {
        isEditing || selectedImage == nil
    }
    
    func showPhotoPicker() {
        do {
            if source == .camera {
                try DripDropPicker.checkPermissions()
            }
            showPicker = true
        } catch {
            showCameraAlert = true
            cameraError = DripDropPicker.CameraErrorType(error: error as! DripDropPicker.PickerError)
        }
    }
    
    func reset() {
        image = nil
        imageName = ""
        isEditing = false
        selectedImage = nil
    }
    
    func display(_ myImage: DripDropImage) {
        image = myImage.image
        imageName = myImage.name
        selectedImage = myImage
    }
    
    func updateSelected() {
        if let index = myImages.firstIndex(where: {$0.id == selectedImage!.id}) {
            myImages[index].name = imageName
            saveMyImagesJSONFile()
            reset()
        }
    }
    
    func deleteSelected() {
        if let index = myImages.firstIndex(where: {$0.id == selectedImage!.id}) {
            myImages.remove(at: index)
            saveMyImagesJSONFile()
            reset()
        }
    }
    
    func addMyImage(_ name: String, image: UIImage) {
        reset()
        let myImage = DripDropImage(name: name)
        do {
            try FileManager().saveImage("\(myImage.id)", image: image)
            myImages.append(myImage)
            saveMyImagesJSONFile()
            reset()
        } catch {
            showFileAlert = true
            appError = DripDropImageError.ErrorType(error: error as! DripDropImageError)
        }
    }
    
    func saveMyImagesJSONFile() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(myImages)
            let jsonString = String(decoding: data, as: UTF8.self)
            reset()
            do {
                try FileManager().saveDocument(contents: jsonString)
            } catch {
                showFileAlert = true
                appError = DripDropImageError.ErrorType(error: error as! DripDropImageError)
            }
        } catch {
            showFileAlert = true
            appError = DripDropImageError.ErrorType(error: .encodingError)
        }
    }
    
    func loadMyImagesJSONFile() {
        do {
            let data = try FileManager().readDocument()
            let decoder = JSONDecoder()
            do {
                myImages = try decoder.decode([DripDropImage].self, from: data)
            } catch {
                showFileAlert = true
                appError = DripDropImageError.ErrorType(error: .decodingError)
            }
        } catch {
            showFileAlert = true
            appError = DripDropImageError.ErrorType(error: error as! DripDropImageError)
        }
    }
}
