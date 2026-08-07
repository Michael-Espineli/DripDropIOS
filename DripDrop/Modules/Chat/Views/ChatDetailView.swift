//
//  ChatDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI

struct ChatDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject private var chatVM : ChatViewModel
    @State var chat:Chat
    init(dataService:any ProductionDataServiceProtocol,chat:Chat){
        _chatVM = StateObject(wrappedValue: ChatViewModel(dataService: dataService))
        _chat = State(wrappedValue: chat)
    }
    @State var messageList:[Message] = []
    @State var message:String = ""
    
    @State private var scrollPosition: Int? = 0
    @State var scrollToBottom:Bool = true
    @State var messagesToGet:Int = 25
    @State var participant:String = ""
    @State private var showLinkComposer: Bool = false
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            VStack(spacing: 0) {
                messages2
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                newMessage
            }
        }
        .navigationTitle(participant.isEmpty ? "Messages" : participant)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
          
                chatVM.addListenerForAllMessages(chatId: chat.id,amount: messagesToGet)
                
                if let user = masterDataManager.user {
                    participant = chat.displayTitle(currentUserId: user.id)
                    if chat.isUnread(for: user.id, companyId: masterDataManager.currentCompany?.id) {
                        try await chatVM.markChatAsRead(userId: user.id, companyId: masterDataManager.currentCompany?.id, chat: chat)
                    }
                }
            } catch {
                print("Error Getting Messages")
            }
        }
        .onChange(of: masterDataManager.selectedID, perform: { datum in
            if let chatId = datum {
                chatVM.removeListenerForMessages()
                chatVM.addListenerForAllMessages(chatId: chatId, amount: messagesToGet)
            }
        })
        .onDisappear(perform: {
            chatVM.removeListenerForMessages()
        })
        
    }
    
}
extension ChatDetailView {
    var messages2: some View {
        ScrollViewReader { scrollView in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    if let user = masterDataManager.user {

                        if chatVM.listOfMessages.isEmpty {
                            emptyThreadState
                                .padding(.horizontal, 14)
                                .padding(.top, 14)
                                .flippedUpsideDown()
                        }

                        ForEach(chatVM.listOfMessages) { item in
                            VStack{
                                HStack{
                                    if item.senderId == user.id {
                                        Spacer()
                                        ChatMessageContent(message: item, isCurrentUser: true)
                                    } else {
                                        
                                        ChatMessageContent(message: item, isCurrentUser: false)
                                        
                                        Spacer()
                                    }
                                    
                                }
                                if item.senderId == user.id {
                                    
                                    HStack(spacing: 6){
                                        Spacer()
                                        Text("\(item.senderName)")
                                        Text("\(fullTime(date:item.dateSent))")
                                    }
                                } else {
                                    HStack(spacing: 6){
                                        Text("\(item.senderName)")
                                        Text("\(fullTime(date:item.dateSent))")
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
                                            if let message = scrollAnchorMessage {
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
                        if let message = scrollAnchorMessage {
                            scrollView.scrollTo(message,anchor: .bottomTrailing)
                        }
                    }
                })
        }
    }
    var messages: some View {
        VStack{
            ScrollViewReader { scrollViewProxy in
                ScrollView{
                    VStack {
                        if let user = masterDataManager.user {
                            
                            ForEach(chatVM.listOfMessages) { i in
                                VStack{
                                    HStack{
                                        if i.senderId == user.id {
                                            Spacer()
                                            ChatMessageContent(message: i, isCurrentUser: true)
                                        } else {
                                            
                                            ChatMessageContent(message: i, isCurrentUser: false)
                                            
                                            Spacer()
                                        }
                                        
                                    }
                                    if i.senderId == user.id {
                                        
                                        HStack{
                                            Spacer()
                                            Text("\(i.senderName)")
                                                .font(.footnote)
                                            Text("\(fullTime(date:i.dateSent))")
                                                .font(.footnote)
                                        }
                                    } else {
                                        HStack{
                                            Text("\(i.senderName)")
                                                .font(.footnote)
                                            Text("\(fullTime(date:i.dateSent))")
                                                .font(.footnote)
                                            Spacer()
                                        }
                                    }
                                }
                                //                                .flippedUpsideDown()
                            }
                        }
                    }
                    //                    .flippedUpsideDown()
                    .onChange(of: chatVM.listOfMessages.count) { count in
                        print("Count From ScrollViewProxy \(count)")
                        scrollViewProxy.scrollTo(chatVM.listOfMessages.last, anchor: .bottom)
                    }
                }
            }
        }
    }
    var newMessage: some View {
        HStack(spacing: 10) {
            Button(action: {
                showLinkComposer = true
            }, label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 38, height: 38)
                    .background(Color.poolBlue.opacity(0.13), in: Circle())
            })
            .buttonStyle(.plain)
            .accessibilityLabel("Attach record")
            .sheet(isPresented: $showLinkComposer) {
                ShareConversationLinkSheet { link, note in
                    Task {
                        await sendLink(link, note: note)
                    }
                }
            }

            HStack(spacing: 8) {
                TextField(
                    "Message",
                    text: $message,
                    axis: .vertical
                )
                .foregroundStyle(.primary)
                .submitLabel(.send)
                .onSubmit {
                    Task {
                        await sendCurrentMessage()
                    }
                }

                Button(action: {
                    Task {
                        await sendCurrentMessage()
                    }
                }, label: {
                    Image(systemName: "arrow.up")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(trimmedMessage.isEmpty ? Color.secondary : Color.white)
                        .frame(width: 30, height: 30)
                        .background(trimmedMessage.isEmpty ? Color.primary.opacity(0.08) : Color.poolGreen, in: Circle())
                })
                .buttonStyle(.plain)
                .disabled(trimmedMessage.isEmpty)
                .accessibilityLabel("Send Message")
            }
            .textFieldStyle(PlainTextFieldStyle())
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var emptyThreadState: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: "bubble.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("No messages yet.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Send the first message in this thread.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var scrollAnchorMessage: Message? {
        guard !chatVM.listOfMessages.isEmpty else { return nil }
        let anchorIndex = chatVM.listOfMessages.index(after: chatVM.listOfMessages.startIndex)
        if chatVM.listOfMessages.indices.contains(anchorIndex) {
            return chatVM.listOfMessages[anchorIndex]
        }
        return chatVM.listOfMessages.first
    }

    private func sendCurrentMessage() async {
        do {
            guard !trimmedMessage.isEmpty else { return }
            guard let user = masterDataManager.user else {
                print("Invalid User")
                return
            }

            let fullName = (user.firstName) + " " + (user.lastName)
            try await chatVM.sendNewMessage(
                userId: user.id,
                senderName: fullName,
                senderCompanyId: masterDataManager.currentCompany?.id,
                senderCompanyName: masterDataManager.currentCompany?.name,
                message: trimmedMessage,
                chatId: chat.id
            )
            message = ""
        } catch {
            print("[ChatDetailView][sendCurrentMessage] \(error)")
        }
    }
    
    private func sendLink(_ link: ConversationLink, note: String) async {
        do {
            guard let user = masterDataManager.user else {
                print("Invalid User")
                return
            }
            let fullName = (user.firstName) + " " + (user.lastName)
            try await chatVM.sendLinkedRecordMessage(
                userId: user.id,
                senderName: fullName,
                senderCompanyId: masterDataManager.currentCompany?.id,
                senderCompanyName: masterDataManager.currentCompany?.name,
                chatId: chat.id,
                note: note,
                link: link
            )
        } catch {
            print("[ChatDetailView][sendLink] \(error)")
        }
    }
}

private struct ChatMessageContent: View {
    let message: Message
    let isCurrentUser: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !message.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(message.message)
                    .font(.subheadline)
            }

            ForEach(message.messageLinks) { link in
                ConversationLinkCard(link: link)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(messageBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isCurrentUser ? Color.clear : Color.primary.opacity(0.07), lineWidth: 1)
        )
        .foregroundStyle(isCurrentUser ? Color.white : Color.primary)
        .frame(maxWidth: 300, alignment: isCurrentUser ? .trailing : .leading)
    }

    private var messageBackground: Color {
        isCurrentUser ? Color.poolBlue : Color(.secondarySystemBackground)
    }
}

private struct ConversationLinkCard: View {
    let link: ConversationLink

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: link.type.systemImage)
                .font(.caption.weight(.semibold))
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(link.type.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .opacity(0.78)
                Text(link.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if let subtitle = link.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .opacity(0.9)
                }
                HStack(spacing: 8) {
                    if let status = link.status, !status.isEmpty {
                        Text(status)
                            .font(.caption2)
                    }
                    if let amountLabel = link.amountLabel, !amountLabel.isEmpty {
                        Text(amountLabel)
                            .font(.caption2)
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .opacity(0.8)
        }
        .padding(9)
        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ShareConversationLinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @State private var type: ConversationLinkType = .serviceStop
    @State private var title: String = ""
    @State private var recordId: String = ""
    @State private var subtitle: String = ""
    @State private var status: String = ""
    @State private var amountLabel: String = ""
    @State private var note: String = ""

    let onSend: (ConversationLink, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $type) {
                    ForEach(ConversationLinkType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.systemImage)
                            .tag(type)
                    }
                }

                TextField("Title", text: $title)
                TextField("Record ID", text: $recordId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                TextField("Subtitle", text: $subtitle)
                TextField("Status", text: $status)
                TextField("Amount", text: $amountLabel)
                TextField("Note", text: $note, axis: .vertical)
            }
            .navigationTitle("Share to Message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedRecordId = recordId.trimmingCharacters(in: .whitespacesAndNewlines)
                        let resolvedRecordId = trimmedRecordId.isEmpty ? UUID().uuidString : trimmedRecordId
                        let companyId = masterDataManager.currentCompany?.id
                        let accountType = masterDataManager.user?.accountType?.lowercased() ?? ""
                        let audience = accountType.contains("home") || accountType.contains("client") ? "client" : "company"
                        let link = ConversationLink(
                            id: UUID().uuidString,
                            type: type,
                            recordId: resolvedRecordId,
                            title: trimmedTitle.isEmpty ? type.displayName : trimmedTitle,
                            subtitle: subtitle.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                            companyId: companyId,
                            status: status.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                            amountLabel: amountLabel.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                            mobileRoute: type.mobileRouteString,
                            audience: audience
                        )
                        onSend(link, note.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
