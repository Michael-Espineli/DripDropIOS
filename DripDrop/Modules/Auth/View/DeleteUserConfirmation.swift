//
//  DeleteUserConfirmation.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/4/26.
//

import SwiftUI
import FirebaseAuth

@MainActor
final class DeleteUserConfirmationViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var search:String = ""
    @Published var companies:[Company] = []
    
    func onLoad(userId:String) async throws {
    }
    func deleteUser(user:DBUser?){
        Task{
            do {
                guard let user else {return}
                //Delete from database
                try await dataService.deleteDBUser(userId: user.id)
                
                //Delete from Auth
                deleteCurrentUser()
                
            } catch {
                print(error)
            }
        }
    }

    func deleteCurrentUser() {
        guard let user = Auth.auth().currentUser else {
            print("No user is signed in")
            return
        }

        user.delete { error in
            if let error = error {
                print("Error deleting user: \(error.localizedDescription)")
            } else {
                print("User account deleted")
            }
        }
    }
}

struct DeleteUserConfirmation: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : DeleteUserConfirmationViewModel

    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: DeleteUserConfirmationViewModel(dataService: dataService))

    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                Text("Please make sure you want to delete your account, It can not be undone.")
                Button(action: {
                    VM.deleteUser(user: masterDataManager.user)
                    dismiss()
                }, label: {
                    Text("Confirm Delete")
                    .foregroundColor(Color.white)
                    .modifier(DismissButtonModifier())
                    
                })
            }
            .padding()
        }
    }
}

#Preview {
    DeleteUserConfirmation(dataService: MockDataService())
}
