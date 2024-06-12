//
//  SignUpView.swift
//  ClientSide
//
//  Created by Michael Espineli on 11/30/23.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    
    @StateObject private var VM : AuthenticationViewModel
    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
    }
    @State var email:String = ""
    @State var password:String = ""
    @State var confirmPassword:String = ""

    @State var firstName:String = ""
    @State var lastName:String = ""
    @State var company:String = ""
    @State var position:String = ""
    @State var showingAlert:Bool = false
    @State var alertMessage:String = ""

    @State var isLoading:Bool = false

    
    var body: some View {
        ZStack{
            VStack{
                Image("pool")
                    .resizable()
            }
            ScrollView{
                VStack{
                    Text("Welcome Buisness Owner")
                        .font(.title)
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
                                Text("Company Name :")
                                    .font(.footnote)
                                Spacer()
                            }
                            TextField(
                                "Company",
                                text: $company
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
                                        alertMessage = "Email Field Empty"
                                        print(alertMessage)
                                        showingAlert = true
                                        isLoading = false
                                        return
                                    }
                                    if password == "" {
                                        alertMessage = "Password Field Empty"
                                        print(alertMessage)
                                        showingAlert = true
                                        isLoading = false
                                        return
                                    }
                                    if firstName == "" {
                                        alertMessage = "First Name Field Empty"
                                        print(alertMessage)
                                        showingAlert = true
                                        isLoading = false
                                        return
                                    }
                                    if lastName == "" {
                                        alertMessage = "Last Name Field Empty"
                                        print(alertMessage)
                                        showingAlert = true
                                        isLoading = false
                                        return
                                    }
                                    if company == "" {
                                        alertMessage = "Company Field Empty"
                                        print(alertMessage)
                                        showingAlert = true
                                        isLoading = false
                                        return
                                    }
                                    try await VM.signUpWithEmail(email: email, password: password,firstName:firstName,lastName:lastName,company:company,position:"Owner")
                                    isLoading = false
                                    masterDataManager.showSignInView = false
                                } catch {
                                    print(error)
                                }
                            }
                        } else {
                            alertMessage = "Passwords Do Not Match"
                            print(alertMessage)
                            showingAlert = true
                        }
                        
                    } label: {
                        Text("Submit")
                            .padding(5)
                            .foregroundColor(Color.white)
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
                .background(Color.gray.opacity(0.65))
                .cornerRadius(10)
                .padding(10)
            }
            if isLoading {
                VStack{
                Spacer()
                    LoadingSpinner()
                    Spacer()
                }
 
            }

        }
        .alert(isPresented:$showingAlert) {
            Alert(
                title: Text("Alert"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting...")
                },
                secondaryButton: .cancel()
            )
        }
    }
}

