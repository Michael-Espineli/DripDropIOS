    //
    //  CompanyUserDetailView.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 1/21/24.
    //

import SwiftUI
import Foundation
@MainActor
final class CompanyUserDetailViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var screens: [String] = ["Info","Work","Money","Review"]
    @Published var selectedScreen: String = "Info"
    
    @Published private(set) var acceptedInviteList: [Invite] = []
    
    @Published private(set) var pendingInviteList: [Invite] = []
    
    @Published private(set) var companyUsers: [CompanyUser] = []
    
    @Published private(set) var specificTech: DBUser? = nil
    @Published private(set) var role: Role? = nil
    @Published var performaceHistoryList:[PerformaceHistory] = []
    func onLoad(companyId:String,companyUser:CompanyUser) async throws{
        self.specificTech = try await dataService.getOneUser(userId: companyUser.userId)
        self.role = try await dataService.getSpecificRole(companyId: companyId, roleId: companyUser.roleId)
        
        self.performaceHistoryList = MockDataService.mockPerformaceHistory
    }
    func getPerformaceReivewByUserId(companyId:String,companyUserId:String) async throws {
        self.performaceHistoryList = MockDataService.mockPerformaceHistory
    }
    func getOneTech(techId: String) async throws{
        self.specificTech = try await dataService.getOneUser(userId: techId)
    }
    
}
struct CompanyUserDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject var VM : CompanyUserDetailViewModel
    
    @State var receivedCompanyUser:CompanyUser
    init(dataService:any ProductionDataServiceProtocol,companyUser:CompanyUser) {
        _VM = StateObject(wrappedValue: CompanyUserDetailViewModel(dataService: dataService))
        _receivedCompanyUser = State(wrappedValue: companyUser)
    }
    @State var companyUser:CompanyUser? = nil
    
    @State private var showSheet:Bool = false
    @State var showNewPerformaceHistory:Bool = false
    @State var showPerformaceHistory:Bool = false
    @State var showNewWorkContract:Bool = false
    @State var showWorkContractList:Bool = false
    @State var seePermissions:Bool = false
    
    @State var tech: DBUser? = nil
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                screenPicker
                ScrollView(showsIndicators:false) {
                    screens
                }
            }
                //            .fontDesign(.monospaced)
            .padding(.horizontal,8)
        }
        .task{
            do {
                companyUser = receivedCompanyUser
                if let companyUser, let company = masterDataManager.currentCompany {
                    try await VM.onLoad(companyId: company.id, companyUser: companyUser)
                } else {
                    print("Company User Error")
                }
            } catch {
                print("Error Getting DetailView")
                print(error)
            }
        }
        .onChange(of: masterDataManager.selectedCompanyUser, perform: { user in
            Task{
                if let user {
                    companyUser = user
                    if let companyUser, let currentCompany = masterDataManager.currentCompany {
                        try await VM.onLoad(companyId: currentCompany.id, companyUser: companyUser)
                    } else {
                        print("Company User Error")
                    }
                }
            }
        })
        .toolbar{
            ToolbarItem(content: {
                Button(action: {
                    showSheet.toggle()
                }, label: {
                    Text("Edit")
                        .modifier(EditButtonModifier())
                })
                
            })
        }
    }
}
extension CompanyUserDetailView {
    var screenPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack{
                ForEach(VM.screens,id:\.self){ screen in
                    Button(action: {
                        
                        VM.selectedScreen = screen
                        
                    }, label: {
                        if screen == VM.selectedScreen {
                            Text(screen)
                                .modifier(AddButtonModifier())
                        } else {
                            Text(screen)
                                .modifier(ListButtonModifier())
                        }
                    })
                    
                }
            }
        }
    }
    var screens: some View {
        VStack{
            switch VM.selectedScreen {
            case "Info":
                companyUserInfo
                Rectangle()
                    .frame(height: 1)
                overView
            case "Work":
                recentActivity
            case "Money":
                monies
            case "Review":
                performaceHistory
            default:
                
                companyUserInfo
                Rectangle()
                    .frame(height: 1)
                overView
            }
        }
    }
    var allInOne: some View {
        VStack{
            companyUserInfo
            Rectangle()
                .frame(height: 1)
            overView
            Rectangle()
                .frame(height: 4)
            Text("Can See Private Job Board // Make Into A permission")
            if UIDevice.isIPhone {
                VStack{
                    recentActivity
                    Rectangle()
                        .frame(height: 4)
                    monies
                    Rectangle()
                        .frame(height: 4)
                    performaceHistory
                }
            } else {
                VStack{
                    recentActivity
                    Rectangle()
                        .frame(height: 4)
                    monies
                    Rectangle()
                        .frame(height: 4)
                    performaceHistory
                }
            }
        }
    }
    var companyUserInfo: some View {
        VStack{
            VStack{
                if let tech = VM.specificTech, let imageLink = tech.photoUrl {
                    ZStack{
                        if UIDevice.isIPhone {
                            
                            Circle()
                                .foregroundColor(Color.darkGray)
                                .frame(maxWidth:110 ,maxHeight:110)
                        } else {
                            Circle()
                                .foregroundColor(Color.darkGray)
                                .frame(maxWidth:165 ,maxHeight:165)
                        }
                        if let url = URL(string: imageLink){
                            if UIDevice.isIPhone {
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
                                        .foregroundColor(Color.white)
                                        .frame(maxWidth:150 ,maxHeight:150)
                                        .cornerRadius(150)
                                }
                            }
                        }else {
                            Image(systemName:"person.circle")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.white)
                                .frame(maxWidth:150 ,maxHeight:150)
                                .cornerRadius(150)
                            
                        }
                    }
                    .padding(3)
                    VStack(alignment: .leading){
                        HStack{
                            Text("Personal Info")
                                .font(.headline)
                            Spacer()
                        }
                        Divider()
                        HStack{
                            Text("\(tech.firstName)")
                            Text("\(tech.lastName)")
                        }
                        Text("Email: ")
                            .bold()
                        Text("\(tech.email)")
                        
                        Text("Phone Number:")
                            .bold()
                        
                        Text("+(619)490-6830")
                        
                        HStack{
                            Text("Bio: ")
                                .bold()
                            if let bio = tech.bio {
                                Text("\(bio)")
                            }
                            Spacer()
                            
                        }
                    }
                    
                }
            }
            VStack(alignment: .leading){
                Rectangle()
                    .frame(height: 1)
                if let companyUser  {
                    Text("Company Info")
                        .font(.headline)
                    Divider()
                    
                    HStack{
                        Text("Position:")
                        Text("\(companyUser.roleName)")
                        
                        Spacer()
                        if UIDevice.isIPhone {
                            if let role = VM.role{
                                NavigationLink(value: Route.editRole(dataService: dataService, role: role), label: {
                                    
                                    HStack{
                                        Text("Role Details")
                                        Image(systemName: "arrow.right")
                                    }
                                    .foregroundColor(Color.poolRed)
                                })
                            }
                        } else {
                            Button(action: {
                                seePermissions.toggle()
                            }, label: {
                                HStack{
                                    Text("See Permissions")
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundColor(Color.poolRed)
                            })
                            
                            .sheet(isPresented: $seePermissions, content: {
                                CompanyRoleLoadingView(roleId: companyUser.roleId)
                            })
                        }
                    }
                    Divider()
                    Text("Date Created: \(fullDate(date:companyUser.dateCreated))")
                    HStack{
                        Text("Worker Type:")
                        Text("\(companyUser.workerType.rawValue)")
                        
                    }
                    if companyUser.workerType == .contractor {
                        HStack{
                            Text("Company:")
                            Text("If sub Contractor then show linkedCompany")
                            Spacer()
                            
                        }
                        .padding(.leading,16)
                    }
                    HStack{
                        Text("Status:")
                        switch companyUser.status {
                        case .active:
                            Text("\(companyUser.status.rawValue)")
                                .modifier(SubmitButtonModifier())
                        case .pending:
                            Text("\(companyUser.status.rawValue)")
                                .modifier(YellowButtonModifier())
                        case .past:
                            Text("\(companyUser.status.rawValue)")
                                .modifier(DismissButtonModifier())
                        }
                        
                    }
                        //                    NavigationLink(value: Route.companyUserRateSheet(user: companyUser,dataService: dataService), label: {
                        //                        Text("Rate Sheet")
                        //                            .foregroundColor(Color.white)
                        //                            .padding(5)
                        //                            .background(Color.poolBlue)
                        //                            .cornerRadius(5)
                        //                    })
                }
                Divider()
            }
        }
        .sheet(isPresented: $showSheet, content: {
            if let companyUser {
                EditCompanyUserView(dataService: dataService, tech: companyUser)
            }
        })
    }
    var overView: some View {
        ScrollView{
            Text("Over View")
                .font(.title)
            Rectangle()
                .frame(height: 1)
            HStack{
                Button(action: {
                    showNewWorkContract.toggle()
                }, label: {
                    Text("Add")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $showNewWorkContract, content: {
                    ScrollView{
                            //                        AddNewLaborContract(dataService: dataService, associatedBusiness: business)
                        Text("AddNewLaborContract")
                    }
                })
                Spacer()
                Text("Contracts")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showWorkContractList.toggle()
                }, label: {
                    HStack{
                        Text("See More")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(Color.poolRed)
                })
                .sheet(isPresented: $showWorkContractList, content: {
                    RecurringLaborContractListView(dataService: dataService)
                })
            }
            VStack{
                ForEach(MockDataService.mockRecurringLaborContracts){ contract in
                    RecurringLaborContractCardView(laborContract: contract)
                }
            }
            
        }
    }
    
    var recentActivity: some View {
        VStack{
            Text("Recent Activity")
                .font(.title)
            Rectangle()
                .frame(height: 1)
            VStack{
                VStack{
                    HStack{
                        Text("Service Stops")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            
                        }, label: {
                            HStack{
                                Text("See More")
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(Color.poolRed)
                        })
                    }
                    Text("Service Stops - 34")
                }
                Rectangle()
                    .frame(height: 1)
                VStack{
                    HStack{
                        Text("Jobs")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            
                        }, label: {
                            HStack{
                                Text("See More")
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(Color.poolRed)
                        })
                    }
                    Text("Filter Cleans - 34")
                }
                Rectangle()
                    .frame(height: 1)
                VStack{
                    HStack{
                        Text("Recently Purchased")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            
                        }, label: {
                            HStack{
                                Text("See More")
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(Color.poolRed)
                        })
                    }
                    Text("Items - 34")
                    Text("Total - 3465")
                }
                Rectangle()
                    .frame(height: 1)
            }
        }
    }
    
    var monies: some View {
        VStack{
            Text("Money")
                .font(.title)
            Rectangle()
                .frame(height: 1)
            VStack{
                
                HStack{
                    Text("Work Done and Not Billed")
                    Spacer()
                    Text(" $304.76")
                    Button(action: {
                        
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(Color.poolRed)
                    })
                }
                Divider()
                HStack{
                    Text("Money Due")
                    Spacer()
                    Text("$1642.76")
                    Button(action: {
                        
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(Color.poolRed)
                    })
                }
                Divider()
                HStack{
                    Text("Recently Paid")
                    Spacer()
                    Text("$3,278.76")
                    Button(action: {
                        
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(Color.poolRed)
                    })
                }
                Divider()
                HStack{
                    Text("Year To Date")
                    Spacer()
                    Text("$48,642.76")
                    Button(action: {
                        
                    }, label: {
                        HStack{
                            Text("See More")
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(Color.poolRed)
                    })
                }
            }
        }
    }
    var performaceHistory: some View {
        ScrollView{
            HStack{
                Spacer()
                Text("Performace History")
                    .font(.title)
                Spacer()
            }
            HStack{
                Button(action: {
                    showNewPerformaceHistory.toggle()
                }, label: {
                    Text("Add")
                        .modifier(AddButtonModifier())
                })
                .sheet(isPresented: $showNewPerformaceHistory, content: {
                    AddNewPerformanceHistory(dataService: dataService, companyUser: receivedCompanyUser)
                })
                Spacer()
                Button(action: {
                    showPerformaceHistory.toggle()
                }, label: {
                    HStack{
                        Text("See More")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(Color.poolRed)
                })
                .sheet(isPresented: $showPerformaceHistory, content: {
                    PerformaceHistoryList(dataService: dataService, companyUser: receivedCompanyUser)
                })
            }
            
            Rectangle()
                .frame(height: 1)
            ForEach(VM.performaceHistoryList){ performace in
                PerformanceHistoryCardView(performanceHistory: performace)
            }
        }
    }
    var icons: some View {
        
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
            .padding(8)
        }
        
    }
}
