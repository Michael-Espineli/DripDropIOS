//
//  EditTechView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/7/23.
//

import SwiftUI

struct EditTechView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var techVM = TechViewModel()
    @StateObject var roleVM = RoleViewModel()

    @StateObject var VM : EditTechViewModel
    
    init(dataService:any ProductionDataServiceProtocol,tech:DBUser) {
        _VM = StateObject(wrappedValue: EditTechViewModel(dataService: dataService))
        _tech = State(wrappedValue: tech)
    }
    @State var tech:DBUser

    @State var selectedRole:Role = Role(id: "", name: "", permissionIdList: [], listOfUserIdsToManage: [], color: "", description: "")
    var body: some View {
        VStack{
            HStack{
                Spacer()
                Button(action: {
                    Task{
                        if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                            //DEVELOPER - I think I might put employment history under each user so that a specific company to edit the Roles
                            do {
                                try await techVM.updateTech(user: user,
                                                             tech: DBUser(id: tech.id,
                                                                          email: tech.email,
                                                                          photoUrl: tech.photoUrl,
                                                                          dateCreated: tech.dateCreated,
                                                                          firstName: tech.firstName,
                                                                          lastName: tech.lastName,
                                                                          accountType: tech.accountType,
                                                                          profileImagePath: tech.profileImagePath,
                                                                          color: tech.color,
                                                                          exp: 0,
                                                                          recentlySelectedCompany: tech.recentlySelectedCompany)
                                )
                            } catch {
                                print(error)
                            }
                        }
                    }
                }, label: {
                    Text("Save")
                        .modifier(SubmitButtonModifier())

                })
            }
            Text("\(tech.firstName ?? "") \(tech.lastName ?? "")")
            Text("Position: ")
            Text("Date Created: \(fullDate(date:tech.dateCreated))")
            Text("Company: ")
            Text("Email: \(tech.email ?? "")")
            HStack{
                Text("Roles 1 ")
                
                Picker("", selection: $selectedRole) {
                    Text("Pick store")
                    ForEach(roleVM.roleList) {
                        
                        Text($0.name ).tag($0)
                        
                    }
                }
            }        }
        .task {
            if let company = masterDataManager.currentCompany{
                do {
                    try await VM.onFirstLoad(companyId: company.id, userId: tech.id)
                } catch {
                    print("")
                    print("Edit Tech View Error")
                    print(error)
                    print("")

                }
            }
        }
    }
}

struct EditTechView_Previews: PreviewProvider {
    static var previews: some View {
        EditTechView(dataService: MockDataService(), tech: DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: ""))
    }
}
