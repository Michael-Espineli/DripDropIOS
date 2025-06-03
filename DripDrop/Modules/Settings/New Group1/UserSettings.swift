//
//  UserSettings.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/21/24.
//


import SwiftUI
@MainActor
final class UserSettingsViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var listOfCompanies: [Company] = []
    @Published var company:Company = Company(id: "", ownerId: "", ownerName: "", name: "", photoUrl: "", dateCreated: Date(), email: "", phoneNumber: "", verified: false, serviceZipCodes: [], services: [])
    @Published var showChangeCompanyScreen:Bool = false

    func onLoad(user:DBUser,selectedCompany:Company?) async throws {
        
        let accessList = try await UserAccessManager.shared.getAllUserAvailableCompanies(userId: user.id)
        print("Received List of \(accessList.count) Companies available to Access")
        var listOfCompanies:[Company] = []
        for access in accessList{
            let company = try await CompanyManager.shared.getCompany(companyId: access.id)// access id is company id
            listOfCompanies.append(company)
        }
        self.listOfCompanies = listOfCompanies
        if let selectedCompany {
            company = selectedCompany
        } else {
            if !listOfCompanies.isEmpty {
                company = listOfCompanies.first!
            }
        }
    }
    func updateRecentlySelectedCompanyWithCompanyId(user:DBUser,companyId:String) async throws {
        print("update Recently Selected Company")
        try await dataService.updateUserRecentlySelectedCompany(user: user, recentlySelectedCompanyId: company.id)
    }
    func updateRecentlySelectedCompany(user:DBUser) async throws {
        print("updateRecentlySelectedCompany")
        try await dataService.updateUserRecentlySelectedCompany(user: user, recentlySelectedCompanyId: company.id)
    }
    func resetPassword() throws {
        let user = try AuthenticationManager.shared.getAuthenticatedUser()
        guard let email = user.email else {
            print("Email is Optional")
            throw FireBasePublish.unableToPublish
        }
        if isValidEmail(email) {
            print("Is Valid Email")
            try AuthenticationManager.shared.resetPassword(email: email)
        } else {
            print("Is Not Valid Email")
            throw FireBasePublish.unableToPublish
        }
    }
    func signOut() throws{
        try AuthenticationManager.shared.signOut()
    }
}
struct UserSettings: View {
    //    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var customerVM : CustomerViewModel
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject private var VM : UserSettingsViewModel

    init(dataService:any ProductionDataServiceProtocol){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _VM = StateObject(wrappedValue: UserSettingsViewModel(dataService: dataService))
    }
    //    @StateObject private var trainingVM = TrainingViewModel()
    @StateObject private var companyVM = CompanyViewModel()
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var userAccessVM = UserAccessViewModel()

    @EnvironmentObject var customerViewModel: CustomerViewModel
    @State var isLoading = false
    @State var showChangeEmailScreen:Bool = false

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                companySettings
                Rectangle()
                    .frame(height: 1)
                    //----------------------------------------
                    //Add Back in During Roll out of Phase 2
                    //----------------------------------------
//                systemSettings
//                Rectangle()
//                    .frame(height: 1)
//                displayPrefrences
//                Rectangle()
//                    .frame(height: 1)
                userSettings
            }
            .padding(8)
        }
        .fontDesign(.monospaced)
        .foregroundColor(Color.basicFontText)
        .task {
            do {
                if let user = masterDataManager.user{
                    try await VM.onLoad(user: user,selectedCompany:masterDataManager.currentCompany)
                } else {
                    masterDataManager.showSignInView = true
                }
            } catch {
                print("Failed to get User Access List - Page: Settings View")
            }
        }
        .onChange(of: VM.company, perform: { changedCompany in
            Task{
                do {
                    if let selectedCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                        if changedCompany.id != "" && selectedCompany.id != changedCompany.id{
                            masterDataManager.currentCompany = changedCompany
                            try await VM.updateRecentlySelectedCompany(user: user)
                        }
                    }
                    
                } catch {
                    print(error)
                }
            }
        })
    }
}

extension UserSettings {
    var companySettings: some View {
        VStack{
            //Developer FIX ADD USER MANAGMENT VIA FIREBASE
            HStack{
                Text("Change Company:")
                Spacer()
                HStack{
                    Text("")
                        .bold(true)
                    Button(action: {
                        VM.showChangeCompanyScreen.toggle()
                    }, label: {
                        if let currentCompany = masterDataManager.currentCompany{
                            Text(currentCompany.name)
                                    .modifier(ListButtonModifier())
                        } else {
                            Text("Change Company")
                                .modifier(ListButtonModifier())
                        }
                    })
                    .sheet(isPresented: $VM.showChangeCompanyScreen, content: {
                        MyCompanyPickerView(dataService: dataService, company: $VM.company)
                    })
                }
            }
            
            //----------------------------------------
            //Add Back in During Roll out of Phase 2
            //----------------------------------------
//            HStack{
//                Text("Accept Copmpany Invite:")
//                Spacer()
//            }
        }
    }
    var systemSettings: some View {
        VStack{
            //Developer FIX ADD USER MANAGMENT VIA FIREBASE
            HStack{
            Spacer()
                Text("System Settings")
                    .font(.headline)
                Spacer()
            }
        }
    }
    var displayPrefrences: some View {
        VStack{
            Text("Display Preferences")
                .font(.headline)
            HStack{
                Text("Display Type:")
                Spacer()
                Picker("Main Screen Type", selection: $masterDataManager.mainScreenDisplayType, content: {
                    ForEach(MainScreenDisplayType.allCases,id:\.self){
                        Text($0.rawValue).tag($0)
                    }
                })
            }
            HStack{
                Text("Main Screen Configuration:")
                Spacer()
            }
        }
    }
    var userSettings: some View {
        VStack{
            HStack{
                Spacer()
                Text("User Settings")
                    .font(.headline)
                Spacer()
            }
            Button(action: {
                print("Change Password")
                Task{
                    do {
                        try VM.resetPassword()
                    } catch {
                        print("Error Reseting Password")
                    }
                }
            }, label: {
                HStack{
                    Text("Reset Password")
                }
                .frame(maxWidth: .infinity)

            })
            
           Divider()
                Spacer()
                Button(action: {
                    print("Send Password Reset Email")
                    showChangeEmailScreen.toggle()
                }, label: {
                    HStack{
                        
                        Text("Change Email")
                    }
                        .frame(maxWidth: .infinity)

                })
            .sheet(isPresented: $showChangeEmailScreen, content: {
                ChangeUserEmailView(dataService: dataService)
            })
            Divider()
            Button(action: {
                Task{
                    do {
                        try VM.signOut()
                        masterDataManager.showSignInView = true
                        masterDataManager.user = nil
                        masterDataManager.currentCompany = nil
                        masterDataManager.selectedCategory = nil
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }, label: {
                HStack{
                    Text("Log out")
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity)
                .modifier(DismissButtonModifier())
            })
            .padding(.horizontal,16)
        }
    }
}
