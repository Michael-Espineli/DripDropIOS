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
    
    @State var agreeToTerms:Bool = false
    @State var agreeToPrivacyPolicy:Bool = false
    
    @FocusState private var focusedField: SignUpFormLabels?
    func submit(){
        if password == confirmPassword {
            Task{
                do{
                    isLoading = true
                    if !agreeToTerms {
                        
                        alertMessage = "Please Agree to Terms and Conditions"
                        print(alertMessage)
                        showingAlert = true
                        isLoading = false
                        return
                        
                    }
                    if !agreeToPrivacyPolicy{
                        
                        alertMessage = "Please Agree to Privacy Policy"
                        print(alertMessage)
                        showingAlert = true
                        isLoading = false
                        return
                        
                    }
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
                    
                    isLoading = false
                    print("Sign Up View Error")
                    print(error)
                }
            }
        } else {
            alertMessage = "Passwords Do Not Match"
            print(alertMessage)
            showingAlert = true
        }
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            
            if UIDevice.isIPhone {
                ScrollView{
                    form
                        .padding(.horizontal, 8)
                }
            } else {
                VStack{
                    form
                        .padding(.horizontal, 32)
                    Spacer()
                }
            }
            if isLoading {
                VStack{
                    Spacer()
                    GenericLoadingView()
                    Spacer()
                }
                
            }
            
        }
        .fontDesign(.monospaced)
        .navigationTitle("Welcome To Drip Drop")
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
                    print("Contains Special Characters")
                    passwordDisabled = false
                } else {
                    print("Does Not Contains Special Characters")
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
        .onSubmit {
            switch focusedField {
            case .firstName:
                focusedField = .lastName
            case .lastName:
                focusedField = .companyName
            case .companyName:
                focusedField = .email
            case .email:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                submit()
            case .none:
                focusedField = .lastName
            }
        }
    }
}
extension SignUpView {
    var form: some View {
        VStack{
            VStack{
                VStack{
                    HStack{
                        Text("First Name:")
                            //                                .font(.footnote)
                        Spacer()
                    }
                    TextField(
                        "First Name",
                        text: $firstName
                    )
                    .modifier(PlainTextFieldModifier())
                    .focused($focusedField, equals: .firstName)
                    .submitLabel(.next)
                    HStack{
                        Text("Last Name:")
                            //                                .font(.footnote)
                        Spacer()
                    }
                    TextField(
                        "Last Name",
                        text: $lastName
                    )
                    .modifier(PlainTextFieldModifier())
                    .focused($focusedField, equals: .lastName)
                    .submitLabel(.next)
                    HStack{
                        Text("Company Name:")
                            //                                .font(.footnote)
                        Spacer()
                    }
                    TextField(
                        "Company",
                        text: $company
                    )
                    .modifier(PlainTextFieldModifier())
                    .focused($focusedField, equals: .companyName)
                    .submitLabel(.next)
                    
                    VStack{
                        HStack{
                            Text("Email:")
                                //                                    .font(.footnote)
                            Spacer()
                        }
                        TextField(
                            "Email",
                            text: $email
                        )
                        .modifier(PlainTextFieldModifier())
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        HStack{
                            Text("Password:")
                                //                                    .font(.footnote)
                            Spacer()
                        }
                        SecureField(
                            "Password",
                            text: $password
                        )
                        .modifier(PlainTextFieldModifier())
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        
                    }
                    HStack{
                        Text("Confirm Password:")
                            //                                .font(.footnote)
                        Spacer()
                    }
                    SecureField(
                        "Confirm Password",
                        text: $confirmPassword
                    )
                    .modifier(PlainTextFieldModifier())
                    .focused($focusedField, equals: .confirmPassword)
                    .submitLabel(.done)
                    
                }
                VStack(alignment: .leading){
                    HStack{
                        Button(action: {
                            agreeToPrivacyPolicy.toggle()
                        }, label: {
                            if agreeToPrivacyPolicy {
                                Image(systemName: "checkmark.square.fill")
                            } else {
                                Image(systemName: "square")
                            }
                        })
                        if let url = URL(string: "https://dripdrop-poolapp.com/PrivacyPolicy"){
                            Link("I agree to the Drip Drop Privacy Policy", destination: url)
                                .font(.caption)
                        }
                    }
                    HStack{
                        Button(action: {
                            agreeToTerms.toggle()
                        }, label: {
                            if agreeToTerms {
                                Image(systemName: "checkmark.square.fill")
                            } else {
                                Image(systemName: "square")
                            }
                        })
                        if let url = URL(string: "https://dripdrop-poolapp.com/TermsAndConditions"){
                            Link("I agree to the Drop Drop Terms", destination: url)
                                .font(.caption)
                        }
                    }
                }
                .padding(.trailing,8)
                Button{
                    submit()
                } label: {
                    HStack{
                        Spacer()
                        Text("Submit")
                        Spacer()
                    }
                    .modifier(SubmitButtonModifier())
                }
                .disabled(passwordDisabled || !agreeToTerms || !agreeToPrivacyPolicy)
                .opacity(passwordDisabled || !agreeToTerms || !agreeToPrivacyPolicy ? 0.6 : 1)
            }
            .padding(16)
            .background(Color.darkGray.opacity(0.5))
            .cornerRadius(8)
            
            VStack(alignment: .leading){
                if password != "" {
                    if password.contains("!") || password.contains("#") || password.contains("@") || password.contains("$") || password.contains("^") || password.contains("*") || password.contains("(") || password.contains(")") || password.contains("+") || password.contains("=") {
                        HStack{
                            Text("Contains Special Characters")
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .foregroundColor(Color.poolGreen)
                    } else {
                        Text("Must Contain Special Characters")
                            .foregroundColor(Color.red)
                    }
                    if password.count >= 8 {
                        HStack{
                            Text("Must Be Longer than 8 Characters")
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .foregroundColor(Color.poolGreen)
                    } else {
                        Text("Must Be Longer than 8 Characters")
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
                } else{
                    Text("Password Must Be Longer than 8 Characters")
                    Text("Password Must Contain Special Characters")
                }
            }
            
                .font(.caption)
        }
    }
}
