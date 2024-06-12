//
//  TechListView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct TechListView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : TechListViewModel

    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: TechListViewModel(dataService: dataService))
    }

    @State var showInviteSheet:Bool = false
    @State var showInviteSheetForTechWithApp:Bool = false
    @State var showPick:Bool = false
    @State var selected:String = "Active"
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                ScrollView{
                    Picker("Pick Type", selection: $selected) {
                        Text("Active").tag("Active")
                        Text("Accepted").tag("Accepted")
                        Text("Pending").tag("Pending")
                        Text("Past").tag("Past")

                    }
                    .pickerStyle(.segmented)
                    .confirmationDialog("Select Type", isPresented: self.$showPick, actions: {
                        Button(action: {
                            showInviteSheet.toggle()
                        }, label: {
                            Text("Add Tech with out app")
                        })
             
                        Button(action: {
                            showInviteSheetForTechWithApp.toggle()
                        }, label: {
                            Text("Add Tech with app")
                        })
             
                    })
                    .sheet(isPresented: $showInviteSheetForTechWithApp, content: {
                        Text("Build invite tech with app. Something like a search bar for all Users")
                    })
               
                    Group{
                        switch selected{
                        case "Active":
                            companyUserTechList
                        case "Pending":
                            Text("pendingTechList")
//                            pendingTechList
                        case "Accepted":
                            Text("acceptedTechList")
//                            acceptedTechList
                        case "Past":
                            companyUserTechList
                        default:
                            companyUserTechList
                        }
                    }
                    .sheet(isPresented: $showInviteSheet, content: {
//                        InviteNewTechView()
                    })
                }
            }
            icons
        }

        .task {
            if let company = masterDataManager.selectedCompany {
                do {
                    try await VM.onFirstLoad(companyId: company.id)
                } catch {
                    print("")
                    print("Tech List View Error")
                    print(error)
                    print("")
                }
            }
        }
        .onChange(of: selected, perform: { status in
            Task{
                if let company = masterDataManager.selectedCompany {
                    if status == "Active" || status == "Past" || status == "Pending" {
                        do {
                            try await VM.onChangeOfSelectedStatus(companyId: company.id, status: status)
                        } catch {
                            print("")
                            print("Error Getting Users By status On Refresh")
                            print(error)
                            print("")
                        }
                    }
                }
            }
        })
    }
}

struct TechListView_Previews: PreviewProvider {
    static var previews: some View {
        @State var show:Bool = false
        TechListView(dataService: MockDataService())
    }
}
extension TechListView {
    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {
                        self.showPick.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "plus")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(Color.white)
                                )
                        }
                    })
                }
                .padding(16)
            }
        }
    }
    var acceptedTechList: some View {
        ForEach(VM.acceptedInviteList){ invite in
            NavigationLink(destination: {
                InviteDetailView(invite: invite)
            }, label: {
                InviteCardView(invite: invite)
            })
            Divider()
        }
    }
    var pendingTechList: some View {
        ForEach(VM.pendingInviteList){ invite in
            NavigationLink(destination: {
                InviteDetailView(invite: invite)
            }, label: {
                InviteCardView(invite: invite)
            })
            Divider()
        }
    }
    var companyUserTechList: some View {
        ForEach(VM.companyUsers){ user in
            NavigationLink(value: Route.companyUserDetailView(user: user, dataService: dataService), label: {
                CompanyUserCardView(dataService: dataService, companyUser: user)
            })
            Divider()
        }
    }
    var toolbar: some View {
        VStack{
            if let role = masterDataManager.role {
                if role.permissionIdList.contains("9") {
                    HStack{
                    }
                    .padding(5)
                }
            }
        }
    }
}
