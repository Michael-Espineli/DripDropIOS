//
//  SignUpView.swift
//  ClientSide
//
//  Created by Michael Espineli on 11/30/23.
//

import SwiftUI

struct SignUpView: View {
    init( dataService:any ProductionDataServiceProtocol,services:[String],serviceZipCodes:[String]){
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
        _serviceZipCodes = State(wrappedValue: serviceZipCodes)
        _services = State(wrappedValue: services)
    }
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject private var VM : AuthenticationViewModel
    
    @State var services:[String] = []
    @State var serviceZipCodes:[String] = []
    
    @State var email:String = ""
    @State var password:String = ""
    @State var confirmPassword:String = ""
    @State var passwordDisabled:Bool = true
    
    @State var firstName:String = ""
    @State var lastName:String = ""
    @State var company:String = ""
    @State var position:String = ""
    @State var showingAlert:Bool = false
    @State var alertMessage:String = ""
    
    @State var isLoading:Bool = false
    
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                HStack{
                    Spacer()
                    VStack{
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
                                .modifier(TextFieldModifier())
                            }
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
                                .modifier(TextFieldModifier())
                                
                            }
                            
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
                                .modifier(TextFieldModifier())
                                
                            }
                            
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
                                .modifier(TextFieldModifier())
                                
                            }
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
                                .modifier(TextFieldModifier())
                                
                            }
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
                            .modifier(TextFieldModifier())
                            
                        }
                        //Password Verification
                        VStack(alignment: .leading){
                            if password != "" {
                                if password.contains("!") || password.contains("#") || password.contains("@") || password.contains("$") || password.contains("^") || password.contains("*") || password.contains("(") || password.contains(")") || password.contains("+") || password.contains("=") {
                                    HStack{
                                        Text("Contains Special Charecters")
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                    .foregroundColor(Color.poolGreen)
                                } else {
                                    Text("Must Contain Special Chatecters")
                                        .foregroundColor(Color.red)
                                }
                                if password.count >= 8 {
                                    HStack{
                                        Text("Length 8 +")
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                    .foregroundColor(Color.poolGreen)
                                } else {
                                    Text("Must Be Longer than 8 Charecters")
                                        .foregroundColor(Color.red)
                                }
                                if password == confirmPassword {
                                    HStack{
                                        Text("Passwords Match")
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                    .foregroundColor(Color.poolGreen)
                                } else {
                                    Text("Passwords Must Match")
                                        .foregroundColor(Color.red)
                                }
                                
                            }
                        }
                        Button{
                            if password == confirmPassword {
                                Task{
                                    do{
                                        isLoading = true
                                        //Verifies all needed information is received
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
                                        //Creates new company
                                        try await VM.signUpWithEmailAndCreateCompany(email: email, password: password, firstName: firstName, lastName: lastName, company: company, position: "Owner", serviceZipCodes: serviceZipCodes, services: services)
                                        isLoading = false
                                        
                                        masterDataManager.showSignInView = false
                                    } catch {
                                        print("Sign Up View Error")
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
                                .modifier(SubmitButtonModifier())
                            
                        }
                        .disabled(passwordDisabled)
                        .opacity(passwordDisabled ? 0.6 : 1)
                        
                        Spacer()
                    }
                    .padding(8)
                    Spacer()
                }
            }
            if isLoading {
                VStack{
                    Spacer()
                    LoadingSpinner()
                    Spacer()
                }
                
            }
            
        }
        .fontDesign(.monospaced)
        .navigationTitle("Welcome")
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
        .onChange(of: password, perform: { word in
            print("")
            print("Change in password")
            
            if word != "" {
                passwordDisabled = false

                if word.contains("!") || word.contains("#") || word.contains("@") || word.contains("$") || word.contains("^") || word.contains("*") || word.contains("(") || word.contains(")") || word.contains("+") || word.contains("=") {
                    print("Contains Special Charecters")
                    passwordDisabled = false
                } else {
                    print("Does Not Contains Special Charecters")
                    passwordDisabled = true
                }
                if word.count >= 8 {
                    print("Greater than 8")
                    passwordDisabled = false
                } else {
                    print("Less than 8")
                    passwordDisabled = true
                }
                if word == confirmPassword {
                    print("Equals confirmed Password")
                    
                    passwordDisabled = false
                } else {
                    print("Does not equal confirmed Password")
                    passwordDisabled = true
                }
            }
        })
        .onChange(of: confirmPassword, perform: { word in
            print("")
            print("Change in Confirm password")
            
            if word != "" {
                passwordDisabled = false

                if word.contains("!") || word.contains("#") || word.contains("@") || word.contains("$") || word.contains("^") || word.contains("*") || word.contains("(") || word.contains(")") || word.contains("+") || word.contains("=") {
                    print("Contains Special Charecters")
                    passwordDisabled = false
                } else {
                    print("Does Not Contains Special Charecters")
                    passwordDisabled = true
                }
                if word.count >= 8 {
                    print("Greater than 8")
                    passwordDisabled = false
                } else {
                    print("Less than 8")
                    passwordDisabled = true
                }
                if word == password {
                    print("Equals confirmed Password")
                    
                    passwordDisabled = false
                } else {
                    print("Does not equal confirmed Password")
                    passwordDisabled = true
                }
            }
        })
    }
}

