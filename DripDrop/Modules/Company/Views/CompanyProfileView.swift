//
//  CompanyProfileView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/3/23.
//

import SwiftUI
import PhotosUI

struct CompanyProfileView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var companyVM = CompanyViewModel()
    @State private var selectedPhoto:PhotosPickerItem? = nil
#if os(iOS)
    @State private var displayImage:UIImage? = nil
#endif

    @State private var displayURL:URL? = nil
    @State private var urlDisplayString:String? = nil

    
    var body: some View {
        VStack{
            profile
            info
        }
        .task{
            if let company = masterDataManager.selectedCompany {
                do {
                    try await companyVM.loadCurrentCompany(companyId: company.id)
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: selectedPhoto, perform: { newValue in
            if let newValue {
                Task{
                print("Save Profile")
                    //Developer Fix Later
//                    companyVM.saveProfileImage(user: user, companyId: companyVM.company?.id ?? user.favoriteCompanyId, item: newValue)
                }
            }
        })
    }
}

struct CompanyProfileView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSignInView: Bool = false
        CompanyProfileView()
    }
}
extension CompanyProfileView {
    var image: some View {
        ZStack{
            Circle()
                .fill(Color.red)
                .frame(maxWidth:150 ,maxHeight:150)
            if let urlString = companyVM.imageUrlString,let url = URL(string: urlString){
                AsyncImage(url: url){ image in
                    image
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(Color.white)
                        .frame(maxWidth:145 ,maxHeight:145)
                        .cornerRadius(75)
                } placeholder: {
                    Image(systemName:"person.circle")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(Color.white)
                        .frame(maxWidth:145 ,maxHeight:145)
                        .cornerRadius(75)
                }
            }
            
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared(), label: {
                        ZStack{
                            Circle()
                                .fill(.blue)
                                .frame(maxWidth:30 ,maxHeight:30)
                            
                            Image(systemName: "photo.on.rectangle.angled")
                                .resizable()
                                .foregroundColor(Color.white)
                                .frame(maxWidth:20 ,maxHeight:20)
                        }
                    })
                }
            }
            .padding()
        }
        .frame(maxWidth: 150,maxHeight:150)
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
    }
    var info: some View {
        VStack{
            VStack{
                HStack{
                    VStack{
                        if let company = masterDataManager.selectedCompany {
                            
                            Text("\(company.name ?? "")")
                                .font(.headline)
                        }
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
    var profile: some View {
        VStack{
                        image
        }
        .background(Color.basicFontText.opacity(0.5))
    }
    
}

