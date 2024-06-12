//
//  CompanyUserDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import SwiftUI

struct CompanyUserDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject var VM : TechListViewModel

    @State var companyUser:CompanyUser
    init(dataService:any ProductionDataServiceProtocol,companyUser:CompanyUser) {
        _VM = StateObject(wrappedValue: TechListViewModel(dataService: dataService))
        _companyUser = State(wrappedValue: companyUser)
    }

    @State var showSheet:Bool = false
    @State var tech: DBUser? = nil

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView {
                VStack{
                    ZStack{
                        if let tech = VM.specificTech, let imageLink = tech.photoUrl,let url = URL(string: imageLink){
                            AsyncImage(url: url){ image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(Color.white)
                                    .frame(maxWidth:100 ,maxHeight:100)
                                    .cornerRadius(100)
                            } placeholder: {
                                Image(systemName:"person.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(Color.white)
                                    .frame(maxWidth:100 ,maxHeight:100)
                                    .cornerRadius(100)
                            }
                        } else {
                            Image(systemName:"person.circle")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.white)
                                .frame(maxWidth:100 ,maxHeight:100)
                                .cornerRadius(100)
                        }
                    }
                    VStack(alignment: .leading){
                        
                        if let company = masterDataManager.selectedCompany {
                            Text("\(companyUser.userName)")
                            Text("Position: \(companyUser.roleName)")
                            Text("Date Created: \(fullDate(date:companyUser.dateCreated))")
                            Text("Company: \(company.name ?? "")")
                            Text("Role: \(companyUser.roleName)")
//                            NavigationLink(value: Route.rateSheet(user: tech,dataService: dataService), label: {
//                                Text("Rate Sheet")
//                                    .foregroundColor(Color.white)
//                                    .padding(5)
//                                    .background(Color.poolBlue)
//                                    .cornerRadius(5)
//                            })
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal,16)
                .sheet(isPresented: $showSheet, content: {
                    EditCompanyUserView(dataService: dataService, tech: companyUser)
                })
            }
            icons
        }
        .task{
            do {
                try await VM.getOneTech(techId: companyUser.userId)
            } catch {
                print("Error Getting DetailView \(companyUser.userName)")
            }
        }
    }
}
extension CompanyUserDetailView {
    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {
                        self.showSheet.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "square.and.pencil")
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
}
