//
//  CompanyUserCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import SwiftUI

struct CompanyUserCardView: View {
    @StateObject var VM : TechListViewModel
    
    init(dataService:any ProductionDataServiceProtocol,companyUser:CompanyUser) {
        _VM = StateObject(wrappedValue: TechListViewModel(dataService: dataService))
        _companyUser = State(wrappedValue: companyUser)
    }
    
    @State var companyUser:CompanyUser

    @State var tech: DBUser? = nil
    var body: some View {
        HStack{
            VStack{
                if let tech = tech, let imageLink = tech.photoUrl,let url = URL(string: imageLink){
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
            }
            Spacer()
            VStack{
                HStack{
                    Text("\(companyUser.userName)")
                    Text(" - \(companyUser.roleName)")
                }
                    Text(companyUser.workerType.rawValue)
                    if companyUser.workerType == .contractor {
                        if let linkedCompanyName = companyUser.linkedCompanyName {
                            Text("\(linkedCompanyName)")
                                .font(.footnote)
                        }
                    }
                
            }
        }
        .padding(8)
        .modifier(ListButtonModifier())
        .task {
            //DEVELOPER WHY DOES THIS CRASH MY APP
//            do {
//                tech = try await techVM.getOneTech(techId: companyUser.userId)
//            } catch {
//                print("Error")
//                print(error)
//            }
        }
    }
}
