//
//  UserSettings.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/21/24.
//


import SwiftUI

struct UserSettings: View {
    //    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var customerVM : CustomerViewModel
    @EnvironmentObject var dataService : ProductionDataService

    init(dataService:any ProductionDataServiceProtocol){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
    }
    //    @StateObject private var trainingVM = TrainingViewModel()
    @StateObject private var VM : AuthenticationViewModel
    @StateObject private var companyVM = CompanyViewModel()
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var userAccessVM = UserAccessViewModel()

    @EnvironmentObject var customerViewModel: CustomerViewModel
    @State var isLoading = false
    @State var company:Company = Company(id: "",name: "")
    @State var companyIdList:[Company] = []
    @State var showChangeEmailScreen:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                HStack{
                    Text("System Settings")
                        .font(.headline)
                    Spacer()
                }
                systemSettings
                HStack{
                    Text("User Settings")
                        .font(.headline)
                    Spacer()
                }
                userSettings
            }
            .padding(.horizontal,16)
        }
        .onChange(of: company, perform: { change in
            if company.id != "" {
                masterDataManager.selectedCompany = change
            }
        })
        .task {
            do {
                if let user = masterDataManager.user {
                    print("\(user.id)")
                    try await companyVM.getCompaniesByUserAccessList(userId: user.id )
                    print("Success")
                } else {
                    masterDataManager.showSignInView = true
                }
            } catch {
                print("Failed to get User Access List - Page: Settings View")
            }
            if companyVM.listOfCompanies.count != 0 {
                company = companyVM.listOfCompanies.first!
                masterDataManager.selectedCompany = company
                companyIdList = companyVM.listOfCompanies
            }
        }
//        .navigationTitle("Settings")
        
    }
}

extension UserSettings {
    var systemSettings: some View {
        VStack{
            //Developer FIX ADD USER MANAGMENT VIA FIREBASE
            Text("System Settings")
        }
    }
    var userSettings: some View {
        VStack{
            
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
                                                masterDataManager.user = nil
                                                masterDataManager.showSignInView = true

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
                .padding(5)
                .background(Color.red)
                .cornerRadius(5)
            })
            .padding(.horizontal,16)
        }
    }
}
