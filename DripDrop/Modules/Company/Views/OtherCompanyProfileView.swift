//
//  OtherCompanyProfileView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import SwiftUI

struct OtherCompanyProfileView: View {
    @StateObject var VM : BuisnessViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    init( dataService:any ProductionDataServiceProtocol,company:Company){
        _VM = StateObject(wrappedValue: BuisnessViewModel(dataService: dataService))
        _company = State(wrappedValue: company)
    }
    @State var  company: Company
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                saveButton
                info
            }
            .padding(8)
        }
        .task {
            if let selectedCompany = masterDataManager.currentCompany {
                do {
                    try await VM.getAssociatedBuisnesses(companyId: selectedCompany.id)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    OtherCompanyProfileView()
//}
extension OtherCompanyProfileView {
    var saveButton: some View {
        HStack{
            Spacer()
            Button(action: {
                Task{
                    if let selectedCompany = masterDataManager.currentCompany {
                        do {
                            if VM.buisnessList.contains(where: {$0.companyId == company.id}) {
                                print("Business List Contains Company")
                                let business = VM.buisnessList.first(where: {$0.companyId == company.id})
                                if let business {
                                    try await VM.deleteAssociatedBusinessToCompany(
                                        companyId: selectedCompany.id,
                                        businessId: business.id
                                    )
                                }
                            } else {
                                print("Business List Does Not Contains Company")

                                try await VM.saveAssociatedBusinessToCompany(
                                    companyId: selectedCompany.id,
                                    business: AssociatedBusiness(
                                        companyId: company.id,
                                        companyName: company.name ?? ""
                                    )
                                )
                            }
                            try await VM.getAssociatedBuisnesses(companyId: selectedCompany.id)

                        } catch {
                            print("error")
                            print(error)
                        }
                    }
                }
            },
                   label: {
                if VM.buisnessList.contains(where: {$0.companyId == company.id}) {
                    Image(systemName: "heart.fill")
                        .modifier(AddButtonModifier())
                } else {
                    Image(systemName: "heart")
                        .modifier(AddButtonModifier())
                }
            })
        }
    }
    var info: some View {
        VStack{
            VStack{
                HStack{
                    VStack{
                        
                        Text("\(company.name ?? "")")
                            .font(.headline)
                        
                    }
                    Spacer()
                    ZStack{
                        Circle()
                            .fill(.white)
                            .frame(maxWidth:80 ,maxHeight:80)
                        
                        Image(systemName: "38.circle")
                            .resizable()
                            .foregroundColor(Color.basicFontText)
                            .frame(maxWidth:80 ,maxHeight:80)
                            .cornerRadius(85)
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(.green,style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(maxWidth:75,maxHeight:75)
                            .rotationEffect(.degrees(-90))
                        
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
            //            RatingView10(rate: 4.5)
            Divider()
            Spacer()
        }
    }
    
}
