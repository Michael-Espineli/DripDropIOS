//
//  FinanceView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//


import SwiftUI

struct FinanceView: View {
    @Binding var showSignInView: Bool
    @State var user:DBUser
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
                        UnbilledJobs(showSignInView: $showSignInView,user:user)
                            .tabItem {
                                Label("Unbilled Jobs", systemImage: "person.crop.circle")
                            }
                        UnbilledItems(showSignInView: $showSignInView,user:user)
                        .tabItem {
                            Label("Unbilled Items", systemImage: "doc.on.doc.fill")
                        }
                        ProfitAndLoss(showSignInView: $showSignInView,user:user)
                            .tabItem {
                                Label("P.N.L.", systemImage: "message.circle")
                            }
                        Text("FianceOption4")
                            .tabItem {
                                Label("FianceOption4", systemImage: "house.circle")
                            }
                        Text("FianceOption5")
                            .tabItem {
                                Label("FianceOption5", systemImage: "person.circle")
                            }
                        
                    }
                    .background(Color.gray)
                
                
            }
        }
        .task {
            isLoading = true
            try? await profileVM.loadCurrentUser()
            let user:DBUser = profileVM.user ?? DBUser(id: "", email: "", firstName: "", lastName: "", exp: 0,recentlySelectedCompany: "")
            let id = user.id
            if id != "" && id != "1"{
                print("Current User Loaded :\(id)")
            }
            isLoading = false
        }
    }
}

struct FinanceView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSignInView: Bool = false
        FinanceView(showSignInView:$showSignInView, user: DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: ""))
        
    }
}
