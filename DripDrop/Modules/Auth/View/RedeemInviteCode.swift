//
//  RedeemInviteCode.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/7/23.
//

import SwiftUI

struct RedeemInviteCode: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var VM : RedeemInviteCodeViewModel
    
    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: RedeemInviteCodeViewModel(dataService: dataService))
    }
    var body: some View {
        VStack{
            ScrollView{
                if let invite = VM.invite {
                    if invite.currentUser {
                        VStack{
                            Text("Hi, \(invite.firstName)")
                                .font(.headline)
                            Text("Welcome to \(invite.companyName)")
                                .font(.headline)
                            Rectangle()
                                .frame(height: 1)
                            Text("Role: \(invite.roleName)")
                            Text("Worker Type: \(invite.workerType.rawValue)")
                            Button{
                                    Task{
                                        do{
                                            try await VM.joinCompanyWithInviteCode(invite:invite)
                                        } catch {
                                            print(error)
                                        }
                                    }
                            } label: {
                                Text("Accept")
                                    .modifier(SubmitButtonModifier())
                            }
                            .padding()
                            if !masterDataManager.showSignInView {
                                NavigationLink(destination: {
                                    SignInView(dataService: dataService)
                                    
                                }, label: {
                                    Text("Already have an acount? Sign In Here.")
                                })
                                .padding()
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.gray.opacity(0.65))
                        .cornerRadius(10)
                        .padding(5)
                    } else {
                        VStack{
                            Text("Hi, \(invite.firstName)")
                                .font(.headline)
                            Text("Welcome to \(invite.companyName)")
                                .font(.headline)
                            VStack{
                                VStack{
                                    HStack{
                                        Text("First Name :")
                                            .font(.footnote)
                                        Spacer()
                                    }
                                    TextField(
                                        "First Name",
                                        text: $VM.firstName
                                    )
                                    .modifier(TextFieldModifier())
                                }
                                .padding(10)
                                VStack{
                                    HStack{
                                        Text("Last Name :")
                                            .font(.footnote)
                                        Spacer()
                                    }
                                    TextField(
                                        "Last Name",
                                        text: $VM.lastName
                                    )
                                    .modifier(TextFieldModifier())
                                }
                                .padding(10)
                                VStack{
                                    HStack{
                                        Text("Email :")
                                            .font(.footnote)
                                        Spacer()
                                    }
                                    TextField(
                                        "Email",
                                        text: $VM.email
                                    )
                                    .modifier(TextFieldModifier())
                                }
                                .padding(10)
                                VStack{
                                    HStack{
                                        Text("Password :")
                                            .font(.footnote)
                                        Spacer()
                                    }
                                    SecureField(
                                        "Password",
                                        text: $VM.password
                                    )
                                    .modifier(TextFieldModifier())
                                }
                                .padding(10)
                            }
                            
                            VStack{
                                HStack{
                                    Text("Confirm Password :")
                                        .font(.footnote)
                                    Spacer()
                                }
                                SecureField(
                                    "Confirm Password",
                                    text: $VM.confirmPassword
                                )
                                .modifier(TextFieldModifier())
                            }
                            .padding(10)
                            if VM.password == VM.confirmPassword {
                                Text("")
                            } else {
                                Text("Passwords Must Match")
                                    .foregroundColor(Color.red)
                            }
                            Button{
                                if VM.password == VM.confirmPassword {
                                    Task{
                                        do{
                                          
                                            try await VM.signUpWithEmailFromInviteCode(invite: invite)
                                            VM.showAlert = false
                                            masterDataManager.showSignInView = false
                                        } catch {
                                            print(error)
                                        }
                                    }
                                } else {
                                    VM.errorCode = "Passwords Do Not Match"
                                    print(VM.errorCode)
                                    VM.showAlert = true
                                }
                                
                            } label: {
                                Text("Submit")
                                    .modifier(SubmitButtonModifier())
                            }
                            .padding()
                            NavigationLink(destination: {
                                SignInView(dataService: dataService)
                                
                            }, label: {
                                Text("Already have an acount? Sign In Here.")
                            })
                            .padding()
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.gray.opacity(0.65))
                        .cornerRadius(10)
                        .padding(5)
                    }
                } else {
                    VStack{
                        Text("Invite Code")
                            .font(.headline)

                        HStack{
                            Button(action: {
                                VM.inviteCode = ""
                            }, label: {
                                Image(systemName: "xmark.app")
                                    .font(.title)
                            })
                            TextField(
                                "Invite Code",
                                text: $VM.inviteCode
                            )
                            .modifier(TextFieldModifier())
                            PasteButton(payloadType: String.self) { strings in
                                guard let first = strings.first else { return }
                                VM.inviteCode = first
                            }
                            #if os(iOS)
                            .buttonBorderShape(.capsule)
                            #endif
                        }
                        HStack{
                            Spacer()
                            Button(action: {
                                Task{
                                    do {
                                        try await VM.getSelectedInvite(inviteId: VM.inviteCode)
                                        if let invite = VM.invite {
                                            VM.firstName = invite.firstName
                                            VM.lastName = invite.lastName
                                            VM.company = invite.companyName
                                            VM.companyId = invite.companyId
                                            VM.email = invite.email
                                            
                                        } else {
                                            VM.errorCode = "Invalid Invite Code"
                                            VM.inviteCode = ""
                                            VM.showAlert = true
                                            return
                                        }
                                    } catch {
                                        print(error)
                                    }
                                }
                            }, label: {
                                Text("Search")
                                    .modifier(SubmitButtonModifier())
                            })
                            .disabled(VM.inviteCode == "")
                            .padding(20)
                            Spacer()
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.65))
                    .cornerRadius(8)
                    .padding(5)
                    .padding(.horizontal,8)
                }
        }
    }
        .fontDesign(.monospaced)

        .alert(VM.errorCode, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear(perform: {
            if !masterDataManager.showSignInView {
                VM.loggedin = true
            }
        })
    }
}
