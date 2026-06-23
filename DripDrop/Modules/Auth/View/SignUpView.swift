//
//  SignUpView.swift
//  ClientSide
//
//  Created by Michael Espineli on 11/30/23.
//

import SwiftUI

struct SignUpView: View {
    init(dataService:any ProductionDataServiceProtocol, services:[String], serviceZipCodes:[String]) {
        self.authDataService = dataService
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
        _serviceZipCodes = State(wrappedValue: serviceZipCodes)
        _services = State(wrappedValue: services)
    }

    private let authDataService:any ProductionDataServiceProtocol

    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var VM : AuthenticationViewModel

    @State private var services:[String] = []
    @State private var serviceZipCodes:[String] = []

    @State private var email:String = ""
    @State private var password:String = ""
    @State private var confirmPassword:String = ""

    @State private var firstName:String = ""
    @State private var lastName:String = ""
    @State private var company:String = ""
    @State private var showingAlert:Bool = false
    @State private var alertMessage:String = ""

    @State private var isLoading:Bool = false

    @State private var agreeToTerms:Bool = false
    @State private var agreeToPrivacyPolicy:Bool = false

    @FocusState private var focusedField: SignUpFormLabels?

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    signUpCard
                }
                .frame(maxWidth: 460)
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
            }

            if isLoading {
                Color.black.opacity(0.12).ignoresSafeArea()

                VStack(spacing: 12) {
                    ProgressView()
                    Text("Creating Account...")
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .padding(24)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Alert", isPresented:$showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
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
                focusedField = .firstName
            }
        }
    }
}

private extension SignUpView {
    var header: some View {
        HStack {
            Text("Drip Drop")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.blue)
            Spacer()
        }
    }

    var signUpCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Create Your Company Account")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.center)

                Text("Account Information")
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                nameFields

                signUpTextField(
                    placeholder: "Company Name",
                    text: $company,
                    focusedValue: .companyName,
                    submitLabel: .next
                )

                signUpTextField(
                    placeholder: "Email address",
                    text: $email,
                    focusedValue: .email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    submitLabel: .next
                )

                signUpSecureField(
                    placeholder: "Password (8+ characters)",
                    text: $password,
                    focusedValue: .password,
                    submitLabel: .next
                )

                signUpSecureField(
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    focusedValue: .confirmPassword,
                    submitLabel: .done
                )
            }

            passwordRequirements
            agreements

            Button {
                submit()
            } label: {
                Text(isLoading ? "Creating Account..." : "Complete Sign Up")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Color.white)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.6)

            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundStyle(Color(.secondaryLabel))

                    NavigationLink {
                        SignInView(dataService: authDataService)
                    } label: {
                        Text("Sign In")
                            .fontWeight(.medium)
                            .foregroundStyle(Color.blue)
                    }
                }

                VStack(spacing: 4) {
                    Text("Have an invite code?")
                        .foregroundStyle(Color(.secondaryLabel))

                    NavigationLink {
                        RedeemInviteCode(dataService:authDataService)
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

    @ViewBuilder
    var nameFields: some View {
        if UIDevice.isIPhone {
            VStack(spacing: 16) {
                signUpTextField(
                    placeholder: "First Name",
                    text: $firstName,
                    focusedValue: .firstName,
                    textContentType: .givenName,
                    submitLabel: .next
                )

                signUpTextField(
                    placeholder: "Last Name",
                    text: $lastName,
                    focusedValue: .lastName,
                    textContentType: .familyName,
                    submitLabel: .next
                )
            }
        } else {
            HStack(spacing: 14) {
                signUpTextField(
                    placeholder: "First Name",
                    text: $firstName,
                    focusedValue: .firstName,
                    textContentType: .givenName,
                    submitLabel: .next
                )

                signUpTextField(
                    placeholder: "Last Name",
                    text: $lastName,
                    focusedValue: .lastName,
                    textContentType: .familyName,
                    submitLabel: .next
                )
            }
        }
    }

    var agreements: some View {
        VStack(alignment: .leading, spacing: 12) {
            agreementRow(
                isSelected: $agreeToPrivacyPolicy,
                title: "I agree to the Drip Drop Privacy Policy",
                url: "https://dripdrop-poolapp.com/PrivacyPolicy"
            )

            agreementRow(
                isSelected: $agreeToTerms,
                title: "I agree to the Drip Drop Terms",
                url: "https://dripdrop-poolapp.com/TermsAndConditions"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var passwordRequirements: some View {
        VStack(alignment: .leading, spacing: 8) {
            requirementRow("At least 8 characters", isMet: passwordIsLongEnough)
            requirementRow("Contains a special character", isMet: passwordContainsSpecialCharacter)
            requirementRow("Passwords match", isMet: passwordsMatch)
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func signUpTextField(
        placeholder:String,
        text:Binding<String>,
        focusedValue:SignUpFormLabels,
        keyboardType:UIKeyboardType = .default,
        textContentType:UITextContentType? = nil,
        submitLabel:SubmitLabel
    ) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
            .autocorrectionDisabled(keyboardType == .emailAddress)
            .submitLabel(submitLabel)
            .focused($focusedField, equals: focusedValue)
            .modifier(CompanySignUpInputModifier())
    }

    func signUpSecureField(
        placeholder:String,
        text:Binding<String>,
        focusedValue:SignUpFormLabels,
        submitLabel:SubmitLabel
    ) -> some View {
        SecureField(placeholder, text: text)
            .textContentType(.password)
            .submitLabel(submitLabel)
            .focused($focusedField, equals: focusedValue)
            .modifier(CompanySignUpInputModifier())
    }

    func agreementRow(isSelected:Binding<Bool>, title:String, url:String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                isSelected.wrappedValue.toggle()
            } label: {
                Image(systemName: isSelected.wrappedValue ? "checkmark.square.fill" : "square")
                    .font(.body)
                    .foregroundStyle(isSelected.wrappedValue ? Color.blue : Color(.secondaryLabel))
            }
            .buttonStyle(.plain)

            if let url = URL(string: url) {
                Link(title, destination: url)
                    .font(.caption)
                    .foregroundStyle(Color.blue)
            }
        }
    }

    func requirementRow(_ title:String, isMet:Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isMet ? Color.green : Color(.tertiaryLabel))
            Text(title)
                .foregroundStyle(isMet ? Color(.label) : Color(.secondaryLabel))
            Spacer()
        }
    }

    var passwordIsLongEnough: Bool {
        password.count >= 8
    }

    var passwordContainsSpecialCharacter: Bool {
        password.rangeOfCharacter(from: CharacterSet(charactersIn: "!#@$^*()+=")) != nil
    }

    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    var canSubmit: Bool {
        passwordIsLongEnough &&
        passwordContainsSpecialCharacter &&
        passwordsMatch &&
        agreeToTerms &&
        agreeToPrivacyPolicy &&
        !isLoading
    }

    func submit() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCompany = company.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty {
            showAlert("Please enter your email address.")
            return
        }

        if password.isEmpty {
            showAlert("Please enter a password.")
            return
        }

        if !passwordIsLongEnough {
            showAlert("Password must be at least 8 characters long.")
            return
        }

        if !passwordContainsSpecialCharacter {
            showAlert("Password must contain a special character.")
            return
        }

        if password != confirmPassword {
            showAlert("Passwords do not match.")
            return
        }

        if trimmedFirstName.isEmpty {
            showAlert("Please enter your first name.")
            return
        }

        if trimmedLastName.isEmpty {
            showAlert("Please enter your last name.")
            return
        }

        if trimmedCompany.isEmpty {
            showAlert("Please enter your company name.")
            return
        }

        if !agreeToTerms {
            showAlert("Please agree to the Terms and Conditions.")
            return
        }

        if !agreeToPrivacyPolicy {
            showAlert("Please agree to the Privacy Policy.")
            return
        }

        Task {
            do {
                isLoading = true
                defer { isLoading = false }

                try await VM.signUpWithEmailAndCreateCompany(
                    email: trimmedEmail,
                    password: password,
                    firstName: trimmedFirstName,
                    lastName: trimmedLastName,
                    company: trimmedCompany,
                    position: "Owner",
                    serviceZipCodes: serviceZipCodes,
                    services: services
                )

                masterDataManager.showSignInView = false
            } catch {
                print("Sign Up View Error")
                print(error)
                showAlert("Unable to create account. Please try again.")
            }
        }
    }

    func showAlert(_ message:String) {
        alertMessage = message
        showingAlert = true
    }
}

private struct CompanySignUpInputModifier: ViewModifier {
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
