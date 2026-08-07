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
        ZStack(alignment: .bottomTrailing) {
            Color.listColor.ignoresSafeArea()
            VStack(spacing: 0) {
                messagesHeader
                searchField
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                list
            }
            composeDock
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
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
        Group {
            if filteredChats.isEmpty {
                ScrollView(showsIndicators: false) {
                    messagesEmptyState
                        .padding(.horizontal, 14)
                        .padding(.top, 4)

                    Color.clear.frame(height: 120)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredChats){ chat in
                            Button(action: { handleChatTap(chat) }){
                                ChatCardViewSmall(dataService: dataService, chat: chat)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }

                        Color.clear.frame(height: 120)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                }
            }
        }
    }

    private var messagesHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 48, height: 48)
                    .background(Color.poolBlue.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Messages")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(messagesListSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                messagesSummaryMetric(
                    title: "Showing",
                    value: "\(filteredChats.count)",
                    tint: .poolBlue
                )

                messagesSummaryMetric(
                    title: "Unread",
                    value: "\(unreadMessagesCount)",
                    tint: .orange
                )

                messagesSummaryMetric(
                    title: "Company",
                    value: "\(companyMessagesCount)",
                    tint: .poolGreen
                )
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Search messages", text: $searchTerm)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            if !searchTerm.isEmpty {
                Button(action: { searchTerm = "" }) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var messagesEmptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: searchTerm.isEmpty ? "bubble.left.and.bubble.right" : "magnifyingglass")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(searchTerm.isEmpty ? "No messages yet." : "No messages found.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(searchTerm.isEmpty ? "Start a new message when you are ready." : "Try another person, message, or linked record.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if searchTerm.isEmpty {
                Button(action: {
                    showNewChatSheet.toggle()
                }, label: {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("New Message")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.poolGreen, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                })
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var composeDock: some View {
        Button(action: {
            showNewChatSheet.toggle()
        }, label: {
            mobileDockIcon(systemName: "square.and.pencil", tint: .poolGreen)
        })
        .buttonStyle(.plain)
        .padding(7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.trailing, 14)
        .padding(.bottom, UIDevice.isIPhone ? 18 : 14)
        .accessibilityLabel("New Message")
        .sheet(isPresented: $showNewChatSheet, content: {
            NavigationStack {
                AddNewChatView(dataService: dataService, receivedCustomer: nil)
            }
        })
    }

    private func messagesSummaryMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func mobileDockIcon(systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 40, height: 40)
            .background(tint.opacity(0.13), in: Circle())
    }

    private var messagesListSubtitle: String {
        if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(chatVM.listOfChats.count) message thread\(chatVM.listOfChats.count == 1 ? "" : "s") for this workspace."
        }

        return "Search results for \"\(searchTerm)\"."
    }

    private var unreadMessagesCount: Int {
        guard let user = masterDataManager.user else { return 0 }
        return chatVM.listOfChats.filter {
            $0.isUnread(for: user.id, companyId: masterDataManager.currentCompany?.id)
        }.count
    }

    private var companyMessagesCount: Int {
        chatVM.listOfChats.filter {
            switch $0.visibility ?? .direct {
            case .company, .companyInternal, .companyExternal, .companyToCompany:
                return true
            case .customer, .direct:
                return false
            }
        }.count
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
