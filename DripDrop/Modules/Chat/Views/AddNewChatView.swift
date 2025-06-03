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
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if user.id == "" && customer.id == "" {
                    chatTypePicker
                    Spacer()
                } else {
                    chatPreview
                }
            }
        }
        .toolbar{
            ToolbarItem{
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
    var newMessage: some View {
        HStack{
            Button(action: {
                print("Does Nothing")
            }, label: {
                Image(systemName: "plus")
            })
            HStack{
                TextField(
                    "Message",
                    text: $message,
                    axis: .vertical
                )
                
                if message != "" {
                    Button(action: {
                        Task {
                            do {
                                if let user = masterDataManager.user {
                                    if let chat = chatVM.chat {
                                        let fullName = (user.firstName) + " " + (user.lastName)
                                        try await chatVM.sendNewMessage(userId: user.id, senderName: fullName, message: message, chatId: chat.id)
                                        try await chatVM.markChatAsUnRead(userId: user.id, chat: chat)
                                        message = ""
                                    } else {
                                        print("Invalid Selected Chat")
                                    }
                                } else {
                                    print("Invalid User")
                                }
                                    //DEVELOPER ADD Subscriber Rather than having to re grab every time
                                
                            } catch {
                                print("")
                                print("Add New Chat View")
                                print(error)
                                print("")
                                
                            }
                        }
                    }, label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(Color.blue)
                    })
                }
            }
            .padding(5)
            .background(Color.white)
            .foregroundColor(Color.basicFontText)
            .cornerRadius(20)
            .padding(5)
        }
        .padding(10)
        .background(Color.gray.opacity(0.5))
    }
    var chatPreview: some View {
        ZStack{
            if let chat = chatVM.chat {
                VStack{
                    ScrollView(.vertical, showsIndicators: false) {
                        messages2
                    }
                    newMessage
                }
                
            } else {
                VStack{
                    Spacer()
                    newMessage
                }
            }
            VStack{
                HStack{
                    Button(action: {
                        user.id = ""
                        customer.id = ""
                    }, label: {
                        HStack{
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    })
                    .padding()
                    Spacer()
                }
                .background(Color.listColor)
                switch chatType {
                case "Customer":
                    if customer.displayAsCompany {
                        Text("\(customer.company ?? "")")
                    } else {
                        Text("\(customer.firstName) \(customer.lastName)")
                    }
                case "Company":
                    Text("Company")
                default:
                    Text("Default")
                }
                Spacer()
            }
        }
    }
    var chatTypePicker: some View {
        VStack{
            HStack{
                Picker("Type", selection: $chatType) {
                    Text("Company").tag("Company")
                    Text("Customer").tag("Customer")
                }
                .pickerStyle(.segmented)
            }
            switch chatType {
            case "Customer":
                toCustomer
            case "Company":
                toCompany
            default:
                toCustomer
            }
        }
        .padding(8)
    }
    var toCustomer: some View {
        VStack{
            HStack{
                TextField(
                    "search",
                    text: $search
                )
                .modifier(SearchTextFieldModifier())
                .padding(8)
                Picker("Customer", selection: $customer) {
                    ForEach(customerList){ customer in
                        if customer.displayAsCompany {
                            Text("\(customer.company ?? "")").tag(customer)
                        } else {
                            Text("\(customer.firstName) \(customer.lastName)").tag(customer)
                        }
                    }
                    
                }
            }
        }
    }
    var toCompany: some View {
        VStack{
            Text("Company")
            HStack{
                TextField(
                    "search",
                    text: $search
                )
                .modifier(SearchTextFieldModifier())
                .padding(8)
                Picker("User", selection: $user) {
                    ForEach(userList){ user in
                        Text("\(user.firstName) \(user.lastName)").tag(user)
                        
                    }
                    
                }
            }
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
                    if let sender = masterDataManager.user {
                        var participants :[BasicUserInfo] = []
                        var participantIds :[String] = []
                        
                        let fullName = (sender.firstName) + " " + (sender.lastName)
                            //DEVELOPER CHANGE TO BE MORE ACCEPTING OF GROUP CHATS
                        recipientList = [user]
                        if recipientList.count != 0 {
                            participants.append(BasicUserInfo(id: UUID().uuidString, userId: sender.id, userName: fullName, userImage: sender.photoUrl ?? ""))
                            participantIds.append(sender.id)
                            for user in recipientList {
                                participantIds.append(user.id)
                                
                                let userFullName = (user.firstName) + " " + (user.lastName)
                                
                                let participant = BasicUserInfo(id: UUID().uuidString, userId: user.id, userName: userFullName, userImage: user.photoUrl ?? "")
                                participants.append(participant)
                            }
                            try await chatVM.uploadChatandMessageWithValidation(userId: sender.id,
                                                                                senderName: fullName,
                                                                                participantIds: participantIds,
                                                                                participants: participants,
                                                                                companyId: company.id,
                                                                                message: message,
                                                                                mostRecentChat: Date())
                            dismiss()
                        } else {
                            print("Add Error Here Should bot be able to send to no one")
                        }
                    } else {
                        print("No User")
                    }
                } catch {
                    
                }
            }
        }, label: {
            Text("Send")
                .foregroundColor(Color.white)
                .padding(5)
                .background(Color.accentColor)
                .cornerRadius(5)
                .padding(5)
        })
    }
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
}
