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
                if chat.userWhoHaveNotRead.contains(where: {$0 == user.id}) {
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
                        
                        AsyncImage(url: URL(string: person.userImage)!){ image in
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
                    }
                    .frame(width: 75,height: 75)
                    .shadow(color: Color.white, radius: 2)
                } else {
                    Circle()
                        .fill(Color.poolGreen)
                        .frame(width: 75, height: 75)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(Color.white)
                        )
                }
            }
            VStack{
                VStack{
                    HStack{
                        ForEach(chat.participants){ participant in
                            if let user = masterDataManager.user {
                                if user.id != participant.userId {
                                    
                                    Text(participant.userName)
                                    Image(systemName: "building.columns.fill")
                                }
                            } else {
                                Text("Invalid User")
                            }
                        }
                        Spacer()
                        Text(shortDate(date:chatVM.newestMessage?.dateSent))
                            .font(.footnote)
                        Image(systemName: "chevron.right")
                            .font(.footnote)

                    }
                    .font(.headline)
                    .lineLimit(1)
                    Text(chatVM.newestMessage?.message ?? "")
                        .lineLimit(2, reservesSpace: true)
                        .font(.footnote)


                }
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
