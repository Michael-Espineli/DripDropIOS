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
        VStack{
            ScrollView(.vertical, showsIndicators: false) {
                messages2
                
            }
            newMessage
        }
        .navigationTitle(participant)
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
            ScrollView{
                LazyVStack{
                    if let user = masterDataManager.user {
                        
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
                                    
                                    HStack{
                                        Spacer()
                                        Text("\(item.senderName)")
                                            .font(.footnote)
                                        Text("\(fullTime(date:item.dateSent))")
                                            .font(.footnote)
                                    }
                                } else {
                                    HStack{
                                        Text("\(item.senderName)")
                                            .font(.footnote)
                                        Text("\(fullTime(date:item.dateSent))")
                                            .font(.footnote)
                                        Spacer()
                                    }
                                    
                                }
                                
                            }
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
                                        print("Loading New Chats")
                                        
                                        if let chat = masterDataManager.selectedChat {
                                            chatVM.removeListenerForMessages()
                                            chatVM.addListenerForAllMessages(chatId: chat.id, amount: messagesToGet)
                                        }
                                        scrollView.scrollTo(chatVM.listOfMessages[placeHolder - 1],anchor: .bottomTrailing)
                                    }
                                    } else {
                                        Button(action: {
                                            scrollView.scrollTo(chatVM.listOfMessages[chatVM.listOfMessages.startIndex + 1],anchor: .bottomTrailing)

                                        }, label: {
                                            VStack{
                                                Text("No More Messages")
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
                        scrollView.scrollTo(chatVM.listOfMessages[chatVM.listOfMessages.startIndex + 1],anchor: .bottomTrailing)
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
        HStack{
            Button(action: {
                showLinkComposer = true
            }, label: {
                Image(systemName: "plus")
                    .font(.headline)
            })
            .sheet(isPresented: $showLinkComposer) {
                ShareConversationLinkSheet { link, note in
                    Task {
                        await sendLink(link, note: note)
                    }
                }
            }
            HStack{
                TextField(
                    "Message",
                    text: $message,
                    axis: .vertical
                )
                .foregroundColor(Color.black)
                .background(Color.white)
                .onSubmit {
                    Task {
                        do {
                            if message == "" {
                                return
                            }
                            if let user = masterDataManager.user {
                                let fullName = (user.firstName) + " " + (user.lastName)
                                    try await chatVM.sendNewMessage(userId: user.id, senderName: fullName, senderCompanyId: masterDataManager.currentCompany?.id, senderCompanyName: masterDataManager.currentCompany?.name, message: message, chatId: chat.id)
                                    try await chatVM.markChatAsUnRead(userId: user.id, chat: chat)
                                    message = ""
                          
                            } else {
                                print("Invalid User")
                            }
                            //DEVELOPER ADD Subscriber Rather than having to re grab every time
                            
                        } catch {
                            print("[ChatDetailView][onSubmit] \(error)")
                        }
                    }
                }
            if message != "" {
                Button(action: {
                    Task {
                        do {
                            if let user = masterDataManager.user {
                                let fullName = (user.firstName) + " " + (user.lastName)
                                    try await chatVM.sendNewMessage(userId: user.id, senderName: fullName, senderCompanyId: masterDataManager.currentCompany?.id, senderCompanyName: masterDataManager.currentCompany?.name, message: message, chatId: chat.id)
                                    try await chatVM.markChatAsUnRead(userId: user.id, chat: chat)
                                    message = ""
                          
                            } else {
                                print("Invalid User")
                            }
                            //DEVELOPER ADD Subscriber Rather than having to re grab every time
                            
                        } catch {
                            print("[ChatDetailView][buttonPress] \(error)")
                        }
                    }
                }, label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Color.blue)
                        .font(.headline)
                })
            }
            }
            .textFieldStyle(PlainTextFieldStyle())
            .font(.headline)
            .padding(8)
            .background(Color.white)
            .cornerRadius(20)
            .foregroundColor(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
        }
        .padding(8)
        .background(Color.gray.opacity(0.5))
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
            try await chatVM.markChatAsUnRead(userId: user.id, chat: chat)
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
            }

            ForEach(message.attachments ?? []) { link in
                ConversationLinkCard(link: link)
            }
        }
        .padding(8)
        .background(isCurrentUser ? Color.blue : Color.gray)
        .foregroundColor(Color.white)
        .cornerRadius(8)
        .padding(5)
        .frame(maxWidth: 280, alignment: isCurrentUser ? .trailing : .leading)
    }
}

private struct ConversationLinkCard: View {
    let link: ConversationLink

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: link.type.systemImage)
                .font(.headline)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(link.type.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .opacity(0.85)
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
        .padding(8)
        .background(Color.white.opacity(0.18))
        .cornerRadius(8)
    }
}

private struct ShareConversationLinkSheet: View {
    @Environment(\.dismiss) private var dismiss
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
            .navigationTitle("Share")
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
                        let link = ConversationLink(
                            id: UUID().uuidString,
                            type: type,
                            recordId: trimmedRecordId.isEmpty ? UUID().uuidString : trimmedRecordId,
                            title: trimmedTitle.isEmpty ? type.displayName : trimmedTitle,
                            subtitle: subtitle.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                            status: status.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                            amountLabel: amountLabel.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
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
