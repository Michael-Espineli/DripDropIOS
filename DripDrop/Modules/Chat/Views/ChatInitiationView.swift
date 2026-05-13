//
//  ParticipantInfo.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/28/26.
//


import SwiftUI



struct ChatInitiationView: View {
    init(dataService:any ProductionDataServiceProtocol,otherParticipantId:String){
        self._otherParticipantId = State(initialValue: otherParticipantId)
    }
    // Inputs
    @State var otherParticipantId: String
    // Provide a navigation callback so this view stays generic
//    let onNavigateToChat: (String) -> Void
//    let onBack: () -> Void

    // Environment dependencies you can swap to your own managers
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var navigationManager: NavigationStateManager
    
    // If you have an Auth manager, inject it here as well
    // @EnvironmentObject var authManager: AuthManager

    // UI State
    @State private var newMessage: String = ""
    @State private var participantInfo: BasicUserInfo?
    @State private var isLoading: Bool = true
    @State private var errorText: String?

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            if isLoading {
                ProgressView("Loading chat...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header

                        VStack(spacing: 0) {
                            VStack {
                                Text("You are starting a new conversation with ")
                                    .foregroundColor(.secondary)
                                    + Text(participantInfo?.userName ?? "New Chat")
                                        .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)

                            Divider()

                            VStack {
                                HStack(spacing: 8) {
                                    TextField("Type your first message...", text: $newMessage)
                                        .textFieldStyle(.roundedBorder)
                                    Button {
                                        Task { await handleSendFirstMessage() }
                                    } label: {
                                        Image(systemName: "paperplane.fill")
                                            .foregroundColor(.white)
                                            .padding(10)
                                            .background(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                                            .clipShape(Circle())
                                    }
                                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                            .padding()
                            .background(Color.white)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)

                        if let errorText {
                            Text(errorText)
                                .foregroundColor(.red)
                        }

                        Spacer(minLength: 12)
                    }
                    .padding(16)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await findOrCreateChat()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New Message to \(participantInfo?.userName ?? "...")")
                .font(.title).bold()
                .foregroundColor(.primary)
        }
    }

    // MARK: - Flow

    private func findOrCreateChat() async {
        // TODO: Replace with your auth current user id
        // For example, from an AuthManager or FirebaseAuth: currentUserId
        
        guard let user = masterDataManager.user else {
            // If you’re using user auth, swap to your user id
            errorText = "Missing current user/company context."
            isLoading = false
            return
        }
        print("[findOrCreateChat] user \(user)")
        do {
            // 1) Check if chat exists between current and participant (both orders).
            // TODO: Query your backend (Firestore) for an existing chat where
            // participantIds == [currentCompanyId, participantId] or [participantId, currentCompanyId]
            
            if let existingChat = try await dataService.getChatBySenderAndReceiver(senderId: user.id, receiverId: otherParticipantId) {
                print("[findOrCreateChat] existingChat \(existingChat)")
                print("")
                print("[findOrCreateChat] Trying to navigate forward")

//                navigationManager.goBack()
//                navigationManager.push(to: Route.chat(chat: existingChat, dataService: dataService))
//                navigationManager.replaceLast(new: Route.chat(chat: existingChat, dataService: dataService))
                navigationManager.replace(stack: [Route.chat(chat: existingChat, dataService: dataService)])
                return
            }
            
            // 2) Load participant info (user or company)
            participantInfo = try await loadParticipantInfo(participantId: otherParticipantId)
            
            print("[findOrCreateChat] participantInfo \(String(describing: participantInfo))")
            
            isLoading = false
        } catch {
            errorText = "Failed to prepare chat: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func handleSendFirstMessage() async {
        guard let participantInfo else {
            errorText = "Missing participant Info"
            print(errorText as Any)
            return
        }
        // TODO: Replace with your auth current user details
        guard let user = masterDataManager.user else {
            errorText = "Missing current user/company context."
            print(errorText as Any)
            return
        }

        let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorText = "First Message Is Empty"
            print(errorText as Any)
            return
        }

        do {
            print("Trying to Create First Chat")
            // 3) Create chat document and first message in your backend.
            // Return the chatId so we can navigate.
            let chat = try await createChatAndFirstMessage(
                currentUser: user,
                participant: participantInfo,
                firstMessage: trimmed
            )
            print("Created First Chat: \(chat.id)")
            navigationManager.replaceLast(new: Route.chat(chat: chat, dataService: dataService))
        } catch {
            errorText = "Failed to start chat: \(error.localizedDescription)"
        }
    }

    // MARK: - Backend Stubs (Replace with your Firestore logic)

        
    private func loadParticipantInfo(participantId: String) async throws -> BasicUserInfo {
        // TODO:
        // 1) Try users collection for participantId
        let user = try await dataService.getOneUser(userId: participantId)
        let fullName = user.firstName + " " + user.lastName
        print("[loadParticipantInfo] fullName: \(fullName)")

        return BasicUserInfo(id: UUID().uuidString, userId: participantId, userName: fullName, userImage: user.profileImagePath ?? "")
    }

    private func createChatAndFirstMessage(currentUser: DBUser, participant: BasicUserInfo, firstMessage: String) async throws -> Chat {
        // TODO:
        let chatId = "chat_" + UUID().uuidString
        let currentUserInfo = BasicUserInfo(
            id: UUID().uuidString,
            userId: currentUser.id,
            userName: currentUser.firstName + " " + currentUser.lastName,
            userImage: currentUser.profileImagePath ?? ""
        )
        print("[createChatAndFirstMessage] currentUserInfo: \(currentUserInfo)")
        let chat = Chat(
            id: chatId,
            participantIds: [participant.userId, currentUserInfo.userId],
            participants: [participant,currentUserInfo],
            companyId: "",
            mostRecentChat: Date(),
            userWhoHaveNotRead: [participant.userId],
            lastMessage: firstMessage
        )
        print("[createChatAndFirstMessage] chat: \(chat)")
        
        let message = Message(id: "msg_" + UUID().uuidString, senderName: currentUserInfo.userName, senderId: currentUserInfo.userId, message: firstMessage, read: false, dateSent: Date(), chatId: chatId)
        print("[createChatAndFirstMessage] message: \(message)")

        // 1) Create chat doc with id = chat_<uuid>
        try await dataService.uploadChat(chat: chat)
        
        // 2) Create first message doc with id = msg_<uuid>
        try await dataService.sendMessage(message: message)
        // 3) Write both (batch or sequential), then return chatId
        print("[createChatAndFirstMessage] Success")

        return chat
    }
}
