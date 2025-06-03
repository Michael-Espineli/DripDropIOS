//
//  TechSignUpView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/12/23.
//


import SwiftUI

struct TechSignUpView: View {
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
    
    var body: some View {
        VStack{
            ScrollView{
                VStack{
                    Text("Welcome Technican")
                        .font(.title)
                    Text("If you have an invite code, you can redeem it now or later.")
                        .font(.footnote)
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
                                    try await VM.signUpWithEmailWithOutInviteCode(email: email, password: password,firstName:firstName,lastName:lastName)
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
        }
        .alert(errorCode, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}
