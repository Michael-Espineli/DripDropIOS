//
//  SignInView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//

import SwiftUI

struct SignInView: View {
    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
    }
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var VM : AuthenticationViewModel

    @FocusState private var focusedField: SignInFormLabels?
    @State var email:String = ""
    @State var password:String = ""
    @State var showForgotPasswordSheet:Bool = false
    @State var showForgotUserNameSheet:Bool = false
    @State var showAlertMessage:String = ""
    @State var showAlert:Bool = false
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                    Spacer()
                
                VStack{
                    Text("Sign In")
                        .font(.title)
                        .foregroundColor(Color.poolWhite)
                    VStack{
                        HStack{
                            Text("Email")
                                .foregroundColor(Color.poolWhite)
                                .font(.headline)
                            Spacer()
                        }
                        HStack{
                                TextField(
                                    "Email",
                                    text: $email
                                )
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.black)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 20)
                                .background(Color.poolWhite)
                                .clipShape(Capsule())
                                .focused($focusedField, equals: .userName)
                                     .submitLabel(.next)
                        }
                        .foregroundColor(Color.white)
                        //                    .cornerRadius(5)
                        HStack{
                            Text("Password")
                                .foregroundColor(Color.poolWhite)
                                .font(.headline)
                            Spacer()
                        }
                        HStack{
                                SecureField(
                                    "Password",
                                    text: $password
                                )
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.black)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 20)
                                .background(Color.poolWhite)
                                .clipShape(Capsule())
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                        }
                        .foregroundColor(Color.white)
                    }
                    .padding(.bottom,48)
                    VStack{
                        Button{
                            Task{
                                do{
                                    print("Attempting Sign in")
                                    
                                    try await VM.signInWithEmail(email: email, password: password)
                                    print("Signed in Successfully")
                                    let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
                                    let user = try await DBUserManager.shared.getCurrentUser(userId: authDataResult.uid)

                                    masterDataManager.user = user
                                    masterDataManager.showSignInView = false
                                    
                                } catch {
                                    password = ""
                                    try VM.signOut()
                                    showAlertMessage = "Failed to login"
                                    showAlert = true
                                    print("Error >> \(error)")
                                }
                            }
                        } label: {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(Color.poolWhite)
                                .padding(5)
                                .background(Color.poolBlue)
                                .clipShape(Capsule())
                        }
                        .padding(8)
                        NavigationLink(destination: {
                            SignUpTypePicker()
                            
                        }, label: {
                            Text("Create Account")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(Color.poolBlue)
                                .padding(5)
                                .background(Color.poolWhite)
                                .clipShape(Capsule())
                        })
                        .padding(8)
                    }
                    .padding(.horizontal,40)
                }
                .padding(8)
                .background(Color.darkGray.opacity(0.5))
                .cornerRadius(8)
                HStack{
                    Button(action: {
                        showForgotUserNameSheet.toggle()
                    }, label: {
                        Text("Forgot User Name")
                
                            .foregroundColor(Color.red)
                    })
                    .sheet(isPresented: $showForgotUserNameSheet, content: {
                        Text("Build Recover User Name Sheet")
                    })
                    Spacer()
                    Button(action: {
                        showForgotPasswordSheet.toggle()
                    }, label: {
                        Text("Forgot Password")
                            .foregroundColor(Color.red)
                        
                    })
                    .sheet(isPresented: $showForgotPasswordSheet, content: {
                        Text("Build Recover Password Sheet")
                    })
                }
                Spacer()
                Text("© Espineli L.L.C.")
                    .font(.footnote)
                    .padding(8)
            }
            .padding(.horizontal, 16)
            .onSubmit {
                   switch focusedField {
      
                   case .userName:
                       focusedField = .password
                   case .password:
                       Task{
                           do{
                               print("Attempting Sign in")
                               
                               try await VM.signInWithEmail(email: email, password: password)
                               print("Signed in Successfully")
                               let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
                               let user = try await DBUserManager.shared.getCurrentUser(userId: authDataResult.uid)

                               masterDataManager.user = user
                               masterDataManager.showSignInView = false
                               
                           } catch {
                               password = ""
                               try VM.signOut()
                               showAlertMessage = "Failed to login"
                               showAlert = true
                               print("Error >> \(error)")
                           }
                       }
                   case .email, .companyName:
                       focusedField = .password
                   case .none:
                       focusedField = .password
                   }
               }

        }
        .alert(showAlertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static let dataService = MockDataService()

    static var previews: some View {
        SignInView(dataService:dataService)
    }
}
