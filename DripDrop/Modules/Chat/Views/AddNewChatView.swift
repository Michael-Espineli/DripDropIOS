    //
    //  AddNewChatView.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 1/8/24.
    //

import SwiftUI

struct AddNewChatView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var chatVM : ChatViewModel
    @StateObject private var customerVM : CustomerViewModel
    @StateObject private var techVM = TechViewModel()
    
    init(dataService:any ProductionDataServiceProtocol,receivedCustomer:Customer?){
        _chatVM = StateObject(wrappedValue: ChatViewModel(dataService: dataService))
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _receivedCustomer = State(wrappedValue: receivedCustomer)
        
    }
    @State var receivedCustomer:Customer?
    @State var chatType:String = "Customer"
    @State var message:String = ""
    @State var search:String = ""
    @State var userList:[DBUser] = []
    @State var recipientList:[DBUser] = []
    
    @State var user:DBUser = DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0, recentlySelectedCompany: "")
    @State var customerList:[Customer] = []
    @State var customer:Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        active: true,
        displayAsCompany: true,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
    
    @State private var scrollPosition: Int? = 0
    @State var scrollToBottom:Bool = true
    @State var messagesToGet:Int = 25
    
    private var trimmedMessage:String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedCustomerUserId:String? {
        if let linkedCustomerUserId = customer.linkedCustomerUserId?.trimmingCharacters(in: .whitespacesAndNewlines), !linkedCustomerUserId.isEmpty {
            return linkedCustomerUserId
        }
        if let linkedHomeownerUserId = customer.linkedHomeownerUserId?.trimmingCharacters(in: .whitespacesAndNewlines), !linkedHomeownerUserId.isEmpty {
            return linkedHomeownerUserId
        }
        return customer.linkedCustomerIds?.first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedCustomerName:String {
        if customer.displayAsCompany, let company = customer.company, !company.isEmpty {
            return company
        }
        let fullName = "\(customer.firstName) \(customer.lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return fullName.isEmpty ? customer.email : fullName
    }

    private var selectedCompanyUserName:String {
        "\(user.firstName) \(user.lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSendChat:Bool {
        guard !trimmedMessage.isEmpty else { return false }
        if chatType == "Customer" {
            guard let selectedCustomerUserId else { return false }
            return customer.id != "" && !selectedCustomerUserId.isEmpty
        }
        return user.id != ""
    }
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack(spacing: 0) {
                if user.id == "" && customer.id == "" {
                    composeHeader
                    chatTypePicker
                    Spacer()
                } else {
                    chatPreview
                }
            }
        }
        .navigationTitle("New Message")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar{
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                button
            }
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await techVM.getAllCompanyTechs(companyId: company.id)
                    userList = techVM.techList
                    try await customerVM.filterAndSortSelected(companyId: company.id, filter: .active, sort: .firstNameHigh)
                    customerList = customerVM.customers
                    if let receivedCustomer {
                        customer = receivedCustomer
                    }
                }
            } catch {
                print("Error")
            }
        }
        .onChange(of: user.id, perform: { receiver in
            Task{
                print("")
                print("Change of User ID")
                if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                    if receiver != "" {
                        do {
                            print("Getting Chat By Sender And Receiver")
                            try await chatVM.getChatBySenderAndReceiver(companyId: company.id, senderId: user.id, receiverId: receiver)
                        } catch {
                            print(error)
                        }
                        if let chat = chatVM.chat {
                            do {
                                chatVM.addListenerForAllMessages(chatId: chat.id,amount: messagesToGet)
                                
                                if let user = masterDataManager.user {
                                    if chat.userWhoHaveNotRead.contains(where: {$0 == user.id}) {
                                        try await chatVM.markChatAsRead(userId: user.id, chat: chat)
                                    }
                                }
                            } catch {
                                print("Error Getting Messages")
                            }
                        }
                    }
                }
            }
        })
    }
}
extension AddNewChatView {
    var composeHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "square.and.pencil")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 48, height: 48)
                    .background(Color.poolBlue.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("New Message")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Choose a recipient and write the first message.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    var newMessage: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField(
                    "Message",
                    text: $message,
                    axis: .vertical
                )
                .submitLabel(.send)
                
                Button(action: {
                    Task {
                        await sendMessageToExistingThread()
                    }
                }, label: {
                    Image(systemName: "arrow.up")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(trimmedMessage.isEmpty ? Color.secondary : Color.white)
                        .frame(width: 30, height: 30)
                        .background(trimmedMessage.isEmpty ? Color.primary.opacity(0.08) : Color.poolGreen, in: Circle())
                })
                .buttonStyle(.plain)
                .disabled(trimmedMessage.isEmpty || chatVM.chat == nil)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
    var chatPreview: some View {
        VStack(spacing: 0) {
            selectedRecipientHeader

            if chatVM.chat != nil {
                messages2
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Spacer()
            }

            newMessage
        }
    }

    var selectedRecipientHeader: some View {
        HStack(spacing: 12) {
            Button(action: {
                user.id = ""
                customer.id = ""
            }, label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 38, height: 38)
                    .background(Color.poolBlue.opacity(0.13), in: Circle())
            })
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 3) {
                Text(selectedRecipientTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(chatVM.chat == nil ? "Ready to start a message." : "Message thread")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(.regularMaterial)
    }
    var chatTypePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Type", selection: $chatType) {
                Text("Company").tag("Company")
                Text("Customer").tag("Customer")
            }
            .pickerStyle(.segmented)

            switch chatType {
            case "Customer":
                toCustomer
            case "Company":
                toCompany
            default:
                toCustomer
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
    }
    var toCustomer: some View {
        VStack(alignment: .leading, spacing: 10) {
            recipientSearchField(placeholder: "Search customers")

            Picker("Customer", selection: $customer) {
                ForEach(filteredCustomerList){ customer in
                    if customer.displayAsCompany {
                        Text("\(customer.company ?? "")").tag(customer)
                    } else {
                        Text("\(customer.firstName) \(customer.lastName)").tag(customer)
                    }
                }
            }
            .pickerStyle(.menu)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
    var toCompany: some View {
        VStack(alignment: .leading, spacing: 10) {
            recipientSearchField(placeholder: "Search company users")

            Picker("User", selection: $user) {
                ForEach(filteredUserList){ user in
                    Text("\(user.firstName) \(user.lastName)").tag(user)
                }
            }
            .pickerStyle(.menu)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
    var button: some View {
        Button(action: {
            Task{
                do {
                    guard let company = masterDataManager.currentCompany else {
                        print("No Company")
                        return
                    }
                    guard canSendChat else {
                        print("Select a recipient and enter a message.")
                        return
                    }
                    if let sender = masterDataManager.user {
                        let isCustomerChat = chatType == "Customer"
                        let senderName = "\(sender.firstName) \(sender.lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
                        let recipientUserId = isCustomerChat ? selectedCustomerUserId ?? "" : user.id
                        let recipientName = isCustomerChat ? selectedCustomerName : selectedCompanyUserName
                        let senderParticipant = BasicUserInfo(
                            id: UUID().uuidString,
                            userId: sender.id,
                            userName: senderName,
                            userImage: sender.photoUrl ?? "",
                            companyId: company.id,
                            companyName: company.name
                        )
                        let recipientParticipant = BasicUserInfo(
                            id: UUID().uuidString,
                            userId: recipientUserId,
                            userName: recipientName,
                            userImage: isCustomerChat ? "" : (user.photoUrl ?? ""),
                            companyId: isCustomerChat ? nil : company.id,
                            companyName: isCustomerChat ? nil : company.name
                        )

                        try await chatVM.uploadChatandMessageWithValidation(
                            userId: sender.id,
                            senderName: senderName,
                            participantIds: [sender.id, recipientUserId],
                            participants: [senderParticipant, recipientParticipant],
                            companyId: company.id,
                            message: trimmedMessage,
                            mostRecentChat: Date(),
                            visibility: isCustomerChat ? .companyExternal : .companyInternal,
                            audience: isCustomerChat ? "external" : "internal",
                            targetType: isCustomerChat ? "customer" : "companyUser",
                            title: "\(recipientName) / \(company.name)",
                            customerId: isCustomerChat ? customer.id : nil,
                            customerUserId: isCustomerChat ? recipientUserId : nil,
                            customerName: isCustomerChat ? recipientName : nil,
                            companyVisibility: isCustomerChat ? "public" : nil,
                            publicToCompanyId: isCustomerChat ? company.id : nil
                        )
                        dismiss()
                    } else {
                        print("No User")
                    }
                } catch {
                    
                }
            }
        }, label: {
            Text("Send")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(canSendChat ? Color.poolBlue : Color.secondary)
        })
        .disabled(!canSendChat)
    }

    private func recipientSearchField(placeholder: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $search)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            if !search.isEmpty {
                Button(action: { search = "" }) {
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

    private var filteredCustomerList: [Customer] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else { return customerList }

        return customerList.filter { customer in
            [
                customer.firstName,
                customer.lastName,
                customer.company ?? "",
                customer.email
            ]
            .contains { $0.lowercased().contains(term) }
        }
    }

    private var filteredUserList: [DBUser] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else { return userList }

        return userList.filter { user in
            [
                user.firstName,
                user.lastName,
                user.email
            ]
            .contains { $0.lowercased().contains(term) }
        }
    }

    private var selectedRecipientTitle: String {
        switch chatType {
        case "Customer":
            return selectedCustomerName
        case "Company":
            return selectedCompanyUserName.isEmpty ? "Company User" : selectedCompanyUserName
        default:
            return "Message"
        }
    }

    private func sendMessageToExistingThread() async {
        do {
            guard !trimmedMessage.isEmpty else { return }
            guard let currentUser = masterDataManager.user else {
                print("Invalid User")
                return
            }
            guard let chat = chatVM.chat else {
                print("Invalid Selected Message Thread")
                return
            }

            let fullName = (currentUser.firstName) + " " + (currentUser.lastName)
            try await chatVM.sendNewMessage(
                userId: currentUser.id,
                senderName: fullName,
                senderCompanyId: masterDataManager.currentCompany?.id,
                senderCompanyName: masterDataManager.currentCompany?.name,
                message: trimmedMessage,
                chatId: chat.id
            )
            try await chatVM.markChatAsUnRead(userId: currentUser.id, chat: chat)
            message = ""
        } catch {
            print("")
            print("Add New Message View")
            print(error)
            print("")
        }
    }

    var messages2: some View {
        ScrollViewReader { scrollView in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    if let user = masterDataManager.user {
                        
                        ForEach(chatVM.listOfMessages) { item in
                            VStack{
                                HStack{
                                    if item.senderId == user.id {
                                        Spacer()
                                        Text("\(item.message)")
                                            .messagePreviewBubble(isCurrentUser: true)
                                    } else {
                                        
                                        Text("\(item.message)")
                                            .messagePreviewBubble(isCurrentUser: false)
                                        
                                        Spacer()
                                    }
                                    
                                }
                                if item.senderId == user.id {
                                    
                                    HStack(spacing: 6){
                                        Spacer()
                                        Text("\(item.senderName)")
                                        Text("\(fullDateAndTime(date:item.dateSent))")
                                    }
                                } else {
                                    HStack(spacing: 6){
                                        Text("\(item.senderName)")
                                        Text("\(fullDateAndTime(date:item.dateSent))")
                                        Spacer()
                                    }
                                    
                                }
                                
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 2)
                            .id(item)
                            .flippedUpsideDown()
                            
                            if item == chatVM.listOfMessages.last{
                                if chatVM.listOfMessages.count == messagesToGet {
                                    
                                    HStack{
                                        ProgressView()
                                    }
                                    .onAppear{
                                        let placeHolder = messagesToGet
                                        messagesToGet = messagesToGet + 10
                                        print("Messages to get \(messagesToGet)")
                                        print("Loading More Messages")
                                        
                                        if let chat = masterDataManager.selectedChat {
                                            chatVM.removeListenerForMessages()
                                            chatVM.addListenerForAllMessages(chatId: chat.id, amount: messagesToGet)
                                        }
                                        scrollView.scrollTo(chatVM.listOfMessages[placeHolder - 1],anchor: .bottomTrailing)
                                    }
                                    .flippedUpsideDown()
                                } else {
                                    Button(action: {
                                        if let message = previewScrollAnchorMessage {
                                            scrollView.scrollTo(message,anchor: .bottomTrailing)
                                        }
                                        
                                    }, label: {
                                        VStack(spacing: 4){
                                            Text("No More Messages")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                    })
                                    .flippedUpsideDown()
                                }
                            }
                        }
                    }
                }
            }
            .flippedUpsideDown()
            
            .onChange(of: chatVM.listOfMessages, perform: { list in
                if list.count > 3 {
                    if let message = previewScrollAnchorMessage {
                        scrollView.scrollTo(message,anchor: .bottomTrailing)
                    }
                }
            })
        }
    }

    private var previewScrollAnchorMessage: Message? {
        guard !chatVM.listOfMessages.isEmpty else { return nil }
        let anchorIndex = chatVM.listOfMessages.index(after: chatVM.listOfMessages.startIndex)
        if chatVM.listOfMessages.indices.contains(anchorIndex) {
            return chatVM.listOfMessages[anchorIndex]
        }
        return chatVM.listOfMessages.first
    }
}

private extension Text {
    func messagePreviewBubble(isCurrentUser: Bool) -> some View {
        self
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isCurrentUser ? Color.poolBlue : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(isCurrentUser ? Color.white : Color.primary)
            .frame(maxWidth: 300, alignment: isCurrentUser ? .trailing : .leading)
    }
}
