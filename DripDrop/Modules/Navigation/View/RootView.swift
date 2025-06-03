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
                    Group {
                        if UIDevice.isIPhone{
                            MobileHome(dataService: dataService)
                        } else {
                            ThreeColumnMenuView(dataService:dataService,layoutExperience:$layoutExperience)
                        }
                    }
                }
            }
        }
        .task{
            do {
                print("Root View - Initial Load")
                try await VM.onInitialLoad()
                masterDataManager.user = VM.user
                masterDataManager.currentCompany = VM.company
                masterDataManager.companyUser = VM.companyUser
                VM.isLoading = false
                masterDataManager.showSignInView = false
            } catch {
                print("Error Root View")
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
                        print("Root View - Change of showSign In View")
                        try await VM.onInitialLoad()
                        masterDataManager.user = VM.user
                        masterDataManager.currentCompany = VM.company
                        masterDataManager.companyUser = VM.companyUser
                        VM.isLoading = false
                        masterDataManager.showSignInView = false
                    } catch {
                        print("Error Root View")
                        print(error)
                        VM.isLoading = false
                        masterDataManager.showSignInView = true
                    }
                    
                }
            }
        })
//        .onChange(of: VM.showSignIn, perform: { signIn in
//            Task{
//                print(signIn)
//                if signIn {
//                    masterDataManager.showSignInView = true
//                } else {
//                    masterDataManager.showSignInView = false
//                }
//            }
//        })
    }
}

struct RootView_Previews: PreviewProvider {
    static let dataService = MockDataService()
    static var previews: some View {
        RootView(dataService:dataService)
    }
}
