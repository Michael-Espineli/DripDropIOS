//
//  EditProfileView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/9/23.
//

import SwiftUI
@MainActor
final class EditProfileViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var canUpdate : Bool = false
    @Published var confirmCancellation : Bool = false
    @Published var confirmUpdate : Bool = false
    @Published var firstName : String = ""
    @Published var lastName : String = ""
    @Published var phoneNumber : String = ""
    @Published var email : String = ""
    @Published var bio : String = ""
    func onLoad(tech:DBUser) async{
        self.firstName = tech.firstName
        self.lastName = tech.lastName
        self.phoneNumber = tech.phoneNumber ?? ""
        self.email = tech.email
        self.bio = tech.bio ?? ""
    }
    func checkChanges(tech:DBUser){
        if tech.firstName != firstName || tech.lastName != lastName || tech.phoneNumber != phoneNumber || tech.email != email || tech.bio != bio{
            if firstName == "" || lastName == "" || email == "" || phoneNumber == "" || bio == ""{
                self.canUpdate = false
            } else {
                self.canUpdate = true
            }
        } else {
            self.canUpdate = false
        }
    }
    
    func confirmUpdate(tech:DBUser) async throws -> DBUser?{
   
            if tech.firstName != firstName {
                try dataService.updateDBUserFirstName(userId: tech.id, firstName: firstName)
            }
            if tech.lastName != lastName {
                try dataService.updateDBUserLastName(userId: tech.id, lastName: lastName)
            }
            if tech.phoneNumber != phoneNumber {
                try dataService.updateDBUserPhoneNumber(userId: tech.id, phoneNumber: phoneNumber)
            }
            if tech.email != email {
                try dataService.updateDBUserEmail(userId: tech.id, email: email)
            }
            if tech.bio != bio{
                try dataService.updateDBUserBio(userId: tech.id, bio: bio)
            }
            return try await dataService.getOneUser(userId: tech.id)
    }
    func cancelUpDate(tech:DBUser){
        self.firstName = tech.firstName
        self.lastName = tech.lastName
        self.phoneNumber = tech.phoneNumber ?? ""
        self.email = tech.email
        self.bio = tech.bio ?? ""
    }
}
struct EditProfileView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @State var tech: DBUser
    init(dataService: any ProductionDataServiceProtocol, tech:DBUser){
        _VM = StateObject(wrappedValue: EditProfileViewModel(dataService: dataService))
        _tech = State(wrappedValue: tech)
        
    }
    @StateObject var VM : EditProfileViewModel
    var body: some View {
        ZStack{
            Text("")
                .alert(isPresented:$VM.confirmUpdate) {
                    Alert(
                        title: Text("Alert"),
                        message: Text("Confirm Update"),
                        primaryButton: .destructive(Text("Update")) {
                                Task{
                                    do {
                                        let updatedUser = try await VM.confirmUpdate(tech: tech)
                                        masterDataManager.user = updatedUser
                                    } catch {
                                        print(error)
                                    }
                                }
                        },
                        secondaryButton: .cancel()
                    )
                }
                Text("")
                .alert(isPresented:$VM.confirmCancellation) {
                        Alert(
                            title: Text("Alert"),
                            message: Text("Cancel Update"),
                            primaryButton: .destructive(Text("Cancel")) {
                                VM.cancelUpDate(tech: tech)
                            },
                            secondaryButton: .cancel()
                        )
                    }
            Color.listColor.ignoresSafeArea()
            ScrollView{
                VStack{
                    Text("Edit User Profile")
                    HStack{
                        Text("First Name:")
                        
                        TextField(
                            "Description",
                            text: $VM.firstName
                        )
                        .modifier(PlainTextFieldModifier())
                        if VM.firstName == ""{
                            Text("Empty")
                                .foregroundColor(.red)
                        }
                    }
                    HStack{
                        Text("Last Name:")
                        
                        TextField(
                            "Description",
                            text: $VM.lastName
                        )
                        .modifier(PlainTextFieldModifier())
                        if VM.lastName == ""{
                            Text("Empty")
                                .foregroundColor(.red)
                        }
                    }
                    HStack{
                        Text("Phone Number:")
                        
                        TextField(
                            "Phone Number",
                            text: $VM.phoneNumber
                        )
                        .modifier(PlainTextFieldModifier())
                        if VM.phoneNumber == ""{
                            Text("Empty")
                                .foregroundColor(.red)
                        }

                    }
                    HStack{
                        Text("Email:")
                        
                        TextField(
                            "Email",
                            text: $VM.email
                        )
                        .modifier(PlainTextFieldModifier())
                        if VM.email == ""{
                            Text("Empty")
                                .foregroundColor(.red)
                        }

                    }
                    HStack{
                        Text("Bio:")
                        
                        TextField(
                            "Bio",
                            text: $VM.bio
                        )
                        .modifier(PlainTextFieldModifier())
                        if VM.bio == ""{
                            Text("Empty")
                                .foregroundColor(.red)
                        }

                    }
                }
                if VM.canUpdate {
                    HStack{
                        Button(action: {
                            VM.confirmCancellation = true
                        }, label: {
                            Text("Cancel")
                                .modifier(DeleteButtonModifier())
                        })
                        Button(action: {
                            VM.confirmUpdate = true
                        }, label: {
                            Text("Update")
                                .modifier(BlueButtonModifier())
                        })
                    }
                } else {
                    Text("No Changes")
                }
            }
            .padding()
        }
        .task{
            await VM.onLoad(tech: tech)
        }
        .onChange(of: VM.firstName, perform: { change in
            VM.checkChanges(tech: tech)
        })
        .onChange(of: VM.lastName, perform: { change in
            VM.checkChanges(tech: tech)
        })
        .onChange(of: VM.email, perform: { change in
            VM.checkChanges(tech: tech)
        })
        .onChange(of: VM.phoneNumber, perform: { change in
            VM.checkChanges(tech: tech)
        })
        .onChange(of: VM.email, perform: { change in
            VM.checkChanges(tech: tech)
        })
        .onChange(of: VM.bio, perform: { change in
            VM.checkChanges(tech: tech)
        })
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(dataService: ProductionDataService(), tech: DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: ""))
    }
}
