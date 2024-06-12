//
//  ChatListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI

struct ChatListView: View {
    @State var showNewChatSheet:Bool = false
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    
    @StateObject private var chatVM : ChatViewModel
    
    init(dataService:any ProductionDataServiceProtocol){
        _chatVM = StateObject(wrappedValue: ChatViewModel(dataService: dataService))
    }
    @State var searchTerm:String = ""
    @State var chatList:[Chat] = []
    
    @State var showNewChat:Bool = false
    @State var showFilters:Bool = false
    @State var showSearch:Bool = false
    
    @State var startDate:Date = Date()
    @State var endDate:Date = Date()
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
                .padding(.horizontal,16)
            icons
        }
        .task {
            if let user = masterDataManager.user {
                chatVM.addListenerForAllChats(userId: user.id)
            } else{
                print("No User")
            }
            
        }
        
        .onChange(of: masterDataManager.selectedID, perform: { id in
            if let selectedId = id {
                if let company = masterDataManager.selectedCompany {
                    Task{
                        do {
                            try await chatVM.getSpecificChat(companyId: company.id, contractId: selectedId)
                            masterDataManager.selectedChat = chatVM.chat
                            print("Successfully Got Chat - Detail View")
                            
                        } catch {
                            print("Failed to Get Chat")
                        }
                    }
                }
            }
        })
        .onDisappear(perform: {
            chatVM.removeListenerForChats()
            
        })
    }
}
extension ChatListView {
    var icons: some View{
        VStack{
            if showSearch {
                Color.basicFontText.opacity(0.5)
                    .onTapGesture {
                        showSearch.toggle()
                    }
            }
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    Button(action: {
                        showNewChatSheet.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.poolBlue)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "square.and.pencil")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(Color.white)
                                )
                        }
                    })
                    .padding()
                    .sheet(isPresented: $showNewChatSheet, content: {
                        AddNewChatView(dataService: dataService)
                    })
                    
                }
            }
        }
    }
    
    var list: some View {
        ScrollView(showsIndicators: false) {
            HStack{
                TextField(
                    "Search Term",
                    text: $searchTerm,
                    axis: .vertical
                )
                .padding(8)
                .background(Color.black)
                .foregroundColor(Color.white)
                .clipShape(Capsule())
                .padding(.horizontal,16)
                .padding(.vertical,8)
            }
            if chatVM.listOfChats.count == 0 {
                Text("No Chats, Sorry you don't have friends")
            } else {
                ForEach(chatVM.listOfChats){ chat in
                    NavigationLink(value: Route.chat(chat: chat, dataService:dataService), label: {
                        ChatCardViewSmall(dataService: dataService, chat:chat)
                    })
                    Divider()
                    
                }
            }
        }
    }
}
