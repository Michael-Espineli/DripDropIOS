//
//  UserViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/27/23.
//

import Foundation
@MainActor
final class UserViewModel:ObservableObject{
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                              Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published private(set) var currentTech: DBUser? = nil
    @Published private(set) var specificUser: DBUser? = nil
    
    @Published private(set) var recentActivityList: [RecentActivityModel] = []

    //Create
    func addRecentActivity(userId:String,recentActivity:RecentActivityModel) async throws{
        try await UserManager.shared.createNewRecentActivity(userId: userId, recentActivity: recentActivity)
    }
    //Read

    func getRecentActivity(userId:String) async throws {
        self.recentActivityList = try await UserManager.shared.getRecentActivityByUser(userId: userId)
    }
    //Update
    func updateUserImagePath(updatingUser:DBUser,path:String) throws {
        try UserManager.shared.updateUserImagePath(updatingUser: updatingUser,path:path)
    }
}
