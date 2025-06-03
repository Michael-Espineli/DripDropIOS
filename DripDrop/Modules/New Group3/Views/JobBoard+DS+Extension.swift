//
//  JobBoard+DS+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

extension ProductionDataService {
    //Refrences
    func JobBoardCollection() -> CollectionReference{
        db.collection("jobBoards")
    }
    func JobPostsCollection() -> CollectionReference{
        db.collection("jobPosts")
    }
    func JobBoardDocument(jobBoardId:String)-> DocumentReference{
        JobBoardCollection().document(jobBoardId)
    }
    func JobPostDocument(jobPostId:String)-> DocumentReference{
        JobPostsCollection().document(jobPostId)
    }
    
    //Create
    
    func createNewJobPost(jobPost:JobPost) async throws{
        try await JobPostDocument(jobPostId: jobPost.id)
            .setData(from:jobPost, merge: true)
    }
    //Read
    func getPublicJobBoards() async throws -> [JobBoard] {
        return try await JobBoardCollection()
            .whereField("permissionType", isEqualTo: JobBoardPermissionType.publicAccess.rawValue)
            .getDocuments(as: JobBoard.self)
    }
    func getSavedJobBoards(userId:String) async throws -> [JobBoard] {
        
        return try await JobBoardCollection()
            .whereField("permissionType", isEqualTo: JobBoardPermissionType.publicAccess.rawValue)
            .getDocuments(as: JobBoard.self)
    }
    func getJobPostsByBoard(boardId:String) async throws -> [JobPost] {
        return try await JobPostsCollection()
            .whereField("boardId", isEqualTo: boardId)
            .order(by: "datePosted", descending: true)
            .getDocuments(as: JobPost.self)
    }
    
    func getJobPostsByUserId(userId:String) async throws -> [JobPost] {
        return try await JobPostsCollection()
            .whereField("ownerId", isEqualTo: userId)
            .order(by: "datePosted", descending: true)
            .getDocuments(as: JobPost.self)
        
    }
    //Update
    
    //Delete
}
