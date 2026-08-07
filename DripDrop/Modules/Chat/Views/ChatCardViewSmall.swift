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
        HStack(alignment: .top, spacing: 11) {
            avatar

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(chat.displayTitle(currentUserId: masterDataManager.user?.id))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text(messageDate)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(messagePreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)

                HStack(spacing: 6) {
                    if isUnread {
                        messageChip(
                            title: "Unread",
                            systemImage: "circle.fill",
                            tint: .orange
                        )
                    }

                    messageChip(
                        title: visibilityLabel,
                        systemImage: visibilitySystemImage,
                        tint: visibilityTint
                    )

                    if hasLinkedRecord {
                        messageChip(
                            title: "Linked",
                            systemImage: "link",
                            tint: .poolBlue
                        )
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary.opacity(0.55))
                .padding(.top, 5)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isUnread ? Color.orange.opacity(0.35) : Color.primary.opacity(0.07), lineWidth: 1)
        }
        .task {
            do {
                try await chatVM.getNewestMessage(chatId: chat.id)
            } catch {
                print("Unable to get Most Recent Message")
                print(error)
            }
        }
    }

    private var isUnread: Bool {
        guard let user = masterDataManager.user else { return false }
        return chat.isUnread(for: user.id, companyId: masterDataManager.currentCompany?.id)
    }

    private var otherParticipant: BasicUserInfo? {
        guard let currentUserId = masterDataManager.user?.id else {
            return chat.participants.first
        }

        return chat.participants.first(where: { $0.userId != currentUserId }) ?? chat.participants.first
    }

    private var messagePreview: String {
        chatVM.newestMessage?.previewText ?? chat.lastMessage
    }

    private var messageDate: String {
        shortDate(date: chatVM.newestMessage?.dateSent ?? chat.mostRecentChat)
    }

    private var hasLinkedRecord: Bool {
        chat.contextLinks?.isEmpty == false || chat.lastConversationLink != nil || chatVM.newestMessage?.messageLinks.isEmpty == false
    }

    private var visibilityLabel: String {
        switch chat.visibility ?? .direct {
        case .companyInternal:
            return "Internal"
        case .companyExternal, .customer:
            return "Customer"
        case .company, .companyToCompany:
            return "Company"
        case .direct:
            return "Direct"
        }
    }

    private var visibilitySystemImage: String {
        switch chat.visibility ?? .direct {
        case .company, .companyInternal, .companyToCompany:
            return "building.2.fill"
        case .companyExternal, .customer:
            return "person.2.fill"
        case .direct:
            return "person.fill"
        }
    }

    private var visibilityTint: Color {
        switch chat.visibility ?? .direct {
        case .companyInternal, .company, .companyToCompany:
            return .poolGreen
        case .companyExternal, .customer:
            return .orange
        case .direct:
            return .secondary
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(avatarTint.opacity(0.13))

            if let url = participantImageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    avatarFallback
                }
            } else {
                avatarFallback
            }
        }
        .frame(width: 42, height: 42)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(isUnread ? Color.orange.opacity(0.55) : Color.primary.opacity(0.06), lineWidth: isUnread ? 2 : 1)
        }
    }

    private var avatarFallback: some View {
        Text(participantInitials)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(avatarTint)
    }

    private var participantImageURL: URL? {
        guard let image = otherParticipant?.userImage.trimmingCharacters(in: .whitespacesAndNewlines),
              !image.isEmpty else {
            return nil
        }

        return URL(string: image)
    }

    private var participantInitials: String {
        let name = otherParticipant?.userName ?? chat.displayTitle(currentUserId: masterDataManager.user?.id)
        let initials = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()

        return initials.isEmpty ? "M" : initials.uppercased()
    }

    private var avatarTint: Color {
        isUnread ? .orange : .poolBlue
    }

    private func messageChip(title: String, systemImage: String, tint: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: Capsule())
            .lineLimit(1)
    }
}
