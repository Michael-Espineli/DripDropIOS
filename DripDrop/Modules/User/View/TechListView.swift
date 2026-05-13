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
    @EnvironmentObject var VM : TechListViewModel

    init(dataService:any ProductionDataServiceProtocol) {
    }

    @State var showInviteSheet:Bool = false
    @State var showInviteSheetForTechWithApp:Bool = false
    @State var showPick:Bool = false
    @State var selected:String = "Active"
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                Picker("Pick Type", selection: $selected) {
                    Text("Active").tag("Active")
                    Text("Pending").tag("Pending")
//                    Text("Past").tag("Past")
                }
                .pickerStyle(.segmented)
                .fontDesign(.monospaced)

                .confirmationDialog("Select Type", isPresented: self.$showPick, actions: {
                    Button(action: {
                        showInviteSheet.toggle()
                    }, label: {
                        Text("Add tech with out app")
                    })
         
                    Button(action: {
                        showInviteSheetForTechWithApp.toggle()
                    }, label: {
                        Text("Add tech with app")
                    })
         
                })
                .sheet(isPresented: $showInviteSheetForTechWithApp, content: {
                    InviteExistingTechView(dataService:dataService)
                })
           
                ScrollView{
             
                    Group{
                        switch selected{
                        case "Active":
                            companyUserTechList
                        case "Pending":
                            pendingTechList
                        case "Past":
                            pastTechList
                        default:
                            companyUserTechList
                        }
                    }
                    .sheet(isPresented: $showInviteSheet, content: {
                        InviteNewTechView()
                    })
                }
            }
//            icons
        }
        .navigationTitle("Directory")
        .onAppear(perform: {
            VM.onFirstLoad(companyId: masterDataManager.currentCompany?.id)
        })
        .onDisappear(perform: {
            VM.stop()
        })
        .onChange(of: selected, perform: { status in
            Task{
                if let company = masterDataManager.currentCompany {
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
        .toolbar{
            ToolbarItem(content: {
                Button(action: {
                    self.showPick.toggle()
                }, label: {
                    Text("Add")
                        .fontDesign(.monospaced)
                })
            })
        }
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
        VStack{
            ForEach(VM.acceptedInviteList){ invite in
                NavigationLink(value: Route.inviteDetailView(dataService: dataService, invite: invite), label: {
                    InviteCardView(invite: invite)
                })
                Divider()
            }
        }
    }
    var pendingTechList: some View {
        VStack{
            if VM.pendingInviteList.isEmpty {
                Text("No Pending Invites")
            }
            ForEach(VM.pendingInviteList){ invite in
                NavigationLink(value: Route.inviteDetailView(dataService: dataService, invite: invite), label: {
                    InviteCardView(invite: invite)
                    
                })
            }
        }
    }
    var pastTechList: some View {
        ForEach(VM.pendingInviteList){ invite in
            NavigationLink(value: Route.inviteDetailView(dataService: dataService, invite: invite), label: {
                InviteCardView(invite: invite)
                
            })
        }
    }
    var companyUserTechList: some View {
        
        VStack{
            if VM.companyUsers.isEmpty {
                Text("No Current Users")
            }
            ForEach(VM.companyUsers){ user in
                HStack{
                    if UIDevice.isIPhone {
                        NavigationLink(value: Route.companyUserDetailView(user: user, dataService: dataService), label: {
                            CompanyUserCardView(dataService: dataService, companyUser: user)
                        })
                    } else {
                        Button(action: {
                            masterDataManager.selectedCompanyUser = user
                        }, label: {
                            CompanyUserCardView(dataService: dataService, companyUser: user)
                        })
                    }
                }
                .padding(.horizontal,8)
                .padding(.vertical,3)
            }
        }
    }
    var toolbar: some View {
        VStack{
            if let role = masterDataManager.role {
                if role.permissionIdList.contains("262") {
                    HStack{
                    }
                    .padding(5)
                }
            }
        }
    }
}
