//
//  CompanyViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/28/23.
//


import Foundation
import SwiftUI
import PhotosUI

@MainActor
final class CompanyViewModel: ObservableObject{
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published private(set) var user: DBUser? = nil
    
    @Published private(set) var company: Company? = nil
    @Published private(set) var listOfCompanies: [Company] = []
    
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
    func loadCurrentCompany(companyId:String) async throws{
        let company = try await CompanyManager.shared.getCompany(companyId: companyId)
        self.imageUrlString = company.photoUrl
    }
    func getImageData(user:DBUser) async throws{
#if os(iOS)

        let currentUser = try await DBUserManager.shared.getCurrentUser(userId: user.id)
        print("Image Path >>\(currentUser.profileImagePath!)")
        self.imageData = try await StorageManager.shared.getData(user: currentUser, path: currentUser.profileImagePath!)
        #endif
    }
    func getCompaniesByUserList(companyIds:[String]) async throws{
        var listOfCompanies:[Company] = []
        for id in companyIds{
            let company = try await CompanyManager.shared.getCompany(companyId: id)
            listOfCompanies.append(company)
        }
        self.listOfCompanies = listOfCompanies
    }
    func getCompaniesByUserAccessList(userId:String) async throws{
        let accessList = try await UserAccessManager.shared.getAllUserAvailableCompanies(userId: userId)
        print("Received List of \(accessList.count) Companies available to Access")
        var listOfCompanies:[Company] = []
        for access in accessList{
            let company = try await CompanyManager.shared.getCompany(companyId: access.id)// access id is company id
            listOfCompanies.append(company)
        }
        self.listOfCompanies = listOfCompanies
    }
    func getFavoriteCompany(favoriteCompanyId:String) async throws{
        let company = try await CompanyManager.shared.getCompany(companyId: favoriteCompanyId)
        
        self.company = company
        
        //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        //                             Get Recordings
        //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        func saveProfileImage(user:DBUser,companyId:String,item:PhotosPickerItem) {
#if os(iOS)

            Task{
                guard let data = try await item.loadTransferable(type: Data.self) else{
                    print("Error Converting Photo Picker Item to Data")
                    return
                }
                print("Converted Photo Picker Item to Data")
                let (path,name) = try await CompanyImageManager.shared.saveImage(user: user, data: data)
                print("SUCCESS 2")
                print("Path \(path)")
                print("Name \(name)")
                let url  = try await CompanyImageManager.shared.getUrlForImage(path: path)
                try CompanyManager.shared.updateCompanyImagePath(user: user, companyId: companyId, path:url.absoluteString)
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
}
