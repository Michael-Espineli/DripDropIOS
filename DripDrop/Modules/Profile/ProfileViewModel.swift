//
//  ProfileViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/27/23.
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
final class ProfileViewModel: ObservableObject{
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published private(set) var user: DBUser? = nil
    @Published private(set) var imageData: Data? = nil
#if os(iOS)

    @Published private(set) var image: UIImage? = nil
    #endif
    @Published private(set) var iamgeUrl: URL? = nil
    @Published private(set) var imageUrlString: String? = nil

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Uploading Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func loadCurrentUser() async throws{
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await DBUserManager.shared.getCurrentUser(userId: authDataResult.uid)
        self.imageUrlString = user?.photoUrl
    }
#if os(iOS)

    func getImageData(user:DBUser) async throws{
        let currentUser = try await DBUserManager.shared.getCurrentUser(userId: user.id)
        print("Image Path >>\(currentUser.profileImagePath!)")
        self.imageData = try await StorageManager.shared.getData(user: currentUser, path: currentUser.profileImagePath!)
    }
    #endif
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Get Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func saveProfileImage(user:DBUser,item:PhotosPickerItem) {
#if os(iOS)

        Task{
            guard let data = try await item.loadTransferable(type: Data.self) else{
                print("Error Converting Photo Picker Item to Data")
                return
            }
            print("Converted Photo Picker Item to Data")
            let (path,name) = try await StorageManager.shared.saveImage(user: user, data: data)
            print("SUCCESS 2")
            print("Path \(path)")
            print("Name \(name)")
            let url  = try await StorageManager.shared.getUrlForImage(path: path)
            try UserManager.shared.updateUserImagePath(updatingUser: user, path: url.absoluteString)
            self.iamgeUrl = url
            self.imageUrlString = url.absoluteString
        }
        #endif
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Editing Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Deleting Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Functions
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
 
 
}
