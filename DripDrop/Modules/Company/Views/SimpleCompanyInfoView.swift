//
//  SimpleCompanyInfoView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/15/25.
//

import SwiftUI
import PhotosUI
@MainActor
final class SimpleCompanyInfoViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }

    @Published private(set) var postedCompany : Company? = nil
    @Published private(set) var edit : Bool = false

    func onLoad(companyId:String,jobPost:JobPost) async throws {
        self.postedCompany = try await dataService.getCompany(companyId: jobPost.companyId)
    }
    func editCompany(){
        self.edit.toggle()
    }
    func saveChanges(){
        self.edit = false
    }
}
struct SimpleCompanyInfoView: View {
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: SimpleCompanyInfoViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : SimpleCompanyInfoViewModel
    
    @StateObject private var companyVM = CompanyViewModel()
    @State private var selectedPhoto:PhotosPickerItem? = nil
#if os(iOS)
    @State private var displayImage:UIImage? = nil
#endif

    @State private var displayURL:URL? = nil
    @State private var urlDisplayString:String? = nil
    
    var body: some View {
        ZStack{
            ScrollView{
                privateProfile
            }
            .fontDesign(.monospaced)
            .padding(8)
        }
        .navigationTitle(masterDataManager.currentCompany?.name ?? "")
        .task{
            if let company = masterDataManager.currentCompany {
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

//struct CompanyProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        @State var showSignInView: Bool = false
//        CompanyProfileView()
//    }
//}
extension SimpleCompanyInfoView {
    var privateProfile: some View {
        VStack {
            if let company = masterDataManager.currentCompany {
            VStack{
                image
                HStack{
                    VStack{
                        
                        Text("\(company.name)")
                            .font(.headline)
                    }
                    Spacer()
                    ZStack{
                        Circle()
                            .fill(.white)
                            .frame(maxWidth:80 ,maxHeight:80)
                        
                        Image(systemName: "38.circle")
                            .resizable()
                            .foregroundColor(Color.black)
                            .frame(maxWidth:80 ,maxHeight:80)
                            .cornerRadius(85)
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(.green,style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(maxWidth:75,maxHeight:75)
                            .rotationEffect(.degrees(-90))
                        
                    }
                }
            }
            Rectangle()
                .frame(height: 1)
            internalInfo
            Divider()
            externalInfo
            }
        }
    }

    var image: some View {
        ZStack{
            Circle()
                .fill(Color.gray)
                .frame(maxWidth:100 ,maxHeight:100)
            if let urlString = companyVM.imageUrlString,let url = URL(string: urlString){
                AsyncImage(url: url){ image in
                    image
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(Color.white)
                        .frame(maxWidth:95 ,maxHeight:95)
                        .cornerRadius(75)
                } placeholder: {
                    Image(systemName:"person.circle")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(Color.white)
                        .frame(maxWidth:95 ,maxHeight:95)
                        .cornerRadius(75)
                }
            } else {
                Image(systemName:"person.circle")
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(Color.white)
                    .frame(maxWidth:95 ,maxHeight:95)
                    .cornerRadius(75)
            }
            if let currentCompany = masterDataManager.currentCompany {
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
                .padding(16)
                
            }
        }
        .frame(maxWidth: 150,maxHeight:150)
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
    }
    var internalInfo: some View {
        VStack{
            Text("Company Info:")
            Text("Clients Under Contract:")
            Text("Monthly Profit:")
            Text("Monthly Revenue:")
        }
    }
    var externalInfo: some View {
        VStack{
            if let company = masterDataManager.currentCompany {
                Text("External Info Info:")
                HStack{
                    Text("Regions Services:")
                        .bold()
                    Spacer()
                }
                ScrollView(.horizontal){
                    HStack{
                        ForEach(company.serviceZipCodes,id:\.self){ tag in
                            HStack{
                                Text(tag)
                                    .modifier(BlueTagModifier())
                            }
                        }
                    }
                }
                HStack{
                    Text("Services Offered:")
                        .bold()
                    Spacer()
                }
                ScrollView(.horizontal){
                    HStack{
                        ForEach(company.services,id:\.self){ tag in
                            HStack{
                                Text(tag)
                                    .modifier(BlueTagModifier())
                            }
                        }
                    }
                }
            }
        }
    }
    var reviews: some View {
        VStack{
            HStack{
                Text("Drop Drop Rating")
                .bold()
                Spacer()
                Button(action: {
                    
                }, label: {
                    HStack{
                        Text("Reviews")
                        Image(systemName: "arrow.right")
                    }
                    .modifier(RedLinkModifier())
                })
            }
            HStack{
                Image(systemName: "star.fill")
                    .foregroundColor(Color.poolYellow)
                Image(systemName: "star.fill")
                    .foregroundColor(Color.poolYellow)
                Image(systemName: "star.fill")
                    .foregroundColor(Color.poolYellow)
                Image(systemName: "star.fill")
                    .foregroundColor(Color.poolYellow)
                Image(systemName: "star")
                    .foregroundColor(Color.poolYellow)
                Spacer()
            }
            
            HStack{
                Text("Drop Drop Reputation")
                .bold()
                Spacer()
            }
            Text("Score based on completing work and paying out")
                .font(.footnote)
            HStack{
                Text("Yelp Rating")
                    .bold()
                Spacer()
                Button(action: {
                    
                }, label: {
                    HStack{
                        Text("Yelp Profile")
                        Image(systemName: "arrow.right")
                    }
                    .modifier(RedLinkModifier())
                })
            }

        }
    }
}

