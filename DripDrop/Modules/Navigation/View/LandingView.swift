//
//  LandingView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/19/23.
//


import SwiftUI

struct LandingView: View {

    @EnvironmentObject private var masterDataManager : MasterDataManager
    @StateObject private var VM : LandingViewModel
    @EnvironmentObject var dataService : ProductionDataService
    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: LandingViewModel(dataService: dataService))
    }

    @State private var isLoading = true
    @State private var showCart:Bool = false
    @State private var showSettings:Bool = false
    @State private var showCompany:Bool = false
    @State var layoutExperience: LayoutExperienceSetting = .threeColumn
    @State var showSignInView:Bool = false
    @State private var columVisibility: NavigationSplitViewVisibility = .automatic
    var body: some View {
        ZStack{
            if isLoading {
                WaterLevelLoading()
            } else {
                if masterDataManager.showPaymentSheet {
                    if let sheetType = masterDataManager.paymentSheetType {
                        StripePaymentSheet(sheetType: sheetType)
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
                            MobileHome(dataService: dataService)
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
                }
            }
        }
        .task {
            isLoading = true
            do {
//                try await profileVM.loadCurrentUser()
                
                try await VM.initalLoad()
                masterDataManager.user = VM.user
                 masterDataManager.selectedCompany = VM.company
                 masterDataManager.companyUser = VM.companyUser

            } catch {
                print("Failed to get User Access List - Page: MobileMainView")
                masterDataManager.showSignInView = true
            }
            isLoading = false
        }
    }
}

struct LandingView_Previews: PreviewProvider {
    static let dataService = MockDataService()
    static var previews: some View {
        LandingView(dataService:dataService)

    }
}
