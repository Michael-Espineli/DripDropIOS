//
//  CreateCompanyViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//


import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFunctions
import FirebaseFirestore

@MainActor
final class CreateCompanyViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol
    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }
    // Inputs
    @Published var name: String = ""
    @Published var address: Address? = nil // Replace Address with your concrete type
    @Published var addressQuery: String = ""

    @Published var phoneNumber: String = ""
    @Published var email: String = ""
    @Published var websiteURL: String = ""
    @Published var yelpURL: String = ""
    @Published var serviceZipCodes: String = ""
    @Published var selectedServices: [ServiceOption] = [] // local UI type below

    // UI State
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var didSucceed: Bool = false
    @Published var recentlySelectedCompanyId: String? = nil
    
    @Published var newCompany: Company? = nil // Replace Address with your concrete type

    // If you already have a “current user” mechanism, you can inject user id/email instead.
    private var auth: Auth { Auth.auth() }
    private let functions = Functions.functions()
    private let db = Firestore.firestore()

    // Convenience to apply “Use My Email”
    func useUserEmail() {
        if let email = auth.currentUser?.email {
            self.email = email
        }
    }

    // Clipboard paste helper
    func paste(into keyPath: ReferenceWritableKeyPath<CreateCompanyViewModel, String>) async {
        #if os(iOS)
        if let string = UIPasteboard.general.string {
            self[keyPath: keyPath] = string
        } else {
            errorMessage = "Clipboard is empty."
        }
        #else
        // macOS or other platforms — add NSPasteboard if you support them
        #endif
    }

    func submit(dbUser:DBUser?) async {
        guard let dbUser else {
            errorMessage = "Company Name is required."
            return
        }
        guard !name.isEmpty else {
            errorMessage = "Company Name is required."
            return
        }
        guard address != nil else {
            errorMessage = "Address is required."
            return
        }
        guard let user = auth.currentUser else {
            errorMessage = "You must be signed in to create a company."
            return
        }

        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            
            // Prepare payload similar to React code
            let payload: [String: Any] = [
                "ownerId": user.uid,
                "ownerName": dbUser.firstName + " " + dbUser.lastName,
                "companyName": name,
                "address": addressDictionary(address), // helper below
                "email": email,
                "phoneNumber": phoneNumber,
                "zipCodes": parseZipCodes(serviceZipCodes),
                "services": selectedServices.map { $0.value },
                "websiteURL": websiteURL,
                "yelpURL": yelpURL
            ]

            let callable = functions.httpsCallable("createCompanyAfterSignUp")
            let result = try await callable.call(payload)
            guard let data = result.data as? [String: Any],
                  let companyId = data["companyId"] as? String,
                  !companyId.isEmpty else {
                throw NSError(domain: "CreateCompany", code: -1, userInfo: [NSLocalizedDescriptionKey: "Company ID not returned from function."])
            }
            self.errorMessage = "Successfully Created Company"
            // Update user doc with recentlySelectedCompany
            let userDocRef = db.collection("users").document(user.uid)
            try await userDocRef.updateData(["recentlySelectedCompany": companyId])
            self.recentlySelectedCompanyId = companyId
            self.didSucceed = true
            
        } catch {
            self.errorMessage = "Failed to create company. Please try again."
            print("Function call error: \(error)")
        }
    }

    // Convert whatever your Address type is to a Firestore-friendly dictionary
    private func addressDictionary(_ address: Address?) -> [String: Any] {
        guard let address else { return [:] }
        // Replace with your actual fields
        return [
            "line1": address.streetAddress,
            "city": address.city,
            "state": address.state,
            "postalCode": address.zip,
        ]
    }

    private func parseZipCodes(_ input: String) -> [String] {
        input.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    func updateRecentlySelectedCompany(user:DBUser,companyId:String){
        Task{
            do {
                print("  [CreateNewCompanyViewModel][updateRecentlySelectedCompany] updateRecentlySelectedCompany")
                try await dataService.updateUserRecentlySelectedCompany(user: user, recentlySelectedCompanyId: companyId)
                self.newCompany = try await dataService.getCompany(companyId: companyId)
                
            } catch {
                print("  [CreateNewCompanyViewModel][updateRecentlySelectedCompany] Error \(error)")
            }
        }
    }
}

// A simple local type to match your React service options
struct ServiceOption: Identifiable, Hashable {
    let id: String
    let value: String
    let label: String

    init(value: String, label: String) {
        self.id = value
        self.value = value
        self.label = label
    }
}
