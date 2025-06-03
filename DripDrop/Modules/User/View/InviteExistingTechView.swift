//
//  InviteExistingTechView.swift
//  DripDrop
//
//  Created by Michael Espineli on 8/24/24.
//

import SwiftUI

struct InviteExistingTechView: View {
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: InviteExistingTechViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var VM : InviteExistingTechViewModel
    @State var selectedUser:DBUser = DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: "")
    @State var role:String = ""
    @State var workerType:WorkerTypeEnum = .employee
    @State var inviteCode:String = UUID().uuidString
    @State var selectedRole:Role = Role(id: "", name: "", permissionIdList: [], listOfUserIdsToManage: [], color: "", description: "")
    @State var showAlert:Bool = false
    @State var alertMesage:String = ""
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if VM.selectedUser.id == "" {
                    searchForUsers
                    listOfUsers
                } else {
                    inviteInfo
                }
            }
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id)
                    if VM.roleList.count == 0 {
                        print("No Roles Found should not happen")
                        
                    } else {
                        selectedRole = VM.roleList.last!
                    }
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: VM.search, perform: { term in
            Task{
                do {
                    print("New Term \(term)")
                    try await VM.changeOfSearchTerm()
                } catch {
                    print(error)
                }
            }
        })
        .alert(alertMesage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

#Preview {
    InviteExistingTechView(dataService: MockDataService())
}
extension InviteExistingTechView {
    var searchForUsers: some View {
        VStack{
            Text("Build invite tech with app. Something like a search bar for all Users")
            TextField(
                text: $VM.search,
                label: {
                    Text("Search...")
                })
            .modifier(SearchTextFieldModifier())
        }
    }
    var listOfUsers: some View {
        ScrollView{
            ForEach(VM.userList){ user in
                Button(action: {
                    VM.selectedUser = user
                }, label: {
                    HStack{
                        Text("\(user.firstName) \(user.lastName)")
                        Spacer()
                        Text(VM.currentUsers.contains(where: {$0.userId == user.id}) ? "Already Added" : "Not Already Added")
                    }
                    .modifier(ListButtonModifier())
                })
                .disabled(VM.currentUsers.contains(where: {$0.userId == user.id}))
                .padding(8)
                Divider()
            }
        }
    }
    var inviteInfo: some View {
        ScrollView{
            HStack{
                Button(action: {
                    VM.selectedUser = DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: "")
                }, label: {
                    Text("Back")
                        .modifier(DismissButtonModifier())
                })
                Spacer()
            }
            HStack{
                Text("First Name:")
                    .bold()

                Text("\(VM.selectedUser.firstName)")
            }
            HStack{
                Text("Last Name:")
                    .bold()

                Text("\(VM.selectedUser.lastName)")
                Spacer()
           }
            HStack{
                Text("Email:")
                    .bold()
                Text("\(VM.selectedUser.email)")
                Spacer()
            }
            Picker("Role", selection: $selectedRole) {
                ForEach(VM.roleList) { role in
                    Text(role.name).tag(role)
                }
            }
            HStack{
                ForEach(selectedRole.permissionIdList,id:\.self){
                    Text($0)
                }
            }
            Picker("Worker Type", selection: $workerType) {
                Text(WorkerTypeEnum.employee.rawValue).tag(WorkerTypeEnum.employee)
                Text(WorkerTypeEnum.contractor.rawValue).tag(WorkerTypeEnum.contractor)
            }
            .pickerStyle(.segmented)
            HStack{
                Text("Invite Code:")
                    .bold()
                Text("\(inviteCode)")
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
            }
            Button(action: {
                Task{
                    if let company = masterDataManager.currentCompany {
                        do {
                            try await VM.createInviteForExistingUser(
                                companyId:company.id,
                                invite:Invite(
                                    id: inviteCode,
                                    userId: VM.selectedUser.id,
                                    firstName: VM.selectedUser.firstName,
                                    lastName: VM.selectedUser.lastName,
                                    email: VM.selectedUser.email,
                                    companyName: company.name,
                                    companyId: company.id,
                                    roleId: selectedRole.id,
                                    roleName: selectedRole.name,
                                    status: "Pending",
                                    workerType: workerType,
                                    currentUser: true
                                )
                            )
                            alertMesage = "Successfully Sending Invite"
                            print(alertMesage)
                            showAlert = true
                        } catch FireBasePublish.unableToPublish {
                            alertMesage = "Invalid Name"
                            print(alertMesage)
                            showAlert = true
                        } catch {
                            alertMesage = "Unable to Publish"
                            print(alertMesage)
                            showAlert = true
                        }
                    }
                }
            },
                   label: {
                Text("Invite")
                    .modifier(AddButtonModifier())
            })
        }
        .padding(8)
    }
}
