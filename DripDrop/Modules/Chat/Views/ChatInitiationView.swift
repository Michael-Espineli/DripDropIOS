//
//  ParticipantInfo.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/28/26.
//


import SwiftUI

struct ParticipantInfo {
    let id: String
    let name: String
    let imageURL: String?
    let type: ParticipantType

    enum ParticipantType {
        case user
        case company
    }
}

struct ChatInitiationView: View {
    // Inputs
    let participantId: String
    // Provide a navigation callback so this view stays generic
    let onNavigateToChat: (String) -> Void
    let onBack: () -> Void

    // Environment dependencies you can swap to your own managers
    @EnvironmentObject var masterDataManager: MasterDataManager
    // If you have an Auth manager, inject it here as well
    // @EnvironmentObject var authManager: AuthManager

    // UI State
    @State private var newMessage: String = ""
    @State private var participantInfo: ParticipantInfo?
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
                                    + Text(participantInfo?.name ?? "New Chat")
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
            Button {
                onBack()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }

            Text("New Message to \(participantInfo?.name ?? "...")")
                .font(.largeTitle).bold()
                .foregroundColor(.primary)
        }
    }

    // MARK: - Flow

    private func findOrCreateChat() async {
        // TODO: Replace with your auth current user id
        // For example, from an AuthManager or FirebaseAuth: currentUserId
        guard let currentCompanyId = masterDataManager.currentCompany?.id else {
            // If you’re using user auth, swap to your user id
            errorText = "Missing current user/company context."
            isLoading = false
            return
        }

        do {
            // 1) Check if chat exists between current and participant (both orders).
            // TODO: Query your backend (Firestore) for an existing chat where
            // participantIds == [currentCompanyId, participantId] or [participantId, currentCompanyId]
            if let existingChatId = try await findExistingChatId(currentId: currentCompanyId, participantId: participantId) {
                onNavigateToChat(existingChatId)
                return
            }

            // 2) Load participant info (user or company)
            participantInfo = try await loadParticipantInfo(participantId: participantId)

            isLoading = false
        } catch {
            errorText = "Failed to prepare chat: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func handleSendFirstMessage() async {
        guard let participantInfo else { return }
        // TODO: Replace with your auth current user details
        guard let currentCompany = masterDataManager.currentCompany else {
            errorText = "Missing current user/company context."
            return
        }

        let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            // 3) Create chat document and first message in your backend.
            // Return the chatId so we can navigate.
            let chatId = try await createChatAndFirstMessage(
                currentCompany: currentCompany,
                participant: participantInfo,
                firstMessage: trimmed
            )
            onNavigateToChat(chatId)
        } catch {
            errorText = "Failed to start chat: \(error.localizedDescription)"
        }
    }

    // MARK: - Backend Stubs (Replace with your Firestore logic)

    private func findExistingChatId(currentId: String, participantId: String) async throws -> String? {
        // TODO: Firestore query:
        // chats where participantIds in [[currentId, participantId], [participantId, currentId]]
        // If found, return the first chat id
        return nil
    }

    private func loadParticipantInfo(participantId: String) async throws -> ParticipantInfo {
        // TODO:
        // 1) Try users collection for participantId
        // 2) If not exists, try companies collection for participantId
        // 3) If found, return ParticipantInfo; else throw an error
        // For now, return a placeholder:
        return ParticipantInfo(id: participantId, name: "Participant", imageURL: nil, type: .company)
    }

    private func createChatAndFirstMessage(currentCompany: Company, participant: ParticipantInfo, firstMessage: String) async throws -> String {
        // TODO:
        // 1) Create chat doc with id = chat_<uuid>
        // 2) Create first message doc with id = msg_<uuid>
        // 3) Write both (batch or sequential), then return chatId
        return "chat_placeholder_id"
    }
}