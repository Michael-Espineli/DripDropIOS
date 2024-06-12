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

    @StateObject var inviteVM = InviteViewModel()
    @StateObject var VM : AuthenticationViewModel
    
    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
    }
    
    @State var inviteCode:String = ""
    @State var errorCode:String = ""
    
    @State var showAlert:Bool = false
    @State var isLoading:Bool = false

    @State var email:String = ""
    @State var password:String = ""
    @State var confirmPassword:String = ""

    @State var firstName:String = ""
    @State var lastName:String = ""
    @State var company:String = ""
    @State var companyId:String = ""

    @State var position:String = ""
    
    @State var invite:Invite? = nil
    var body: some View {
        VStack{
            ScrollView{
            if invite == nil {
                VStack{
                    Text("Invite Code")
                        .font(.headline)

                    HStack{
                        Button(action: {
                            inviteCode = ""
                        }, label: {
                            Image(systemName: "xmark.app")
                                .font(.title)
                        })
                        TextField(
                            "Invite Code",
                            text: $inviteCode
                        )
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .foregroundColor(Color.basicFontText)
                        PasteButton(payloadType: String.self) { strings in
                            guard let first = strings.first else { return }
                            inviteCode = first
                        }
                        #if os(iOS)
                        .buttonBorderShape(.capsule)
                        #endif
                    }
                    HStack{
                        Spacer()
                        Button(action: {
                            Task{
                                try? await inviteVM.getSelectedInvite(inviteId: inviteCode)
                                invite = inviteVM.invite
                                if invite == nil {
                                    errorCode = "Invalid Invite Code"
                                    inviteCode = ""
                                    showAlert = true
                                    return
                                } else {
                                    firstName = invite!.firstName
                                    lastName = invite!.lastName
                                    company = invite!.companyName
                                    companyId = invite!.companyId
                                    email = invite!.email
                                    
                                }
                            }
                        }, label: {
                            Text("Submit")
                                .padding(5)
                                .foregroundColor(colorScheme == .dark ? Color.basicFontText:Color.white)
                                .background(Color.accentColor)
                                .cornerRadius(5)
                        })
                        .disabled(inviteCode == "")
                        .padding(20)
                        Spacer()
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.65))
                .cornerRadius(10)
                .padding(5)
            } else {
                VStack{
                    Text("Hi, \(invite!.firstName)")
                        .font(.headline)
                    Text("Welcome to \(company)")
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
                                text: $firstName
                            )
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .foregroundColor(Color.basicFontText)
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
                                text: $lastName
                            )
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .foregroundColor(Color.basicFontText)
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
                                text: $email
                            )
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .foregroundColor(Color.basicFontText)
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
                                text: $password
                            )
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .foregroundColor(Color.basicFontText)
                        }
                        .padding(10)
                    }
                    if password == confirmPassword {
                        Text("")
                    } else {
                        Text("PassWords Must Match")
                            .foregroundColor(Color.red)
                    }
                    VStack{
                        HStack{
                            Text("Confirm Password :")
                                .font(.footnote)
                            Spacer()
                        }
                        SecureField(
                            "Confirm Password",
                            text: $confirmPassword
                        )
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .foregroundColor(Color.basicFontText)
                    }
                    .padding(10)
                    
                    Button{
                        if password == confirmPassword {
                            Task{
                                do{
                                    isLoading = true
                                    if email == "" {
                                        errorCode = "Email Field Empty"
                                        print(errorCode)
                                        showAlert = true
                                        isLoading = false
                                        return
                                    }
                                    if password == "" {
                                        errorCode = "Password Field Empty"
                                        print(errorCode)
                                        showAlert = true
                                        isLoading = false
                                        return
                                    }
                                    if firstName == "" {
                                        errorCode = "First Name Field Empty"
                                        print(errorCode)
                                        showAlert = true
                                        isLoading = false
                                        return
                                    }
                                    if lastName == "" {
                                        errorCode = "Last Name Field Empty"
                                        print(errorCode)
                                        showAlert = true
                                        isLoading = false
                                        return
                                    }
                                    if company == "" {
                                        errorCode = "Company Field Empty"
                                        print(errorCode)
                                        showAlert = true
                                        isLoading = false
                                        return
                                    }
                                    try await VM.signUpWithEmailFromInviteCode(email: email, password: password,firstName:firstName,lastName:lastName,company:company,position:invite!.roleName,invite: invite!)
                                    showAlert = false
                                    masterDataManager.showSignInView = false
                                } catch {
                                    print(error)
                                }
                            }
                        } else {
                            errorCode = "Passwords Do Not Match"
                            print(errorCode)
                            showAlert = true
                        }
                        
                    } label: {
                        Text("Submit")
                            .foregroundColor(colorScheme == .dark ? Color.basicFontText:Color.white)
                            .padding(5)
                            .background(Color.accentColor)
                            .cornerRadius(5)
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
        }
    }
        .alert(errorCode, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}
