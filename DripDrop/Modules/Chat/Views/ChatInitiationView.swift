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
    @State private var participantTargetType: String = "companyUser"
    @State private var participantCustomerId: String? = nil

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            if isLoading {
                ProgressView("Loading message...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header

                        VStack(spacing: 0) {
                            VStack {
                                Text("New message to ")
                                    .foregroundColor(.secondary)
                                    + Text(participantInfo?.userName ?? "New Message")
                                        .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.background)

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
                                            .background(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.poolGreen)
                                            .clipShape(Circle())
                                    }
                                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                            .padding()
                            .background(.background)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )

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
            Text("New Message")
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
            Text(participantInfo?.userName ?? "...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
            participantInfo = try await loadParticipantInfo(participantId: otherParticipantId)

            if let participantInfo, let existingChat = try await findExistingChat(
                currentUserId: user.id,
                participant: participantInfo,
                companyId: masterDataManager.role?.canViewOtherMessages == true
                    ? masterDataManager.currentCompany?.id
                    : nil
            ) {
                print("[findOrCreateChat] existingChat \(existingChat)")
                print("")
                print("[findOrCreateChat] Trying to navigate forward")

//                navigationManager.goBack()
//                navigationManager.push(to: Route.chat(chat: existingChat, dataService: dataService))
//                navigationManager.replaceLast(new: Route.chat(chat: existingChat, dataService: dataService))
                navigationManager.replace(stack: [Route.chat(chat: existingChat, dataService: dataService)])
                return
            }

            print("[findOrCreateChat] participantInfo \(String(describing: participantInfo))")
            
            isLoading = false
        } catch {
            errorText = "Failed to prepare message: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func findExistingChat(currentUserId: String, participant: BasicUserInfo, companyId: String?) async throws -> Chat? {
        if let companyId {
            let chats = try await dataService.getVisibleChats(userId: currentUserId, companyId: companyId)
            return chats.first { chat in
                let hasParticipant = chat.participantIds.contains(participant.userId)
                let hasCustomer = participantCustomerId.map { chat.customerId == $0 } ?? false
                let hasCompany = participant.companyId.map { targetCompanyId in
                    chat.receiverCompanyId == targetCompanyId
                        || chat.companyId == targetCompanyId
                        || chat.participantCompanyIds?.contains(targetCompanyId) == true
                } ?? false
                return hasParticipant || hasCustomer || hasCompany
            }
        }

        return try await dataService.getChatBySenderAndReceiver(senderId: currentUserId, receiverId: participant.userId)
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
        let currentCompany = masterDataManager.currentCompany

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
                currentCompany: currentCompany,
                participant: participantInfo,
                firstMessage: trimmed
            )
            print("Created First Chat: \(chat.id)")
            navigationManager.replaceLast(new: Route.chat(chat: chat, dataService: dataService))
        } catch {
            errorText = "Failed to start message: \(error.localizedDescription)"
        }
    }

    // MARK: - Backend Stubs (Replace with your Firestore logic)

        
    private func loadParticipantInfo(participantId: String) async throws -> BasicUserInfo {
        if let company = masterDataManager.currentCompany {
            if let companyUser = try? await dataService.getCompanyUserById(companyId: company.id, companyUserId: participantId) {
                participantTargetType = "companyUser"
                participantCustomerId = nil
                return companyUserParticipant(companyUser, company: company)
            }

            if let companyUser = try? await dataService.getCompanyUserByDBUserId(companyId: company.id, userId: participantId) {
                participantTargetType = "companyUser"
                participantCustomerId = nil
                return companyUserParticipant(companyUser, company: company)
            }

            if let customer = try? await dataService.getCustomerById(companyId: company.id, customerId: participantId) {
                let customerUserId = linkedCustomerUserId(customer)
                guard !customerUserId.isEmpty else {
                    throw ChatInitiationError.customerNotLinked
                }

                participantTargetType = "customer"
                participantCustomerId = customer.id
                return BasicUserInfo(
                    id: UUID().uuidString,
                    userId: customerUserId,
                    userName: customerDisplayName(customer),
                    userImage: ""
                )
            }
        }

        if let company = try? await dataService.getCompany(companyId: participantId) {
            participantTargetType = "company"
            participantCustomerId = nil
            return BasicUserInfo(
                id: UUID().uuidString,
                userId: company.ownerId,
                userName: company.name,
                userImage: company.photoUrl ?? "",
                companyId: company.id,
                companyName: company.name
            )
        }

        let user = try await dataService.getOneUser(userId: participantId)
        let fullName = user.firstName + " " + user.lastName
        print("[loadParticipantInfo] fullName: \(fullName)")
        participantTargetType = "direct"
        participantCustomerId = nil

        return BasicUserInfo(id: UUID().uuidString, userId: participantId, userName: fullName, userImage: user.profileImagePath ?? "")
    }

    private func companyUserParticipant(_ companyUser: CompanyUser, company: Company) -> BasicUserInfo {
        BasicUserInfo(
            id: UUID().uuidString,
            userId: companyUser.userId,
            userName: companyUser.userName,
            userImage: "",
            companyId: company.id,
            companyName: company.name,
            roleName: companyUser.roleName
        )
    }

    private func linkedCustomerUserId(_ customer: Customer) -> String {
        if let linkedCustomerUserId = customer.linkedCustomerUserId?.trimmingCharacters(in: .whitespacesAndNewlines), !linkedCustomerUserId.isEmpty {
            return linkedCustomerUserId
        }

        if let linkedHomeownerUserId = customer.linkedHomeownerUserId?.trimmingCharacters(in: .whitespacesAndNewlines), !linkedHomeownerUserId.isEmpty {
            return linkedHomeownerUserId
        }

        return customer.linkedCustomerIds?.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func customerDisplayName(_ customer: Customer) -> String {
        if customer.displayAsCompany, let companyName = customer.company, !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return companyName
        }

        let fullName = "\(customer.firstName) \(customer.lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return fullName.isEmpty ? customer.email : fullName
    }

    private func companyScopedParticipantIds(currentCompany: Company?, participant: BasicUserInfo) -> [String]? {
        var ids: [String] = []

        if let currentCompany {
            ids.append(currentCompany.id)
        }

        if let participantCompanyId = participant.companyId,
           !participantCompanyId.isEmpty,
           !ids.contains(participantCompanyId) {
            ids.append(participantCompanyId)
        }

        return ids.isEmpty ? nil : ids
    }

    private func createChatAndFirstMessage(currentUser: DBUser, currentCompany: Company?, participant: BasicUserInfo, firstMessage: String) async throws -> Chat {
        // TODO:
        let chatId = "chat_" + UUID().uuidString
        let isCompanyChat = currentCompany != nil
        let isCustomerChat = participantTargetType == "customer"
        let isCompanyTarget = participantTargetType == "company"
        let companyId = currentCompany?.id ?? (isCompanyTarget ? participant.companyId : nil)
        let companyName = currentCompany?.name ?? (isCompanyTarget ? participant.companyName : nil)
        let receiverCompanyId = isCompanyTarget ? participant.companyId : nil
        let participantCompanyIds = companyScopedParticipantIds(currentCompany: currentCompany, participant: participant)
        let companyIdsWhoHaveNotRead = receiverCompanyId.map { [$0] } ?? []
        let chatVisibility: ChatVisibility
        if isCompanyTarget && currentCompany != nil {
            chatVisibility = .companyToCompany
        } else if isCompanyTarget || isCustomerChat {
            chatVisibility = .companyExternal
        } else if !isCompanyChat {
            chatVisibility = .direct
        } else {
            chatVisibility = .companyInternal
        }
        let currentUserInfo = BasicUserInfo(
            id: UUID().uuidString,
            userId: currentUser.id,
            userName: currentUser.firstName + " " + currentUser.lastName,
            userImage: currentUser.profileImagePath ?? "",
            companyId: currentCompany?.id,
            companyName: currentCompany?.name
        )
        print("[createChatAndFirstMessage] currentUserInfo: \(currentUserInfo)")
        let chat = Chat(
            id: chatId,
            participantIds: [participant.userId, currentUserInfo.userId],
            participants: [participant,currentUserInfo],
            companyId: companyId,
            mostRecentChat: Date(),
            userWhoHaveNotRead: [participant.userId],
            lastMessage: firstMessage,
            visibility: chatVisibility,
            participantCompanyIds: participantCompanyIds,
            companyIdsWhoHaveNotRead: companyIdsWhoHaveNotRead,
            readByUserIds: [currentUser.id],
            title: "\(participant.userName) / \(companyName ?? currentUserInfo.userName)",
            customerId: isCustomerChat ? participantCustomerId : nil,
            companyName: companyName,
            senderCompanyId: currentCompany?.id,
            receiverCompanyId: receiverCompanyId,
            customerUserId: isCustomerChat ? participant.userId : nil,
            customerName: isCustomerChat ? participant.userName : nil,
            audience: (isCustomerChat || isCompanyTarget) ? "external" : (isCompanyChat ? "internal" : "direct"),
            targetType: isCustomerChat ? "customer" : (isCompanyTarget ? "company" : (isCompanyChat ? "companyUser" : "user")),
            companyVisibility: isCustomerChat || (isCompanyTarget && currentCompany == nil) ? "public" : nil,
            publicToCompanyId: isCustomerChat ? currentCompany?.id : (isCompanyTarget && currentCompany == nil ? participant.companyId : nil),
            lastMessageKind: .text
        )
        print("[createChatAndFirstMessage] chat: \(chat)")
        
        let message = Message(id: "msg_" + UUID().uuidString, senderName: currentUserInfo.userName, senderId: currentUserInfo.userId, message: firstMessage, read: false, dateSent: Date(), chatId: chatId, senderCompanyId: currentCompany?.id, senderCompanyName: currentCompany?.name)
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

private enum ChatInitiationError: LocalizedError {
    case customerNotLinked

    var errorDescription: String? {
        switch self {
        case .customerNotLinked:
            return "This customer is not linked to a homeowner account yet."
        }
    }
}
