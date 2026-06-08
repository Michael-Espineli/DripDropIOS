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
    @EnvironmentObject var navigationManager: NavigationStateManager

    @StateObject private var chatVM : ChatViewModel
    
    init(dataService:any ProductionDataServiceProtocol){
        _chatVM = StateObject(wrappedValue: ChatViewModel(dataService: dataService))
    }
    @State var searchTerm:String = ""
    @State var chatList:[Chat] = []
    
    private var filteredChats: [Chat] {
        if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return chatVM.listOfChats }
        let lower = searchTerm.lowercased()
        return chatVM.listOfChats.filter { chat in
            // Match by other participant name (derive from participants)
            let currentUserId = masterDataManager.user?.id
            let title = chat.displayTitle(currentUserId: currentUserId).lowercased()
            if title.contains(lower) { return true }
            // Fallback: search in last message
            if chat.lastMessage.lowercased().contains(lower) { return true }
            if chat.contextLinks?.contains(where: { $0.title.lowercased().contains(lower) || $0.type.displayName.lowercased().contains(lower) }) == true { return true }
            return false
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing){
            Color.listColor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 12){
                // Header
                Text("Chats")
                    .font(.largeTitle).bold()
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal)
                    .padding(.top)
                list
                Spacer(minLength: 0)
            }
            // Floating New Chat Button
//            Update 4.1
            /*
            Button(action: {
                showNewChatSheet.toggle()
            }, label: {
                ZStack{
                    Circle()
                        .fill(Color.poolBlue)
                        .frame(width: 56, height: 56)
                        .shadow(radius: 4)
                    Image(systemName: "square.and.pencil")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                }
            })
            .padding()
            .sheet(isPresented: $showNewChatSheet, content: {
                AddNewChatView(dataService: dataService, receivedCustomer: nil)
            })
             */
        }
        .task {
            if let user = masterDataManager.user {
                chatVM.addListenerForVisibleChats(userId: user.id, companyId: masterDataManager.currentCompany?.id)
            } else{
                print("No User")
            }
        }
        
        .onChange(of: masterDataManager.selectedID, perform: { id in
            if let selectedId = id {
                if let company = masterDataManager.currentCompany {
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
    var list: some View {
        VStack(spacing: 0){
            // Search Field
            HStack(spacing: 8){
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.secondary)
                TextField("Search chats...", text: $searchTerm)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                if !searchTerm.isEmpty {
                    Button(action: { searchTerm = "" }){
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Color.secondary)
                    }
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .padding(.horizontal)
            .padding(.bottom, 8)

            if filteredChats.isEmpty {
                ScrollView { Text("No chats found.")
                        .foregroundStyle(Color.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0){
                        ForEach(filteredChats){ chat in
                            Button(action: { handleChatTap(chat) }){
                                ChatCardViewSmall(dataService: dataService, chat: chat)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func handleChatTap(_ chat: Chat) {
        Task {
            if let user = masterDataManager.user {
                try await dataService.markChatAsRead(userId: user.id, companyId: masterDataManager.currentCompany?.id, chat: chat)
            }
            // Navigate by setting the selected chat in masterDataManager
            if UIDevice.isIPhone {
                navigationManager.push(to: Route.chat(chat: chat, dataService: dataService))
            } else {
                masterDataManager.selectedChat = chat
            }
        }
    }
}
