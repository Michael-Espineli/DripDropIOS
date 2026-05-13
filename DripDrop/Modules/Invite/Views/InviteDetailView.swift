//
//  InviteDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/12/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct InviteDetailView: View {
    init( dataService:any ProductionDataServiceProtocol, invite:Invite){
        _VM = StateObject(wrappedValue: InviteDetailViewModel(dataService: dataService))
        self._invite = .init(initialValue: invite)
    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject private var VM : InviteDetailViewModel
    
    @State var invite:Invite
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                if let company = masterDataManager.currentCompany {
                    if company.id == invite.companyId {
                        self.companyView
                    }
                } else {
                    if let user = masterDataManager.user {
                        if user.id == invite.userId {
                            self.techView
                        }
                    }
                }
            }
        }
        .task{
            await VM.onLoad(invite: invite)
        }
        .toolbar{
            Button(action: {
                print("Button does not function")  // DEVELOPER
            }, label: {
                Text("Edit")

            })
        }
    }
}
extension InviteDetailView {
    var companyView: some View {
        VStack{
            Text("\(invite.firstName) \(invite.lastName)")
            Text("\(invite.status)")
            Text("\(invite.roleName)")

            Text("\(invite.workerType.rawValue)")


                #if os(iOS)
                Button(action: {
                    UIPasteboard.general.setValue("\(invite.id)",forPasteboardType: UTType.plainText.identifier)
                }, label: {
                    HStack{
                        Text("\(invite.id)")
                            .textSelection(.enabled)
                            .foregroundColor(Color.white)
                            .padding(10)
                            .background(Color.gray.opacity(0.5))
                            .cornerRadius(5)
                        VStack{
                            Text("Copy")
                            Image(systemName: "square.fill.on.square.fill")
                        }
                    }
                })
                #endif
            
            Spacer()
        }
    }
    var techView: some View {
        ZStack{
            ScrollView{
                Text("Tech View")
                Text("\(invite.companyName)")
                Text("\(invite.companyId)")
                Text("\(invite.status)")
                Text("\(invite.roleName)")
                Text("Company Contact Information")
                if let updatedInvite = VM.updatedInvite{
                    if updatedInvite.status == "pending"{
                        Divider()
                        HStack{
                            Button(action: {
                                Task{
                                    
                                    await VM.acceptInvite(user: masterDataManager.user, invite: invite)
                                }
                            }, label: {
                                Text("Accept")
                                    .modifier(AddButtonModifier())
                            })
                            Spacer()
                            Button(action: {
                                Task{
                                    await VM.rejectInvite(user: masterDataManager.user, invite: invite)
                                }
                            }, label: {
                                Text("Rejected")
                                    .modifier(DeleteButtonModifier())
                            })
                        }
                    }
                    
                }
            }
        }
    }

}
