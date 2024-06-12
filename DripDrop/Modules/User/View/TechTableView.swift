//
//  TechTableView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/12/23.
//

import SwiftUI

struct TechTableView: View {
    @StateObject var techVM = TechViewModel()
    @StateObject var inviteVM = InviteViewModel()

    @Binding var showSignInView: Bool
    @State var user:DBUser
    @State var company:Company

    @State var showInviteSheet:Bool = false
    @State var selected:String = "Current"
    var body: some View {
        ZStack{
            VStack{
                ScrollView{
                    toolbar
                    Picker("What is your favorite color?", selection: $selected) {
                        Text("Current").tag("Current")
                        Text("Pending").tag("Pending")
                        Text("Accepted").tag("Accepted")

                    }
                    .pickerStyle(.segmented)
                    switch selected{
                    case "Current":
                        techList
                    case "Pending":
                        pendingTechList
                    case "Accepted":
                        acceptedTechList
                    default:
                        techList
                    }
                }
            }
        }
        .task {
            try? await techVM.getAllCompanyTechs(companyId: company.id)
            try? await inviteVM.getAllPendingComapnyInvites(companyId: company.id)
            try? await inviteVM.getAllAcceptedComapnyInvites(companyId: company.id)

        }
    }
}

struct TechTableView_Previews: PreviewProvider {
    static var previews: some View {
        @State var show:Bool = false
        TechTableView(showSignInView: $show, user: DBUser(id: "",exp: 0), company: Company(id: ""))
    }
}
extension TechTableView {
    var acceptedTechList: some View {
        ForEach(inviteVM.acceptedInviteList){ invite in
            NavigationLink(destination: {
//                TechDetailView(tech: tech)
            }, label: {
                InviteCardView(invite: invite)
            })
        }
    }
    var pendingTechList: some View {
        ForEach(inviteVM.pendingInviteList){ invite in
            NavigationLink(destination: {
//                TechDetailView(tech: tech)
            }, label: {
                InviteCardView(invite: invite)
            })
        }
    }
    var techList: some View {
        ForEach(techVM.techList){ tech in
            NavigationLink(destination: {
                TechDetailView(tech: tech)
            }, label: {
                TechCardView(tech: tech)
            })
        }
    }
    var toolbar: some View {
        HStack{
            Spacer()
            Button(action: {
                showInviteSheet.toggle()
            }, label: {
                Text("Invite new Team Member")
            })
            .sheet(isPresented: $showInviteSheet, content: {
                InviteNewTechView()
            })
        }
        .padding()
    }
}

