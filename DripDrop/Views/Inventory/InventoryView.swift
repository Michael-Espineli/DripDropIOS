//
//  InventoryView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//


import SwiftUI

struct InventoryView: View {
    @EnvironmentObject var dataService: ProductionDataService
    @Binding var showSignInView: Bool
    @State var user:DBUser
    @State var company:Company

    @State private var isLoading = true
    @StateObject var profileVM = ProfileViewModel()
    
    var body: some View {
        ZStack{
            if isLoading {
                VStack{
                    ProgressView()
                    Text("Setting up pool stick")
                }
                .background(Color.gray.opacity(0.5))
                .cornerRadius(5)
            } else {
                    TabView {
                        ReceiptView(showSignInView: $showSignInView, user: user,company: company)
                            .tabItem {
                                Label("Receipts", systemImage: "person.crop.circle")
                            }
                        ReceiptDatabaseView(dataService: dataService)
                        .tabItem {
                            Label("Data Base", systemImage: "doc.on.doc.fill")
                        }
                        PurchasesView(dataService: dataService)
                            .tabItem {
                                Label("Purchases", systemImage: "person.crop.circle")
                            }
                        StoreView()
                            .tabItem {
                                Label("Venders", systemImage: "house.circle")
                            }
                        Text("Inventory5")
                            .tabItem {
                                Label("Inventory5", systemImage: "person.circle")
                            }
                        
                    }
                    .background(Color.gray)
                
                
            }
        }
        .task {
            isLoading = true
            try? await profileVM.loadCurrentUser()
            let user:DBUser = profileVM.user ?? DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0, recentlySelectedCompany: "")
            let id = user.id
            if id != "" && id != "1"{
                print("Current User Loaded :\(id)")
            }
            isLoading = false
        }
    }
}

