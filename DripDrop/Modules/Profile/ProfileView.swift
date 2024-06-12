//
//  ProfileView.swift
//  ClientSide
//
//  Created by Michael Espineli on 11/30/23.
//

import SwiftUI
import PhotosUI
import Charts
struct ProfileView: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject private var VM : AuthenticationViewModel
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var userAccessVM = UserAccessViewModel()

    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
    }
    
    @State private var selectedPhoto:PhotosPickerItem? = nil
    #if os(iOS)
    @State private var displayImage:UIImage? = nil
    #endif
    @State private var displayURL:URL? = nil
    @State private var urlDisplayString:String? = nil

    @State var level:Int = 0
    @State var percentage:Double = 0
    @State var expToNext:Double = 0

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        ZStack{

                            VStack(spacing: 10){
                                Divider()
                                companies
                                Divider()
                                ScrollView(.horizontal,showsIndicators: false){
                                    HStack{
                                        rateSheet
                                        recentActivity
                                        sendInvoice
                                    }
                                }
                                chartStuff
                                Spacer()
                            }
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                        }
                        .background(Color.listColor)
                        .foregroundColor(Color.white)
                        .cornerRadius(25)
                    }, header: {
                        profile
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                            .background(Color.poolBlue)
                    })
                    
                })

            }
            
        }
        .navigationTitle("\(masterDataManager.user?.firstName ?? "") \(masterDataManager.user?.lastName ?? "")")
//        .navigationBarBackground()
        .toolbar{
            ToolbarItem{
                if let user = masterDataManager.user {
                    NavigationLink(value: Route.userSettings(dataService: dataService), label: {
                        Image(systemName: "gear")
                    })
                    NavigationLink(value: Route.editUser(user: user,dataService: dataService), label: {
                        Image(systemName: "square.and.pencil")
                        
                    })
                }
            }
        }
        .task{
            if let user = masterDataManager.user {
                
                print("Arrived at Profile Page")
                do {
                    try await profileVM.loadCurrentUser()
          
                } catch {
                    print(error)
                }
                do {
                    try await userAccessVM.getAllUserAvailableCompanies(userId: user.id)
    
                } catch {
                    print(error)
                }
                print("Calculating Exp")
                    let thing = calculateLevel(exp:user.exp)
                    level = thing.level
                    percentage = thing.percentage
                    expToNext = thing.expToNextlevel
            }
        }
        .onChange(of: selectedPhoto, perform: { newValue in
            if let user = masterDataManager.user {
                
                if let newValue {
                    Task{
                        print("Save Profile Image")
                        profileVM.saveProfileImage(user: user, item: newValue)
                    }
                }
            }
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static let dataService = MockDataService()
    static var previews: some View {
        ProfileView(dataService:dataService)
    }
}
extension ProfileView {
    var bio: some View {
        ZStack{
            if let user = masterDataManager.user {
                
                VStack{
                    HStack{
                        Text("Email: ")
                        Spacer()
                        Text("\(user.email ?? "")")
                    }
                    HStack{
                        Text("Date Created: ")
                        Spacer()
                        Text("\(fullDate(date:user.dateCreated))")
                        
                    }
                    HStack{
                        Text("Bio: ")
                        Spacer()
                        Text("\(user.bio ?? "")")
                    }
                }
            }
        }
    }
    var companies: some View {
        VStack{
            Text("Company Access")
                .font(.headline)
            ScrollView(.horizontal,showsIndicators: false){
                HStack{
                 
                    ForEach(userAccessVM.allAvailableAccess){ access in
                        Button(action: {
                            Task{
                                print("Get Company From User Access")
                            }
                        }, label: {
                            VStack{
                                Text("\(access.companyName)")
                                Text("\(access.roleName)")
                                Text("Account Type: SubContractor")
                            }
                        })
                     
                    }
                }
            }
        }
        .foregroundColor(Color.basicFontText)
    }
    var rateSheet: some View {
        VStack{
            if let user = masterDataManager.user {
                HStack{
                    Spacer()
             
                        NavigationLink(value: Route.rateSheet(user: user, dataService: dataService), label: {

                        HStack{
                            Text("Rate Sheet")
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(Color.reverseFontText)
                        .padding(5)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                    })
                }
            }
        }
    }
    var recentActivityEmployee: some View {
        VStack{
            
            HStack{
                Spacer()
                Button(action: {
                    
                    navigationManager.routes.append(Route.recentActivity(dataService: dataService))
                }, label: {
                    HStack{
                        Text("Recent Activity")
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(Color.reverseFontText)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(5)
                })
            }
        }
    }
    var recentActivity: some View {
        VStack{
            
            HStack{
                Spacer()
                    NavigationLink(value: Route.recentActivity(dataService: dataService), label: {

                    HStack{
                        Text("Recent Activity")
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(Color.reverseFontText)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(5)
                })
            }
        }
    }
    var chartStuff: some View {
        mockChart(numbers: [1,4,7,3,6,8,3,4,9,3,5,7,1,3,7,4,7])
    }
    var sendInvoice: some View {
        VStack{
            
            HStack{
                Spacer()
      
                    NavigationLink(value: Route.compileInvoice(dataService: dataService), label: {

                    HStack{
                        Text("Send Invoice")
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(Color.reverseFontText)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(5)
                })
            }
        }
    }
    var image: some View {
        ZStack{
            Circle()
                .fill(Color.gray)
                .frame(maxWidth:100 ,maxHeight:100)
            if let urlString = profileVM.imageUrlString,let url = URL(string: urlString){
                AsyncImage(url: url){ image in
                    image
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(Color.white)
                        .frame(maxWidth:90 ,maxHeight:90)
                        .cornerRadius(75)
                } placeholder: {
                    Image(systemName:"person.circle")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(Color.white)
                        .frame(maxWidth:90 ,maxHeight:90)
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
        }
        .frame(maxWidth: 150,maxHeight:150)
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
    }
    var profile: some View {
        ZStack{
            Color.poolBlue
            if let user = masterDataManager.user {
                VStack{
                    HStack{
                        image
                        
                        VStack{
                            VStack{
//                                    HStack{
//                                        Text((user.firstName ?? "...Loading") + " " + (user.lastName ?? "...Loading"))
//                                            .bold(true)
//                                        Spacer()
//                                    }
                                HStack{
                                    Spacer()
                                    ZStack{
                                        Circle()
                                            .fill(.white)
                                            .frame(maxWidth:50 ,maxHeight:50)
                                        
                                        Text("\(calculateLevel(exp:user.exp).level)")
                                            .bold(true)
                                            .foregroundColor(Color.black)
                                            .frame(maxWidth:50 ,maxHeight:50)
                                            .cornerRadius(85)
                                        Circle()
                                            .stroke(Color.reverseFontText,style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                            .frame(maxWidth:50,maxHeight:50)
                                        Circle()
                                            .trim(from: 0, to: calculateLevel(exp:user.exp).percentage)
                                            .stroke(Color.poolGreen,style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                            .frame(maxWidth:50,maxHeight:50)
                                            .rotationEffect(.degrees(-90))
                                        
                                    }
                                }
                                
                            }
                            
                        }
                    }
                    bio
                }
                .foregroundColor(Color.white)

            }
        }
    }
}

