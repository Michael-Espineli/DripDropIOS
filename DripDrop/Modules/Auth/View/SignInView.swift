//
//  SignInView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//

import SwiftUI

struct SignInView: View {
    init(dataService:any ProductionDataServiceProtocol) {
        self.dataService = dataService
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
    }

    private let dataService:any ProductionDataServiceProtocol

    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var VM : AuthenticationViewModel

    @FocusState private var focusedField: SignInFormLabels?
    @State private var email:String = ""
    @State private var password:String = ""
    @State private var isSigningIn:Bool = false
    @State private var isSendingPasswordReset:Bool = false
    @State private var showAlertMessage:String = ""
    @State private var showAlert:Bool = false

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    signInCard
                    footerLinks
                }
                .frame(maxWidth: 430)
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(showAlertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onSubmit {
            switch focusedField {
            case .userName, .email:
                focusedField = .password
            case .password:
                Task { await signIn() }
            case .companyName, .none:
                focusedField = .password
            }
        }
    }
}

private extension SignInView {
    var header: some View {
        HStack {
            Text("Drip Drop")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.blue)
            Spacer()
        }
    }

    var signInCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Company Sign In")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.center)

                Text("Access your company dashboard.")
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                TextField("Email address", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedField, equals: .userName)
                    .modifier(CompanySignInInputModifier())

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .password)
                    .modifier(CompanySignInInputModifier())

                HStack {
                    Spacer()
                    Button {
                        Task { await sendPasswordReset() }
                    } label: {
                        Text(isSendingPasswordReset ? "Sending reset email..." : "Forgot your password?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.blue)
                    }
                    .disabled(isSendingPasswordReset)
                }
            }

            Button {
                Task { await signIn() }
            } label: {
                Text(isSigningIn ? "Signing In..." : "Sign In")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Color.white)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .disabled(isSigningIn)
            .opacity(isSigningIn ? 0.6 : 1)

            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("Don't have a company account?")
                        .foregroundStyle(Color(.secondaryLabel))

                    NavigationLink {
                        IndustryTypePicker(dataService: dataService)
                    } label: {
                        Text("Sign up")
                            .fontWeight(.medium)
                            .foregroundStyle(Color.blue)
                    }
                }

                VStack(spacing: 4) {
                    Text("Have an invite code?")
                        .foregroundStyle(Color(.secondaryLabel))

                    NavigationLink {
                        RedeemInviteCode(dataService:dataService)
                    } label: {
                        Text("Redeem it here")
                            .fontWeight(.medium)
                            .foregroundStyle(Color.blue)
                    }
                }
            }
            .font(.footnote)
            .multilineTextAlignment(.center)
        }
        .padding(28)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
    }

    var footerLinks: some View {
        Text("Espineli L.L.C.")
            .font(.footnote)
            .foregroundStyle(Color(.secondaryLabel))
    }

    func signIn() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            showAlertMessage = "Please fill out both email and password."
            showAlert = true
            return
        }

        isSigningIn = true
        defer { isSigningIn = false }

        do {
            print("Attempting Sign in")
            try await VM.signInWithEmail(email: trimmedEmail, password: password)
            print("Signed in Successfully")
            let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
            let user = try await DBUserManager.shared.getCurrentUser(userId: authDataResult.uid)
            masterDataManager.user = user
            masterDataManager.showSignInView = false
        } catch {
            password = ""
            try? VM.signOut()
            showAlertMessage = "Invalid email or password."
            showAlert = true
            print("Error >> \(error)")
        }
    }

    func sendPasswordReset() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            showAlertMessage = "Enter your email address first."
            showAlert = true
            return
        }

        isSendingPasswordReset = true
        defer { isSendingPasswordReset = false }

        do {
            try await VM.sendPasswordReset(email: trimmedEmail)
            showAlertMessage = "Password reset email sent."
            showAlert = true
        } catch {
            showAlertMessage = "Unable to send reset email. Please check the email address and try again."
            showAlert = true
            print("Password reset error >> \(error)")
        }
    }
}

private struct CompanySignInInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundStyle(Color(.label))
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 1)
            )
    }
}

struct SignInView_Previews: PreviewProvider {
    static let dataService = MockDataService()

    static var previews: some View {
        NavigationStack {
            SignInView(dataService:dataService)
        }
    }
}
