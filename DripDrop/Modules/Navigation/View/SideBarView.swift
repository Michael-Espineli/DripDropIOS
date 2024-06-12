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
    
    @State private var showSettings = false
    @State var layoutExperience: LayoutExperienceSetting? = .threeColumn
    @State var unreadMessageCount:Int = 0
    @State var viewType:String = "Company"
    @State var viewPicker:[String] = ["Company","Personal"]
    var body: some View {
        ZStack{
                mac
        }
        .navigationTitle("Menu")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackground()
                .sheet(isPresented: $showSettings, content: {
                    SettingsView(dataService:dataService)
                })
                .toolbar{
                    Button(action: {
                        showSettings.toggle()
                    }, label: {
                        Image(systemName: "gear")
                    })
                }
        .task{
            if let user = masterDataManager.user {
                chatVM.addListenForUnReadChats(userId: user.id)
            }
        }
        .onChange(of: chatVM.listOfChats, perform: { num in
            print("Number of unread Chats \(num.count)")
                unreadMessageCount = num.count
            
        })
        .onDisappear(perform:{
            chatVM.removeListenerForChats()
        })
//        #if os(iOS)
//        .navigationBarTitleDisplayMode(.inline)
//        #endif
    }
}

extension SideBarView {
    var mac: some View {
        List(selection: $selectedCategory) {
            Section{
                NavigationLink(value: MacCategories.profile, label: {
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
                        if let user = masterDataManager.user {
                            Text("\(user.firstName ?? "NA") \(user.lastName ?? "NA")")
                        }
                    }
                })
                .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
            }
            Picker("View Type", selection: $viewType) {
                ForEach(viewPicker,id: \.self){ stat in
                    Text(stat).tag(stat)
                }
            }
            .pickerStyle(.segmented)
            switch viewType {
            case "Company":
                company
            case "Personal":
                personal
            default:
                company
            }
        }
        .listStyle(.plain)
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
    var company: some View {
            Group{
                if role.permissionIdList.contains("11") {
                    Section(content: {
                        
                        NavigationLink(value: MacCategories.dashBoard, label: {
                            HStack{
                                Image(systemName: MacCategories.dashBoard.imageName())
                                Text(MacCategories.dashBoard.title())
                            }
                        })
//                        NavigationLink(value: MacCategories.dailyDisplay, label: {
//                            HStack{
//                                Image(systemName: MacCategories.dailyDisplay.imageName())
//                                Text(MacCategories.dailyDisplay.title())
//                            }
//                        })
                        NavigationLink(value: MacCategories.customers, label: {
                            HStack{
                                Image(systemName: MacCategories.customers.imageName())
                                Text(MacCategories.customers.title())
                            }
                        })
                        NavigationLink(value: MacCategories.serviceStops, label: {
                            HStack{
                                Image(systemName: MacCategories.serviceStops.imageName())
                                Text(MacCategories.serviceStops.title())
                            }
                        })
                       
                    }, header: {
                        Text("Operations")
                            .font(.headline)

                    })
                }
                    //Permission 7
                    Section(content: {
                        if role.permissionIdList.contains("12") {
                            
                                NavigationLink(value: MacCategories.routeBuilder, label: {
                                    HStack{
                                        Image(systemName: MacCategories.routeBuilder.imageName())
                                        Text(MacCategories.routeBuilder.title())
                                    }
                                })
                                NavigationLink(value: MacCategories.management, label: {
                                    HStack{
                                        Image(systemName: MacCategories.management.imageName())
                                        Text(MacCategories.management.title())
                                    }
                                })
                   
                        }
                        if role.permissionIdList.contains("7") {
                            NavigationLink(value: MacCategories.fleet, label: {
                                HStack{
                                    Image(systemName: MacCategories.fleet.imageName())
                                    Text(MacCategories.fleet.title())
                                }
                            })
                        NavigationLink(value: MacCategories.jobs, label: {
                            HStack{
                                Image(systemName: MacCategories.jobs.imageName())
                                Text(MacCategories.jobs.title())
                            }
                        })
                        NavigationLink(value: MacCategories.repairRequest, label: {
                            HStack{
                                Image(systemName: MacCategories.repairRequest.imageName())
                                Text(MacCategories.repairRequest.title())
                            }
                        })
                        NavigationLink(value: MacCategories.contract, label: {
                            HStack{
                                Image(systemName: MacCategories.contract.imageName())
                                Text(MacCategories.contract.title())
                            }
                        })
                    }
                        
                    }, header: {
                        Text("Managment")
                            .font(.headline)

                    })
                
                if role.permissionIdList.contains("6") {
                    
                    Section(content: {
                        NavigationLink(value: MacCategories.purchases, label: {
                            HStack{
                                Image(systemName: MacCategories.purchases.imageName())
                                Text(MacCategories.purchases.title())
                            }
                        })
                        NavigationLink(value: MacCategories.receipts, label: {
                            HStack{
                                Image(systemName: MacCategories.receipts.imageName())
                                Text(MacCategories.receipts.title())
                            }
                        })
                        NavigationLink(value: MacCategories.databaseItems, label: {
                            HStack{
                                Image(systemName: MacCategories.databaseItems.imageName())
                                Text(MacCategories.databaseItems.title())
                            }
                        })
                        NavigationLink(value: MacCategories.genericItems, label: {
                            HStack{
                                Image(systemName: MacCategories.genericItems.imageName())
                                Text(MacCategories.genericItems .title())
                            }
                        })
                        NavigationLink(value: MacCategories.vender, label: {
                            HStack{
                                Image(systemName: MacCategories.vender.imageName())
                                Text(MacCategories.vender.title())
                            }
                        })
                    }, header: {
                        Text("Inventory")
                            .font(.headline)

                    })
                }
                if role.permissionIdList.contains("7") {
                
                    Section(content: {
                        NavigationLink(value: MacCategories.readingsAndDosages, label: {
                            HStack{
                                Image(systemName: MacCategories.readingsAndDosages.imageName())
                                Text(MacCategories.readingsAndDosages.title())
                            }
                        })
                        NavigationLink(value: MacCategories.reports, label: {
                            HStack{
                                Image(systemName: MacCategories.reports.imageName())
                                Text(MacCategories.reports.title())
                            }
                        })
                        NavigationLink(value: MacCategories.contract, label: {
                            HStack{
                                Image(systemName: MacCategories.contract.imageName())
                                Text(MacCategories.contract.title())
                            }
                        })
                        NavigationLink(value: MacCategories.maps, label: {
                            HStack{
                                Image(systemName: MacCategories.maps.imageName())
                                Text(MacCategories.maps.title())
                            }
                        })
                        NavigationLink(value: MacCategories.calendar, label: {
                            HStack{
                                Image(systemName: MacCategories.calendar.imageName())
                                Text(MacCategories.calendar.title())
                            }
                        })
                        NavigationLink(value: MacCategories.userRoles, label: {
                            HStack{
                                Image(systemName: MacCategories.userRoles.imageName())
                                Text(MacCategories.userRoles.title())
                            }
                        })
                        NavigationLink(value: MacCategories.users, label: {
                            HStack{
                                Image(systemName: MacCategories.users.imageName())
                                Text(MacCategories.users.title())
                            }
                        })
                        NavigationLink(value: MacCategories.companyProfile, label: {
                            HStack{
                                Image(systemName: MacCategories.companyProfile.imageName())
                                Text(MacCategories.companyProfile.title())
                            }
                        })
                    }, header: {
                        Text("Administraion")
                            .font(.headline)

                    })
                }
//                    ForEach(MacCategories.allCases) { category in
//                        NavigationLink(value: category, label: {
//                            HStack{
//                                Image(systemName: category.imageName())
//                                Text(category.title())
//                            }
//                        })
//                    }
                    
                
        }
    }

}

