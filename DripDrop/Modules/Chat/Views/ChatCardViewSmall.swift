//
//  ChatCardViewSmall.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI

struct ChatCardViewSmall: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject private var chatVM : ChatViewModel

    init(dataService:any ProductionDataServiceProtocol,chat:Chat){
        _chatVM = StateObject(wrappedValue: ChatViewModel(dataService: dataService))
        _chat = State(wrappedValue: chat)
    }
    @State var chat:Chat
    var body: some View {
        HStack{
            if let user = masterDataManager.user {
                if chat.isUnread(for: user.id, companyId: masterDataManager.currentCompany?.id) {
                    Image(systemName: "circle")
                        .foregroundColor(Color.red)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(Color.clear)
                }
                
                if let person = chat.participants.first(where: {$0.userId != user.id }) {
                    ZStack{
                        Circle()
                            .stroke(Color.lightBlue, lineWidth:4)
                        if let url = URL(string: person.userImage){
                            AsyncImage(url: url){ image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName:"photo.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(Color.white)
                            }
                            .clipShape(Circle())
                            
                        } else {
                            Image(systemName:"photo.circle")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.white)
                                .clipShape(Circle())
                        }
                    }
                    .frame(width: 50,height: 50)
                    .shadow(color: Color.white, radius: 2)
                } else {
                    Circle()
                        .fill(Color.poolGreen)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(Color.white)
                        )
                }
            }
            VStack(alignment: .leading){
                HStack{
                    Text(chat.displayTitle(currentUserId: masterDataManager.user?.id))
                    if chat.visibility == .company || chat.visibility == .companyToCompany {
                        Image(systemName: "building.2.fill")
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                }
                .font(.headline)
                .lineLimit(1)
                Text(shortDate(date:chatVM.newestMessage?.dateSent))
                    .font(.footnote)
                Text(chatVM.newestMessage?.previewText ?? chat.lastMessage)
                    .lineLimit(2, reservesSpace: true)
                    .font(.footnote)
            }
            
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
        .task {
            do {
                try await chatVM.getNewestMessage(chatId: chat.id)
            } catch {
                print("Unable to get Most Recent Message")
                print(error)
            }
        }
    }
}
