//
//  OperationsView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//


import SwiftUI

struct OperationsView: View {
    @StateObject var profileVM = ProfileViewModel()
    @EnvironmentObject var dataService: ProductionDataService

    @Binding var showSignInView: Bool
    @State var user:DBUser
    @State var company:Company
        
    var body: some View {
        ZStack{
                TabView {

                    CustomerMainView()
                        .tabItem {
                            Label("Customer", systemImage: "person.crop.circle")
                        }
                    ServiceStopMainView()
                        .tabItem {
                            Label("Service Stops", systemImage: "doc.on.doc.fill")
                        }

                    RouteManagmentView(dataService: dataService)
                        .tabItem {
                            Label("Route", systemImage: "car")
                        }
                    
                }
                .background(Color.gray)
                
                
            
        }
    }
}

struct OperationsView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSignInView: Bool = false
        OperationsView(showSignInView:$showSignInView, user: DBUser(id: "", exp: 0), company: Company(id: ""))
        
    }
}
