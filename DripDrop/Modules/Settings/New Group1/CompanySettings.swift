//
//  CompanySettings.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//


    import SwiftUI

    struct CompanySettings: View {
        init(dataService:any ProductionDataServiceProtocol){
            _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
            _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
        }

        @EnvironmentObject var dataService : ProductionDataService
        @EnvironmentObject var masterDataManager : MasterDataManager
        @EnvironmentObject var customerViewModel: CustomerViewModel

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
                        Text("Company Settings View")
                            .fontWeight(.bold)
                    settings
                    Rectangle()
                        .frame(height: 1)
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
                        }
                    }
                }
            })
        }
    }

    extension CompanySettings {
        var displayPrefrences: some View {
            VStack{
                Text("Display Preferences")

                HStack{
                    Text("Main Screen Type:")
                        .fontWeight(.bold)
                    Spacer()
                    Picker("Main Screen Type", selection: $masterDataManager.mainScreenDisplayType, content: {
                        ForEach(MainScreenDisplayType.allCases,id:\.self){
                            Text($0.rawValue).tag($0)
                        }
                    })
                }
            }
        }
        var settings: some View {
            VStack{
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
                        NavigationLink(value: Route.emailConfiguration(
                            dataService: dataService
                        ),label: {
                            HStack{
                                Spacer()
                                Text("Email Configuration")
                                Spacer()
                            }
                            .modifier(HeaderModifier())
                            .frame(height: 50)
                            
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
                            .frame(height: 50)
                            
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
                            .frame(height: 50)
                            
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
                            .frame(height: 50)
                            
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
                            .frame(height: 50)
                            
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
                            .frame(height: 50)
                            
                        })
                    }
                } else {
                    
                    //Mac List
                    ScrollView(showsIndicators: false){
                        Button(action: {
                            masterDataManager.selectedCategory = .readingsAndDosages
                            
                        }, label: {
                            HStack{
                                Spacer()
                                Text("Readings And Dosages")
                                Spacer()
                            }
                            .modifier(HeaderModifier())
                            .frame(height: 50)
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
                            .frame(height: 50)
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
                            .frame(height: 50)
                            
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
                            .frame(height: 50)
                            
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
                            .frame(height: 50)
                            
                        })
                    }
                }
            }
            .foregroundColor(Color.white)
        }

    }
