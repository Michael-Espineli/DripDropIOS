//
//  SettingsView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//


import SwiftUI

struct SettingsView: View {
    init(dataService:any ProductionDataServiceProtocol){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
        _userSettingsViewModel = StateObject(wrappedValue: UserSettingsViewModel(dataService: dataService))
    }

    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var customerViewModel: CustomerViewModel
    
    @StateObject var userSettingsViewModel: UserSettingsViewModel

    @StateObject private var VM : AuthenticationViewModel
    @StateObject private var companyVM = CompanyViewModel()
    @StateObject private var userAccessVM = UserAccessViewModel()
    @StateObject private var customerVM : CustomerViewModel
    @StateObject var roleVM = RoleViewModel()

    @State var company:Company = Company(id: "", ownerId: "", ownerName: "", name: "", photoUrl: "", dateCreated: Date(), email: "", phoneNumber: "", verified: false, serviceZipCodes: [], services: [])
    @State var companyIdList:[Company] = []
    @State var showChangeEmailScreen:Bool = false
    @State var isLoading = false
    @State var showReedemInviteCode = false

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Text("Settings View")
                    .fontWeight(.bold)
                Rectangle()
                    .frame(height: 2)
//                companySettings
                UserSettings(dataService: dataService)

//                settings
//                
//                Rectangle()
//                    .frame(height: 1)
                    //----------------------------------------
                    //Add Back in During Roll out of Phase 2
                    //----------------------------------------
            }
            .padding(8)
        }
        .fontDesign(.monospaced)
        .task {
            do {
                if let user = masterDataManager.user {
                    print("\(user.id)")
                    try await companyVM.getCompaniesByUserAccessList(userId: user.id )
                    print("Success")
                } else {
                    masterDataManager.showSignInView = true
                }
                if companyVM.listOfCompanies.count != 0 {
                    if let selectedCompany = masterDataManager.currentCompany {
                        company = companyVM.listOfCompanies.first(where: {$0.id == selectedCompany.id})!                        
                    }
                    companyIdList = companyVM.listOfCompanies
                }
            } catch {
                print("Failed to get User Access List - Page: Settings View")
            }
        }
        .onChange(of: company, perform: { change in
            Task{
            //Developer Change Role of Company On change of current company
                if let selectedCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                    try await userSettingsViewModel.updateRecentlySelectedCompanyWithCompanyId(user: user, companyId: change.id)

                    if change.id != "" && selectedCompany.id != change.id{
                        masterDataManager.currentCompany = change
                        try await userAccessVM.getUserAccessCompanies(userId: user.id, companyId: company.id)
                        if let access = userAccessVM.userAccess{
                            print("Mobile Home Access >> \(access)")
                            try await roleVM.getSpecificRole(companyId: company.id, roleId: access.roleId)
                            if let role = roleVM.role {
                                masterDataManager.role = role
                            } else {
                                masterDataManager.showSignInView = true
                            }
                        } else {
                            masterDataManager.showSignInView = true
                        }
                    } else {
                    }
                } else {
                    print("No selected Company or User")
                }
            }
        })
    }
}

extension SettingsView {
    var companySettings: some View {
        VStack(alignment:.leading){
            HStack{
                Text("Company:")
                    .fontWeight(.bold)
                if companyVM.listOfCompanies.count != 0 {
                    Picker("", selection: $company) {
                        Text("Pick Company")
                        ForEach(companyVM.listOfCompanies) {
                            Text($0.name).tag($0)
                        }
                    }
                    .modifier(ListButtonModifier())
                } else {
                    Text("Pick Company")
                        .modifier(ListButtonModifier())
                }
                
            }
            Rectangle()
                .frame(height: 1)
            HStack{
                Button(action: {
                    showReedemInviteCode.toggle()
                }, label: {
                    Text("Reedem Invite Code")
                        .modifier(ListButtonModifier())
                })
                .sheet(isPresented: $showReedemInviteCode, content: {
                    RedeemInviteCode(dataService: dataService)
                })
                Spacer()
            }
            Rectangle()
                .frame(height: 1)
        }
    }
    var settings: some View {
        VStack{
            HStack{
                Text("Settings")
                    .fontDesign(.monospaced)
                Spacer()
//                if UIDevice.isIPhone {
//                    NavigationLink(value: Route.settings(
//                        dataService: dataService
//                    ),label: {
//                        HStack{
//                            Text("See More")
//                            Image(systemName: "chevron.right")
//                        }
//                        .padding(3)
//                    })
//                } else {
//                    Button(action: {
//                        masterDataManager.selectedCategory = .settings
//                    }, label: {
//                        
//                        HStack{
//                            Text("See More")
//                            Image(systemName: "chevron.right")
//                        }
//                        .padding(3)
//                    })
//                }
//                
            }
            .foregroundColor(Color.basicFontText)
            if UIDevice.isIPhone {
                ScrollView(showsIndicators: false){
                    NavigationLink(value: Route.taskGroups(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Spacer()
                            Text("Task Groups")
                            Spacer()
                        }
                        .modifier(HeaderModifier())
                        
                    })
                    NavigationLink(value: Route.readingsAndDosages(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Spacer()
                            Text("Readings And Dosages")
                            Spacer()
                        }
                        .modifier(HeaderModifier())
                        
                    })
                    
                    NavigationLink(value: Route.databaseItems(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Spacer()
                            Text("Data Base")
                            Spacer()
                        }
                        .modifier(HeaderModifier())
                        
                    })
                    
                    NavigationLink(value: Route.jobTemplates(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Spacer()
                            Text("Jobs Templates")
                            Spacer()
                        }
                        .modifier(HeaderModifier())
                    })
                    
                    NavigationLink(value: Route.reports(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Spacer()
                            Text("Reports")
                            Spacer()
                        }
                        .modifier(HeaderModifier())
                    })
                    NavigationLink(value: Route.userRoles(
                        dataService: dataService
                    ),label: {
                        HStack{
                            Spacer()
                            Text("User Roles")
                            Spacer()
                        }
                        .modifier(HeaderModifier())
                    })
                }
            } else {
                
                //Mac List
                ScrollView(showsIndicators: false){
                    Button(action: {
                        masterDataManager.selectedCategory = .taskGroups
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Task Groups")
                            Spacer()
                        }
                        .modifier(HeaderModifier())
                    })
                    Button(action: {
                        masterDataManager.selectedCategory = .readingsAndDosages
                        
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Readings And Dosages")
                            Spacer()
                        }
                        .modifier(HeaderModifier())
                    })
                    Button(action: {
                        masterDataManager.selectedCategory = .databaseItems
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Data Base")
                            Spacer()
                        }
                        .modifier(HeaderModifier())
                    })
                    Button(action: {
                        masterDataManager.selectedCategory = .jobTemplates
                        
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Jobs Templates")
                            Spacer()
                        }
                        .modifier(HeaderModifier())
                        
                    })
                    Button(action: {
                        masterDataManager.selectedCategory = .reports
                        
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Reports")
                            Spacer()
                        }
                        .modifier(HeaderModifier())
                        
                    })
                    Button(action: {
                        masterDataManager.selectedCategory = .userRoles
                    }, label: {
                        HStack{
                            Spacer()
                            Text("User Roles")
                            Spacer()
                        }
                        .modifier(HeaderModifier())
                    })
                }
            }
        }
        .foregroundColor(Color.white)
    }

}
