//
//  AdminView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//



import SwiftUI

struct AdminView: View {
    @EnvironmentObject var dataService: ProductionDataService

    @Binding var showSignInView: Bool
    @State var user:DBUser
    var company:Company
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
                    JobView()
                        .tabItem {
                            Label("Job", systemImage: "doc.on.doc.fill")
                        }
                    TechView(showSignInView: $showSignInView, user: user,company: company)
                        .tabItem {
                            Label("Techs", systemImage: "person.3.fill")
                        }
//                    CalendarView(showSignInView: $showSignInView, user: user, company: company)
                    UserRouteOverView(dataService: dataService)
                        .tabItem {
                            Label("Route Overview", systemImage: "calendar")
                        }
                    RouteManagmentView(dataService: dataService)
                        .tabItem {
                            Label("Route Builder", systemImage: "car")
                        }
                    
                    CompanyProfileView()
                        .tabItem {
                            Label("Company Profile", systemImage: "person.circle")
                        }
                    
                }
                .background(Color.gray)
                
                
            }
        }
        .task {
            isLoading = true
            try? await profileVM.loadCurrentUser()
            let user:DBUser = profileVM.user ?? DBUser(id: "1",exp: 0)
            let id = user.id
            if id != "" && id != "1"{
                print("Current User Loaded :\(id)")
            }
            isLoading = false
        }
    }
}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSignInView: Bool = false
        AdminView(showSignInView:$showSignInView, user: DBUser(id: "",exp: 0), company:Company(id: ""))
        
    }
}
