//
//  EditCompanyUserView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/19/24.
//

import SwiftUI

struct EditCompanyUserView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var VM : EditTechViewModel
    
    init(dataService:any ProductionDataServiceProtocol,tech:CompanyUser) {
        _VM = StateObject(wrappedValue: EditTechViewModel(dataService: dataService))
        _tech = State(wrappedValue: tech)
    }
    
    @State var tech:CompanyUser
    
    @State var selectedRole:Role = Role(id: "", name: "", permissionIdList: [], listOfUserIdsToManage: [], color: "", description: "")
    
    @State var status: CompanyUserStatus = .active

    var body: some View {
        VStack{
            HStack{
                if tech.roleId != selectedRole.id || tech.status != status {
                    Button(action: {
                        Task{
                            if let company = masterDataManager.selectedCompany,
                               let user = masterDataManager.user {
                                //DEVELOPER - I think I might put employment history under each user so that a specific company to edit the Roles
                                do {
                                    try await VM.updateCompanyUser(
                                        user: tech,
                                        userId: tech.userId,
                                        userName: tech.userName,
                                        roleId: selectedRole.id,
                                        roleName: selectedRole.name,
                                        dateCreated: tech.dateCreated,
                                        status: status
                                    )
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    },
                           label: {
                        Text("Save")
                            .foregroundColor(Color.basicFontText)
                            .padding(8)
                            .background(Color.poolBlue)
                            .cornerRadius(8)
                    })
                }
                Spacer()

            }
            Text("\(tech.userName)")
            Text("Position: ")
            Text("Date Created: \(fullDate(date:tech.dateCreated))")
            Text("Company: ")
            HStack{
                Text("Roles")
                
                Picker("", selection: $selectedRole) {
                    Text("Pick Role")
                    ForEach(VM.roleList) {
                        Text($0.name ).tag($0)
                        
                    }
                }
            }
            Rectangle()
                .frame(height: 4)
            VStack{
                if let user = VM.user {
                    if let urlString = user.photoUrl,let url = URL(string: urlString){
                        AsyncImage(url: url){ image in
                            image
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.white)
                                .frame(maxWidth:50 ,maxHeight:50)
                                .cornerRadius(50)
                        } placeholder: {
                            Image(systemName:"person.circle")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.basicFontText)
                                .frame(maxWidth:50 ,maxHeight:50)
                                .cornerRadius(50)
                        }
                    } else {
                        Image(systemName:"person.circle")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(Color.basicFontText)
                            .frame(maxWidth:50 ,maxHeight:50)
                            .cornerRadius(50)
                    }
                    Text("\(user.firstName ?? "") \(user.lastName ?? "")")
                    Rectangle()
                        .frame(height: 1)
                    Text("Email: \(user.email)")
                    Text("Phone Number: +(619)490-6830")
                    Text("Bio: \(user.bio)")
                }
            }
        }
        .task {
            if let company = masterDataManager.selectedCompany{
                do {
                    try await VM.onFirstLoad(companyId: company.id,userId:tech.userId)
                } catch {
                    print("")
                    print("Edit Tech View Error")
                    print(error)
                    print("")

                }
            }
        }
        .onAppear(perform: {
            
            status = tech.status
            selectedRole.id = tech.roleId
            selectedRole.name = tech.roleName

        })
    }
}

struct EditCompanyUserView_Previews: PreviewProvider {
    static var previews: some View {
        EditCompanyUserView(dataService: MockDataService(), tech:CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active))
    }
}
