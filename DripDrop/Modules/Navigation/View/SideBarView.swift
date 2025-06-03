//
//  SideBarView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//

import SwiftUI

struct SideBarView: View {
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject private var chatVM : ChatViewModel
    @Binding var selectedCategory: MacCategories?
    @State var role:Role
    

    init(dataService:any ProductionDataServiceProtocol,role:Role,selectedCategory:Binding<MacCategories?>){
        _chatVM = StateObject(wrappedValue: ChatViewModel(dataService: dataService))
        _role = State(wrappedValue: role)
        self._selectedCategory = selectedCategory
    }
    
    @State private var showSettings:Bool = false
    @State var layoutExperience: LayoutExperienceSetting? = .threeColumn
    @State var unreadMessageCount:Int = 0
    @State var viewType:String = "Company"
    @State var viewPicker:[String] = ["Company","Personal"]
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            mac2
            Text("")
                .sheet(isPresented: $showSettings, content: {
                    SettingsView(dataService:dataService)
                })
        }
        .navigationTitle(masterDataManager.currentCompany?.name ?? "Menu")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackground()
        .task{
            if let user = masterDataManager.user {
                chatVM.addListenForUnReadChats(userId: user.id)
            }
        }
        .onChange(of: masterDataManager.selectedCategory, perform: { cat in
            print("Sid Bar Selected Category \(cat)")
        })
        .onChange(of: chatVM.listOfChats, perform: { num in
            print("Number of unread Chats \(num.count)")
                unreadMessageCount = num.count
            
        })
        .onDisappear(perform:{
            chatVM.removeListenerForChats()
        })
        .toolbar{
            Button(action: {
                showSettings.toggle()
            }, label: {
                Image(systemName: "gear")
            })
        }
    }
}

extension SideBarView {
    var mac2: some View {
        VStack{
            Picker("View Type", selection: $viewType) {
                ForEach(viewPicker,id: \.self){ stat in
                    Text(stat).tag(stat)
                }
            }
            .pickerStyle(.segmented)
            switch viewType {
            case "Company":
                companyLink
                MyCompany(dataService: dataService)
            case "Personal":
                profileLink
                All(dataService: dataService)
            default:
                MyCompany(dataService: dataService)
            }
        }
        .listStyle(.plain)
    }
    var companyLink: some View {
        VStack{
            if UIDevice.isIPhone {
                NavigationLink(value: MacCategories.companyProfile, label: {
                    switch masterDataManager.mainScreenDisplayType {
                    case .compactList:
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(maxWidth:35 ,maxHeight:35)
                                    .overlay(
                                        ZStack{
                                            if let company = masterDataManager.currentCompany,let urlString = company.photoUrl ,let url = URL(string: urlString){
                                                AsyncImage(url: url){ image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:30 ,maxHeight:30)
                                                        .cornerRadius(30)
                                                } placeholder: {
                                                    Image(systemName:"person.circle")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:30 ,maxHeight:30)
                                                        .cornerRadius(30)
                                                }
                                            }
                                        }
                                    )
                                
                            }
                            Spacer()

                            if let company = masterDataManager.currentCompany {
                                Text("\(company.name)")
                                    .foregroundColor(Color.basicFontText)
                            }
                        }
                    case .preview:
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(maxWidth:55 ,maxHeight:55)
                                    .overlay(
                                        ZStack{
                                            if let company = masterDataManager.currentCompany,let urlString = company.photoUrl ,let url = URL(string: urlString){
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
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:50 ,maxHeight:50)
                                                        .cornerRadius(50)
                                                }
                                            }
                                        }
                                    )
                                
                            }
                            Spacer()
                            if let company = masterDataManager.currentCompany {
                                Text("\(company.name)")
                                    .foregroundColor(Color.basicFontText)
                            }
                        }
                    case .fullPreview:
                        
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(maxWidth:150 ,maxHeight:100)
                                    .overlay(
                                        ZStack{
                                            if let company = masterDataManager.currentCompany,let urlString = company.photoUrl ,let url = URL(string: urlString){
                                                AsyncImage(url: url){ image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:90 ,maxHeight:90)
                                                        .cornerRadius(90)
                                                } placeholder: {
                                                    Image(systemName:"person.circle")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:90 ,maxHeight:90)
                                                        .cornerRadius(90)
                                                }
                                            }
                                        }
                                    )
                                
                            }
                            Spacer()
                            if let company = masterDataManager.currentCompany {
                                Text("\(company.name)")
                                    .foregroundColor(Color.basicFontText)
                                    .font(.title)
                            }
                        }
                    }
                })
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
            } else {
                Button(action: {
                    masterDataManager.selectedCategory = .companyProfile
                    masterDataManager.selectedCompany1 = masterDataManager.currentCompany
                }, label: {
                    switch masterDataManager.mainScreenDisplayType {
                    case .compactList:
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(maxWidth:35 ,maxHeight:35)
                                    .overlay(
                                        ZStack{
                                            if let company = masterDataManager.currentCompany,let urlString = company.photoUrl ,let url = URL(string: urlString){
                                                AsyncImage(url: url){ image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:30 ,maxHeight:30)
                                                        .cornerRadius(30)
                                                } placeholder: {
                                                    Image(systemName:"person.circle")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:30 ,maxHeight:30)
                                                        .cornerRadius(30)
                                                }
                                            }
                                        }
                                    )
                                
                            }
                            Spacer()
                            if let company = masterDataManager.currentCompany {
                                Text("\(company.name)")
                                    .foregroundColor(Color.basicFontText)
                            }
                        }
                    case .preview:
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(maxWidth:55 ,maxHeight:55)
                                    .overlay(
                                        ZStack{
                                            if let company = masterDataManager.currentCompany,let urlString = company.photoUrl ,let url = URL(string: urlString){
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
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:50 ,maxHeight:50)
                                                        .cornerRadius(50)
                                                }
                                            }
                                        }
                                    )
                                
                            }
                            Spacer()
                            if let company = masterDataManager.currentCompany {
                                Text("\(company.name)")
                                    .foregroundColor(Color.basicFontText)
                            }
                        }
                    case .fullPreview:
                        
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(maxWidth:150 ,maxHeight:100)
                                    .overlay(
                                        ZStack{
                                            if let company = masterDataManager.currentCompany,let urlString = company.photoUrl ,let url = URL(string: urlString){
                                                AsyncImage(url: url){ image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:90 ,maxHeight:90)
                                                        .cornerRadius(90)
                                                } placeholder: {
                                                    Image(systemName:"person.circle")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:90 ,maxHeight:90)
                                                        .cornerRadius(90)
                                                }
                                            }
                                        }
                                    )
                                
                            }
                            Spacer()
                            if let company = masterDataManager.currentCompany {
                                Text("\(company.name)")
                                    .foregroundColor(Color.basicFontText)
                                    .font(.title)
                            }
                        }
                    }

                })
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
            }

        }
    }
    var profileLink: some View {
        VStack{
            if UIDevice.isIPhone {
                NavigationLink(value: MacCategories.profile, label: {
                    switch masterDataManager.mainScreenDisplayType {
                    case .compactList:
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(maxWidth:35 ,maxHeight:35)
                                    .overlay(
                                        ZStack{
                                            if let user = masterDataManager.user,let urlString = user.photoUrl,let url = URL(string: urlString){
                                                AsyncImage(url: url){ image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:30 ,maxHeight:30)
                                                        .cornerRadius(30)
                                                } placeholder: {
                                                    Image(systemName:"person.circle")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:30 ,maxHeight:30)
                                                        .cornerRadius(30)
                                                }
                                            }
                                        }
                                    )
                                
                            }
                            Spacer()

                            if let user = masterDataManager.user {
                                Text("\(user.firstName ?? "NA") \(user.lastName ?? "NA")")
                                    .foregroundColor(Color.basicFontText)
                            }
                        }
                    case .preview:
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(maxWidth:55 ,maxHeight:55)
                                    .overlay(
                                        ZStack{
                                            if let user = masterDataManager.user,let urlString = user.photoUrl,let url = URL(string: urlString){
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
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:50 ,maxHeight:50)
                                                        .cornerRadius(50)
                                                }
                                            }
                                        }
                                    )
                                
                            }
                            Spacer()

                            if let user = masterDataManager.user {
                                Text("\(user.firstName ?? "NA") \(user.lastName ?? "NA")")
                                    .foregroundColor(Color.basicFontText)
                            }
                        }
                    case .fullPreview:
                        
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(maxWidth:150 ,maxHeight:100)
                                    .overlay(
                                        ZStack{
                                            if let user = masterDataManager.user,let urlString = user.photoUrl,let url = URL(string: urlString){
                                                AsyncImage(url: url){ image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:90 ,maxHeight:90)
                                                        .cornerRadius(90)
                                                } placeholder: {
                                                    Image(systemName:"person.circle")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:90 ,maxHeight:90)
                                                        .cornerRadius(90)
                                                }
                                            }
                                        }
                                    )
                                
                            }
                            Spacer()

                            if let user = masterDataManager.user {
                                Text("\(user.firstName ?? "NA") \(user.lastName ?? "NA")")
                                    .foregroundColor(Color.basicFontText)
                                    .font(.title)
                            }
                        }
                    }
                })
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
            } else {
                Button(action: {
                    masterDataManager.selectedCategory = .profile
                }, label: {
                    switch masterDataManager.mainScreenDisplayType {
                    case .compactList:
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(maxWidth:35 ,maxHeight:35)
                                    .overlay(
                                        ZStack{
                                            if let user = masterDataManager.user,let urlString = user.photoUrl,let url = URL(string: urlString){
                                                AsyncImage(url: url){ image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:30 ,maxHeight:30)
                                                        .cornerRadius(30)
                                                } placeholder: {
                                                    Image(systemName:"person.circle")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:30 ,maxHeight:30)
                                                        .cornerRadius(30)
                                                }
                                            }
                                        }
                                    )
                                
                            }
                            Spacer()
                            if let user = masterDataManager.user {
                                Text("\(user.firstName ?? "NA") \(user.lastName ?? "NA")")
                                    .foregroundColor(Color.basicFontText)
                            }
                        }
                    case .preview:
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(maxWidth:55 ,maxHeight:55)
                                    .overlay(
                                        ZStack{
                                            if let user = masterDataManager.user,let urlString = user.photoUrl,let url = URL(string: urlString){
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
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:50 ,maxHeight:50)
                                                        .cornerRadius(50)
                                                }
                                            }
                                        }
                                    )
                                
                            }
                            Spacer()

                            if let user = masterDataManager.user {
                                Text("\(user.firstName ?? "NA") \(user.lastName ?? "NA")")
                                    .foregroundColor(Color.basicFontText)
                            }
                        }
                    case .fullPreview:
                        
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color.gray)
                                    .frame(maxWidth:150 ,maxHeight:100)
                                    .overlay(
                                        ZStack{
                                            if let user = masterDataManager.user,let urlString = user.photoUrl,let url = URL(string: urlString){
                                                AsyncImage(url: url){ image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:90 ,maxHeight:90)
                                                        .cornerRadius(90)
                                                } placeholder: {
                                                    Image(systemName:"person.circle")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(Color.white)
                                                        .frame(maxWidth:90 ,maxHeight:90)
                                                        .cornerRadius(90)
                                                }
                                            }
                                        }
                                    )
                                
                            }
                            Spacer()

                            if let user = masterDataManager.user {
                                Text("\(user.firstName ?? "NA") \(user.lastName ?? "NA")")
                                    .foregroundColor(Color.basicFontText)
                                    .font(.title)
                            }
                        }
                    }

                })
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
            }

        }
    }
    var personal: some View {
        Group{
            Section(content: {
                NavigationLink(value: MacCategories.chat, label: {
                    HStack{
                        Image(systemName: MacCategories.chat.imageName())
                        Text(MacCategories.chat.title())
                        
                            if  unreadMessageCount == 0 {
                                
                            } else if unreadMessageCount > 50 {
                                
                                Image(systemName: "50.circle.fill")
                                    .foregroundColor(Color.red)
                                Image(systemName: "plus")
                                    .foregroundColor(Color.red)
                            } else {
                                Image(systemName: "\(String(unreadMessageCount)).circle.fill")
                                    .foregroundColor(Color.red)
                            }
                        
                    }
                })
            }, header: {
                Text("Personal")
                    .font(.headline)
            })
        Section(content: {
            NavigationLink(value: MacCategories.marketPlace, label: {
                HStack{
                    Image(systemName: MacCategories.marketPlace.imageName())
                    Text(MacCategories.marketPlace.title())
                }
            })
            NavigationLink(value: MacCategories.jobPosting, label: {
                HStack{
                    Image(systemName: MacCategories.jobPosting.imageName())
                    Text(MacCategories.jobPosting.title())
                }
            })
            NavigationLink(value: MacCategories.feed, label: {
                HStack{
                    Image(systemName: MacCategories.feed.imageName())
                    Text(MacCategories.feed.title())
                }
            })
        }, header: {
            Text("Public")
                .font(.headline)
        })
        }
    }
}

