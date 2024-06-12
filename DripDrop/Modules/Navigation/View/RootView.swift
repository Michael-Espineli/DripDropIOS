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

    @State var layoutExperience: LayoutExperienceSetting?
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
                    Group {
                        if UIDevice.isIPad{
//                            if let user = VM.user {
//                                ThreeColumnMenuView(
//                                    columnVisibility: $columVisibility,
//                                    showCart: $showCart,
//                                    showSettings: $showSettings,
//                                    showCompany:$showCompany,
//                                    layoutExperience:$layoutExperience,
//                                    showSignInView: $showSignInView,
//                                    user: user
//                                )
//                            }
                        } else if UIDevice.isIPhone {
                            //I decided to take out the landingView
                            MobileHome(dataService: dataService)
//                            LandingView(dataService: dataService)
                        } else {
//                            if let user = VM.user {
//
//                                ThreeColumnMenuView(
//                                    columnVisibility: $columVisibility,
//                                    showCart: $showCart,
//                                    showSettings: $showSettings,
//                                    showCompany:$showCompany,
//                                    layoutExperience:$layoutExperience,
//                                    showSignInView: $showSignInView,
//                                    user: user
//                                    )
//
//                            }
                        }
                    }
//                    LandingView(dataService: dataService)
                }
            }
        }
        .task{
            do {
                print("Root View")
                try await VM.onInitialLoad()
                masterDataManager.user = VM.user
                masterDataManager.selectedCompany = VM.company
                masterDataManager.companyUser = VM.companyUser
                VM.isLoading = false
                masterDataManager.showSignInView = false
            } catch {
                VM.isLoading = false
                masterDataManager.showSignInView = true
            }
        }
        .onChange(of: VM.showSignIn, perform: { signIn in
            print(signIn)
            if signIn {
                masterDataManager.showSignInView = true
            } else {
                masterDataManager.showSignInView = false
                
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
