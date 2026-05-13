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
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Text("Welcome Technican")
                    .font(.title)
                Text("If you have an invite code, you can redeem it now or later.")
                    .font(.footnote)
                VStack{
                    VStack{
                        HStack{
                            Text("First Name:")
                            Spacer()
                        }
                        TextField(
                            "First Name",
                            text: $firstName
                        )
                        .modifier(PlainTextFieldModifier())
                    }
                    .padding(10)
                    VStack{
                        HStack{
                            Text("Last Name:")
                            Spacer()
                        }
                        TextField(
                            "Last Name",
                            text: $lastName
                        )
                        .modifier(PlainTextFieldModifier())
                    }
                    .padding(10)
                    
                    VStack{
                        HStack{
                            Text("Email :")
                            Spacer()
                        }
                        TextField(
                            "Email",
                            text: $email
                        )
                        .modifier(PlainTextFieldModifier())
                    }
                    .padding(10)
                    
                    VStack{
                        HStack{
                            Text("Password :")
                            Spacer()
                        }
                        SecureField(
                            "Password",
                            text: $password
                        )
                        .modifier(PlainTextFieldModifier())
                    }
                    .padding(10)
                }
                if password == confirmPassword {
                    Text("")
                } else {
                    Text("Passwords Must Match")
                        .foregroundColor(Color.red)
                }
                VStack{
                    HStack{
                        Text("Confirm Password :")
                        Spacer()
                    }
                    SecureField(
                        "Confirm Password",
                        text: $confirmPassword
                    )
                    .modifier(PlainTextFieldModifier())
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
                                print("Success")
                                showAlert = false
                                masterDataManager.showSignInView = false
                            } catch {
                                print("")
                                print("[TechSignUpView][Create New User] Error \(error)")
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
                        .underline(true)
                })
                .padding()
            }
            .padding()
        }
        .alert(errorCode, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}
