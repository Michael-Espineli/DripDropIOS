//
//  RootView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager

    @State var layoutExperience: LayoutExperienceSetting = .threeColumn
    @StateObject var userVM = TechViewModel()
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject private var VM : AuthenticationViewModel
    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack{
            if VM.isLoading {
                WaterLevelLoading()
            } else {
                if masterDataManager.showSignInView {
                    NavigationStack{
                        SignInView(dataService: dataService)
                    }
                } else {
                    // check if subscription // Moved it further into the app. so they have access to basic settings. Especially Logging in and Logging out
//                    if masterDataManager.activeSubscription == nil {
//                        SubscriptionPicker(dataService:dataService)
//                    } else {
                        Group {
                            if UIDevice.isIPhone{
                                MobileHome(dataService: dataService)
                            } else {
                                ThreeColumnMenuView(dataService:dataService,layoutExperience:$layoutExperience)
                            }
                        }
                    
                }
            }
            EnvironmentBanner()
        }
        .task{
            do {
                print("[Root View][Task] - Initial Load")
                try await VM.onInitialLoad()
                print("[Root View][Task] - onInitialLoad successfully completed")
                masterDataManager.checkForSubscriptionStatus()
                print("[Root View][Task] - checkForSubscriptionStatus successfully completed")
                masterDataManager.user = VM.user
                masterDataManager.currentCompany = VM.company
                masterDataManager.companyUser = VM.companyUser
                VM.isLoading = false
                masterDataManager.showSignInView = false
            } catch {
                print("[RootView][task]Error Root View")
                print(error)
                VM.isLoading = false
                masterDataManager.showSignInView = true
            }
        }
        .onChange(of: masterDataManager.showSignInView, perform: { showSignIn in
            Task{
                print(showSignIn)
                if !showSignIn {
                    do {
                        print("[Root View][Task] - Change of Show Sign In View")
                        try await VM.onInitialLoad()
                        print("[Root View][Task] - onInitialLoad successfully completed")
                        masterDataManager.checkForSubscriptionStatus()
                        print("[Root View][Task] - checkForSubscriptionStatus successfully completed")
                        masterDataManager.user = VM.user
                        masterDataManager.currentCompany = VM.company
                        masterDataManager.companyUser = VM.companyUser
                        VM.isLoading = false
                        masterDataManager.showSignInView = false
                    } catch {
                        print("[RootView][OnChangeOfShowSigninView]Error Root View")
                        print(error)
                        VM.isLoading = false
                        masterDataManager.showSignInView = true
                    }
                    
                }
            }
        })
    }
}

struct RootView_Previews: PreviewProvider {
    static let dataService = MockDataService()
    static var previews: some View {
        RootView(dataService:dataService)
    }
}
