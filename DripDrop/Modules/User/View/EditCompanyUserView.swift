//
//  EditCompanyUserView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/19/24.
//

import SwiftUI

struct EditCompanyUserView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @Environment(\.dismiss) private var dismiss

    @StateObject var VM : EditTechViewModel
    
    init(dataService:any ProductionDataServiceProtocol,tech:CompanyUser) {
        _VM = StateObject(wrappedValue: EditTechViewModel(dataService: dataService))
        _companyUser = State(wrappedValue: tech)
    }
    
    @State var companyUser:CompanyUser
    
    @State var selectedRole:Role = Role(id: "", name: "", permissionIdList: [], listOfUserIdsToManage: [], color: "", description: "")
    
    @State var status: CompanyUserStatus = .active
    @State var workerType: WorkerTypeEnum = .contractor
    @State var active:Bool = false

    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                HStack{
                    if companyUser.roleId != selectedRole.id || companyUser.status != status || companyUser.workerType != workerType{
                        Button(action: {
                            Task{
                                if let company = masterDataManager.currentCompany,
                                   let user = masterDataManager.user {
                                    //DEVELOPER - I think I might put employment history under each user so that a specific company to edit the Roles
                                    do {
                                        try await VM.updateCompanyUser(
                                            companyId:company.id,
                                            user: companyUser,
                                            userId: companyUser.userId,
                                            userName: companyUser.userName,
                                            roleId: selectedRole.id,
                                            roleName: selectedRole.name,
                                            dateCreated: companyUser.dateCreated,
                                            status: status,
                                            workerType:workerType
                                        )
                                        alertMessage = "Successfully"
                                        showAlert = true
                                        print(alertMessage)
                                        companyUser.roleId = selectedRole.id
                                        companyUser.roleName = selectedRole.name
                                        companyUser.status = status
                                        companyUser.workerType = workerType
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        },
                               label: {
                            Text("Save")
                                .modifier(SubmitButtonModifier())
                            
                        })
                    }
                    Spacer()
                    Button(action: {
                        dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                            .modifier(DismissButtonModifier())
                    })
                }
                VStack{
                    if let dbuser = VM.user {
                        if UIDevice.isIPhone {
                            if let urlString = dbuser.photoUrl,let url = URL(string: urlString){
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
                        } else {
                            if let urlString = dbuser.photoUrl,let url = URL(string: urlString){
                                AsyncImage(url: url){ image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundColor(Color.white)
                                        .frame(maxWidth:150 ,maxHeight:150)
                                        .cornerRadius(150)
                                } placeholder: {
                                    Image(systemName:"person.circle")
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundColor(Color.basicFontText)
                                        .frame(maxWidth:150 ,maxHeight:150)
                                        .cornerRadius(150)
                                }
                            } else {
                                Image(systemName:"person.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(Color.basicFontText)
                                    .frame(maxWidth:150 ,maxHeight:150)
                                    .cornerRadius(150)
                            }
                        }
                        Text("\(companyUser.userName)")
                        Rectangle()
                            .frame(height: 1)
                        HStack{
                            Text("Email: ")
                                Text("\(dbuser.email)")
                            
                            Spacer()

                        }
                        HStack{
                            Text("Bio: ")
                            if let bio = dbuser.bio {
                                Text("\(bio)")
                            }
                            Spacer()

                        }
                        HStack{
                            Text("Phone Number: +(619)490-6830")
                            Spacer()
                        }
                    }
                }
                HStack{
                    Text("Date Created: ")
                        Text("\(fullDate(date:companyUser.dateCreated))")
                    
                    Spacer()

                }
                Rectangle()
                    .frame(height: 4)

                HStack{
                    Text("Position : ")
                    Text("\(companyUser.roleName)")
                    Spacer()
                    Picker("", selection: $selectedRole) {
                        Text("Pick Role")
                        ForEach(VM.roleList) {
                            Text($0.name ).tag($0)
                            
                        }
                    }
                }
            
                HStack{
                    Text("WorkerType: ")
                    Text("\(companyUser.workerType.rawValue)")
                
                    Spacer()
                 
                }
                Picker("", selection: $workerType) {
                    ForEach(WorkerTypeEnum.allCases,id:\.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                
                .pickerStyle(.segmented)
                Picker("Active", selection: $active) {
                        Text("Active").tag(true)
                        Text("In Active").tag(false)
                }
                
                .pickerStyle(.segmented)
                Spacer()
            }
            .padding(8)
        }
        .task {
            if let company = masterDataManager.currentCompany{
                do {
                    status = companyUser.status
                    selectedRole.id = companyUser.roleId
                    selectedRole.name = companyUser.roleName
                    try await VM.onFirstLoad(companyId: company.id,userId:companyUser.userId)
                    if !VM.roleList.isEmpty {
                        selectedRole = VM.roleList.first(where: {$0.id == companyUser.roleId}) ?? Role(id: "", name: "", permissionIdList: [], listOfUserIdsToManage: [], color: "", description: "")
                    }
                } catch {
                    print("")
                    print("Edit Tech View Error")
                    print(error)
                    print("")

                }
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

struct EditCompanyUserView_Previews: PreviewProvider {
    static var previews: some View {
        EditCompanyUserView(dataService: MockDataService(), tech:CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active,workerType: .contractor))
    }
}
