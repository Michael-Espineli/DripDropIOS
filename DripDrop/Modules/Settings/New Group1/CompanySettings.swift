//
//  CompanySettings.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//

import Foundation
import SwiftUI
import StripePaymentSheet
import FirebaseFunctions

@MainActor
final class CompanySettingsViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published private(set) var externalAccountLink: URL? = nil
    @Published private(set) var totalActiveCustomers: Float = 1
    @Published private(set) var currentActiveCustomers: Float = 0

    func onLoad() {
        Task{
            do {
                self.totalActiveCustomers = 50
                self.currentActiveCustomers = 25
            } catch {
                print(error)
            }
        }
    }
    func setUpStripeAccount(company:Company,user:DBUser) {
        Task{
            do {
                guard let stripeConnectAccountId = company.stripeConnectAccountId else{
                    return
                }
                
                print("--createStripeAccountLink--")
                let data:[String:Any] = [
                    "accountId": stripeConnectAccountId,
                    "stripeVersion": "2023-10-16",
                ]
                print(data)
                let result = try await Functions.functions().httpsCallable("createStripeAccountLink").call(data)
                print(result)
                guard let json = result.data as? [String: Any] else {
                    
                      print("Failed to Parse JSON")
                  return
                }
                print(json)
                guard let accountLink = json["accountLink"] as? String else {
                  // Handle error
                    print("Failed to Get Account Link")
                  return
                }
                guard let url = URL(string: accountLink) else {
                    // Handle error
                      print("Failed to Make URL")
                    return
                  }
                    
                self.externalAccountLink = url
            } catch {
                print(error)
            }
        }
    }
}

struct CompanySettings: View {
    init(dataService:any ProductionDataServiceProtocol){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _AuthVM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
        _VM = StateObject(wrappedValue: CompanySettingsViewModel(dataService: dataService))
    }

    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var customerViewModel: CustomerViewModel

    @StateObject private var VM : CompanySettingsViewModel
    @StateObject private var AuthVM : AuthenticationViewModel
    @StateObject private var companyVM = CompanyViewModel()
    @StateObject private var userAccessVM = UserAccessViewModel()
    @StateObject private var customerVM : CustomerViewModel
    @StateObject var roleVM = RoleViewModel()

    @State var company:Company = Company(
        id: "",
        ownerId: "",
        ownerName: "",
        name: "",
        photoUrl: "",
        dateCreated: Date(),
        email: "",
        phoneNumber: "",
        verified: false,
        serviceZipCodes: [],
        services: [],
        accountType: .free,
        paidUntil: Date(),
        status: .free,
        stripeConnectAccountStatus: .notStarted,
        yelpURL : "",
        websiteURL : ""
    )
    @State var companyIdList:[Company] = []
    @State var showChangeEmailScreen:Bool = false
    @State var isLoading = false

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                settings
                
                //Developer Remove Before Production Always
#if DEBUG
                TestDataView()
#endif
            }
            .padding(8)
        }
        .foregroundColor(Color.basicFontText)
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
                        VM.onLoad()
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
            Text("Company Settings")
                .fontWeight(.bold)
            
            if UIDevice.isIPhone {
                VStack{
                    if let role = masterDataManager.role {
                        
                        if role.permissionIdList.contains(["890"]) {
                                Section(header: Text("General")) {
                                    if role.permissionIdList.contains("890") {
                                    NavigationLink(value: Route.manageSubscriptions(
                                        dataService: dataService
                                    ),label: {
                                        HStack{
                                            Spacer()
                                            Text("Manage Subscriptions")
                                            Spacer()
                                        }
                                        .modifier(HeaderModifier())
                                        .frame(height: 50)
                                    })
                                }
                            }
                        }
                        if role.permissionIdList.contains(where:  ["810","820","830","840","850","860","870"].contains) {
                            Section(header: Text("Company")) {
                                if role.permissionIdList.contains("810") {
                                    NavigationLink(value: Route.companyInfo(
                                        dataService: dataService
                                    ),label: {
                                        HStack{
                                            Spacer()
                                            Text("Company Information")
                                            Spacer()
                                        }
                                        .modifier(HeaderModifier())
                                        .frame(height: 50)
                                        
                                    })
                                }
                                if role.permissionIdList.contains("820") {
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
                                }
                                if role.permissionIdList.contains("830") {
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
                                }
                                if role.permissionIdList.contains("840") {
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
                                }
                                if role.permissionIdList.contains("850") {
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
                                }
                                if role.permissionIdList.contains("860") {
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
                                if role.permissionIdList.contains("870") {
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
                                }
                            }
                        }
                        
                        if role.permissionIdList.contains(["880"]) {
                            Section(header: Text("Billing")) {
                                if role.permissionIdList.contains("880") {
                                    NavigationLink(value: Route.manageTermsTemplates(
                                        dataService: dataService
                                    ),label: {
                                        HStack{
                                            Spacer()
                                            Text("Terms Templates")
                                            Spacer()
                                        }
                                        .modifier(HeaderModifier())
                                        .frame(height: 50)
                                        
                                    })
                                }
                            }
                        }
                    }
                }
                VStack{
//                         update 3.1
//                        NavigationLink(value: Route.stripeConfiguration(
//                            dataService: dataService
//                        ),label: {
//                            HStack{
//                                Spacer()
//                                Text("Stripe Configuration")
//                                Spacer()
//                            }
//                            .background(Color.pink)
//                            .modifier(HeaderModifier())
//                            .frame(height: 50)
//
//                        })
                }
            }
        }
        .foregroundColor(Color.basicFontText)

    }

}
