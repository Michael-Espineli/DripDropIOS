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
                    var particiapntName:String = ""
                    for participant in chat.participants {
                        if participant.userId != user.id {
                            particiapntName = particiapntName + " " + participant.userName
                        }
                    }
                    participant = particiapntName
                    if chat.userWhoHaveNotRead.contains(where: {$0 == user.id}) {
                        try await chatVM.markChatAsRead(userId: user.id, chat: chat)
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
                                        Text("\(item.message)")
                                            .padding(5)
                                            .background(.blue)
                                            .foregroundColor(Color.white)
                                            .cornerRadius(5)
                                            .padding(5)
                                    } else {
                                        
                                        Text("\(item.message)")
                                            .padding(5)
                                            .background(.gray)
                                            .foregroundColor(Color.white)
                                            .cornerRadius(5)
                                            .padding(5)
                                        
                                        Spacer()
                                    }
                                    
                                }
                                if item.senderId == user.id {
                                    
                                    HStack{
                                        Spacer()
                                        Text("\(item.senderName)")
                                            .font(.footnote)
                                        Text("\(fullDateAndTime(date:item.dateSent))")
                                            .font(.footnote)
                                    }
                                } else {
                                    HStack{
                                        Text("\(item.senderName)")
                                            .font(.footnote)
                                        Text("\(fullDateAndTime(date:item.dateSent))")
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
Text("Return to bottom")
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
                                            Text("\(i.message)")
                                                .padding(5)
                                                .background(.blue)
                                                .foregroundColor(Color.white)
                                                .cornerRadius(5)
                                                .padding(5)
                                        } else {
                                            
                                            Text("\(i.message)")
                                                .padding(5)
                                                .background(.gray)
                                                .foregroundColor(Color.white)
                                                .cornerRadius(5)
                                                .padding(5)
                                            
                                            Spacer()
                                        }
                                        
                                    }
                                    if i.senderId == user.id {
                                        
                                        HStack{
                                            Spacer()
                                            Text("\(i.senderName)")
                                                .font(.footnote)
                                            Text("\(fullDateAndTime(date:i.dateSent))")
                                                .font(.footnote)
                                        }
                                    } else {
                                        HStack{
                                            Text("\(i.senderName)")
                                                .font(.footnote)
                                            Text("\(fullDateAndTime(date:i.dateSent))")
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
                print("Does Nothing")
            }, label: {
                Image(systemName: "plus")
                    .font(.headline)
            })
            HStack{
                TextField(
                    "Message",
                    text: $message,
                    axis: .vertical
                )
                .foregroundColor(Color.black)
            if message != "" {
                Button(action: {
                    Task {
                        do {
                            if let user = masterDataManager.user {
                                    let fullName = (user.firstName ?? "") + " " + (user.lastName ?? "")
                                    try await chatVM.sendNewMessage(userId: user.id, senderName: fullName, message: message, chatId: chat.id)
                                    try await chatVM.markChatAsUnRead(userId: user.id, chat: chat)
                                    message = ""
                          
                            } else {
                                print("Invalid User")
                            }
                            //DEVELOPER ADD Subscriber Rather than having to re grab every time
                            
                        } catch {
                            
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
}
