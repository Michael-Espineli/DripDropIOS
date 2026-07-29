//
//  EditProfileView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/9/23.
//

import SwiftUI
@MainActor
final class EditProfileViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var canUpdate : Bool = false
    @Published var confirmCancellation : Bool = false
    @Published var confirmUpdate : Bool = false
    @Published var firstName : String = ""
    @Published var lastName : String = ""
    @Published var phoneNumber : String = ""
    @Published var email : String = ""
    @Published var bio : String = ""
    func onLoad(tech:DBUser) async{
        self.firstName = tech.firstName
        self.lastName = tech.lastName
        self.phoneNumber = tech.phoneNumber ?? ""
        self.email = tech.email
        self.bio = tech.bio ?? ""
    }
    func checkChanges(tech:DBUser){
        if tech.firstName != firstName || tech.lastName != lastName || tech.phoneNumber != phoneNumber || tech.email != email || tech.bio != bio{
            if firstName == "" || lastName == "" || email == "" || phoneNumber == "" || bio == ""{
                self.canUpdate = false
            } else {
                self.canUpdate = true
            }
        } else {
            self.canUpdate = false
        }
    }
    
    func confirmUpdate(tech:DBUser) async throws -> DBUser?{
   
            if tech.firstName != firstName {
                try dataService.updateDBUserFirstName(userId: tech.id, firstName: firstName)
            }
            if tech.lastName != lastName {
                try dataService.updateDBUserLastName(userId: tech.id, lastName: lastName)
            }
            if tech.phoneNumber != phoneNumber {
                try dataService.updateDBUserPhoneNumber(userId: tech.id, phoneNumber: phoneNumber)
            }
            if tech.email != email {
                try dataService.updateDBUserEmail(userId: tech.id, email: email)
            }
            if tech.bio != bio{
                try dataService.updateDBUserBio(userId: tech.id, bio: bio)
            }
            return try await dataService.getOneUser(userId: tech.id)
    }
    func cancelUpDate(tech:DBUser){
        self.firstName = tech.firstName
        self.lastName = tech.lastName
        self.phoneNumber = tech.phoneNumber ?? ""
        self.email = tech.email
        self.bio = tech.bio ?? ""
    }
}
struct EditProfileView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @State var tech: DBUser
    init(dataService: any ProductionDataServiceProtocol, tech:DBUser){
        _VM = StateObject(wrappedValue: EditProfileViewModel(dataService: dataService))
        _tech = State(wrappedValue: tech)
        
    }
    @StateObject var VM : EditProfileViewModel
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    profileDetailsCard
                    actionSection
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Edit User Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Save profile changes?", isPresented:$VM.confirmUpdate) {
            Button("Save Changes") {
                Task {
                    do {
                        let updatedUser = try await VM.confirmUpdate(tech: tech)
                        masterDataManager.user = updatedUser
                        if let updatedUser {
                            tech = updatedUser
                            VM.canUpdate = false
                        }
                    } catch {
                        print(error)
                    }
                }
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Your profile information will be updated immediately.")
        }
        .alert("Discard profile changes?", isPresented:$VM.confirmCancellation) {
            Button("Discard Changes", role: .destructive) {
                VM.cancelUpDate(tech: tech)
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("This resets the form back to the current saved profile.")
        }
        .task {
            await VM.onLoad(tech: tech)
        }
        .onChange(of: VM.firstName, perform: { change in
            VM.checkChanges(tech: tech)
        })
        .onChange(of: VM.lastName, perform: { change in
            VM.checkChanges(tech: tech)
        })
        .onChange(of: VM.email, perform: { change in
            VM.checkChanges(tech: tech)
        })
        .onChange(of: VM.phoneNumber, perform: { change in
            VM.checkChanges(tech: tech)
        })
        .onChange(of: VM.bio, perform: { change in
            VM.checkChanges(tech: tech)
        })
    }
}

extension EditProfileView {
    private var displayName: String {
        let firstName = VM.firstName.isEmpty ? tech.firstName : VM.firstName
        let lastName = VM.lastName.isEmpty ? tech.lastName : VM.lastName
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "User Profile" : name
    }

    private var displayEmail: String {
        VM.email.isEmpty ? tech.email : VM.email
    }

    private var hasChanges: Bool {
        tech.firstName != VM.firstName ||
        tech.lastName != VM.lastName ||
        (tech.phoneNumber ?? "") != VM.phoneNumber ||
        tech.email != VM.email ||
        (tech.bio ?? "") != VM.bio
    }

    private var hasMissingRequiredField: Bool {
        VM.firstName.isEmpty ||
        VM.lastName.isEmpty ||
        VM.phoneNumber.isEmpty ||
        VM.email.isEmpty ||
        VM.bio.isEmpty
    }

    private var initials: String {
        let firstInitial = (VM.firstName.isEmpty ? tech.firstName : VM.firstName).first.map(String.init) ?? ""
        let lastInitial = (VM.lastName.isEmpty ? tech.lastName : VM.lastName).first.map(String.init) ?? ""
        let combined = "\(firstInitial)\(lastInitial)"
        return combined.isEmpty ? "?" : combined.uppercased()
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            profileAvatar

            VStack(alignment: .leading, spacing: 5) {
                Text(displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Label(displayEmail, systemImage: "envelope")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .editProfileCardStyle()
    }

    private var profileAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.16))
                .frame(width: 64, height: 64)

            if let urlString = tech.photoUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 64, height: 64)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    case .failure:
                        avatarInitials
                    @unknown default:
                        avatarInitials
                    }
                }
            } else {
                avatarInitials
            }
        }
        .overlay {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }

    private var avatarInitials: some View {
        Text(initials)
            .font(.title3.weight(.bold))
            .foregroundStyle(Color.accentColor)
            .frame(width: 64, height: 64)
    }

    private var profileDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Profile Details", systemImage: "person.text.rectangle")

            profileField(
                "First Name",
                text: $VM.firstName,
                placeholder: "First name",
                systemImage: "person",
                textContentType: .givenName,
                textInputAutocapitalization: .words
            )

            profileField(
                "Last Name",
                text: $VM.lastName,
                placeholder: "Last name",
                systemImage: "person",
                textContentType: .familyName,
                textInputAutocapitalization: .words
            )

            profileField(
                "Phone Number",
                text: $VM.phoneNumber,
                placeholder: "Phone number",
                systemImage: "phone",
                keyboardType: .phonePad,
                textContentType: .telephoneNumber
            )

            profileField(
                "Email",
                text: $VM.email,
                placeholder: "Email address",
                systemImage: "at",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                textInputAutocapitalization: .never
            )

            bioEditor
        }
        .padding(16)
        .editProfileCardStyle()
    }

    private var bioEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "text.alignleft")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20)

                Text("Bio")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if VM.bio.isEmpty {
                    requiredBadge
                }
            }

            ZStack(alignment: .topLeading) {
                if VM.bio.isEmpty {
                    Text("Write a short bio")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $VM.bio)
                    .font(.body)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(8)
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(VM.bio.isEmpty ? Color.poolRed.opacity(0.35) : Color.primary.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private var actionSection: some View {
        Group {
            if VM.canUpdate {
                HStack(spacing: 12) {
                    Button {
                        VM.confirmCancellation = true
                    } label: {
                        Label("Discard", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(Color.poolRed)

                    Button {
                        VM.confirmUpdate = true
                    } label: {
                        Label("Save", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Color.poolBlue)
                }
                .padding(.top, 2)
            } else {
                statusCard
            }
        }
        .animation(.easeInOut(duration: 0.2), value: VM.canUpdate)
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: hasChanges && hasMissingRequiredField ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(hasChanges && hasMissingRequiredField ? Color.poolRed : Color.poolGreen)

            VStack(alignment: .leading, spacing: 3) {
                Text(hasChanges && hasMissingRequiredField ? "Finish required fields" : "No Changes")
                    .font(.subheadline.weight(.semibold))

                Text(hasChanges && hasMissingRequiredField ? "All fields must be filled in before saving." : "Make an update to enable saving.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    private func profileField(
        _ title: String,
        text: Binding<String>,
        placeholder: String,
        systemImage: String,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        textInputAutocapitalization: TextInputAutocapitalization? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20)

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if text.wrappedValue.isEmpty {
                    requiredBadge
                }
            }

            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.body)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(textInputAutocapitalization)
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(text.wrappedValue.isEmpty ? Color.poolRed.opacity(0.35) : Color.primary.opacity(0.08), lineWidth: 1)
                }
        }
    }

    private var requiredBadge: some View {
        Text("Required")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.poolRed)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.poolRed.opacity(0.12), in: Capsule())
    }
}

private extension View {
    func editProfileCardStyle() -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(dataService: ProductionDataService(), tech: DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: ""))
    }
}
