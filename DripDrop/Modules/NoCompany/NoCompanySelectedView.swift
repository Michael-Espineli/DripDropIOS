//
//  NoCompanySelectedView.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//

    //
//  NoCompanySelectedView.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//

import SwiftUI

struct NoCompanySelectedView: View {
    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: NoCompanySelectedViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject private var VM : NoCompanySelectedViewModel
    // In React this came from useContext(Context). Here we model it as a simple input.
    var name: String = "User"

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                        // Header
                    VStack(spacing: 8) {
                        if let user = masterDataManager.user {
                            Text("Welcome, \(user.firstName) \(user.lastName)!")
                                .font(.headline)
                                .bold()
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                            
                        }
                        Text("What would you like to do today?")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    
                        // Main Action Cards
                    AdaptiveGrid(columns: 3, spacing: 16) {
                        ActionCard(
                            destination: Route.browseCompanies(dataService:dataService),
                            icon: Image(systemName: "briefcase"),
                            iconColor: .blue,
                            title: "Find a Company",
                            description: "View pending invites or browse companies to join.",
                            buttonText: "Browse Companies",
                            buttonColor: .blue
                        )
                        
                            //                    ActionCard(
                            //                        destination: Route.browseCompanies(dataService:dataService),
                            //                        icon: Image(systemName: "doc.text"),
                            //                        iconColor: .purple,
                            //                        title: "Job Postings",
                            //                        description: "Browse and apply for job openings.",
                            //                        buttonText: "Find a Job",
                            //                        buttonColor: .purple
                            //                    )
                        ActionCard(
                            destination: Route.createCompanyView(dataService:dataService),
                            icon: Image(systemName: "building.2"),
                            iconColor: .green,
                            title: "Start Your Own",
                            description: "Create a company and start managing your business.",
                            buttonText: "Create Company",
                            buttonColor: .green
                        )
                    }
                    .padding(.top, 4)
                    
                        // Lower Section
                    AdaptiveGrid(columns: 3, spacing: 16) {
                            // Recent messages (2 columns wide on large screens)
                        VStack(spacing: 12) {
                            RecentChatsWidgetPlaceholder(chats: VM.chats)
                        }
                        .gridCellColumns(2)
                        
                            // Invites (1 column)
                        InvitesWidgetPlaceholder(invites: VM.invites)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.listColor.ignoresSafeArea())
        .task{
            await VM.onLoad(user: masterDataManager.user)
        }
    }
}

// MARK: - Reusable Action Card
struct ActionCard: View {
    var destination: Route
    var icon: Image
    var iconColor: Color
    var title: String
    var description: String
    var buttonText: String
    var buttonColor: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 64, height: 64)
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(iconColor)
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
            NavigationLink(value: destination, label: {
                Text(buttonText)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(buttonColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
            })
            NavigationLink(destination: destination) {
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: Color.darkGray.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Adaptive Grid Helper
struct AdaptiveGrid<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        // Uses adaptive columns to mimic 1/2/3 column behavior
        let gridItems = [GridItem(.adaptive(minimum: 260), spacing: spacing)]
        LazyVGrid(columns: gridItems, spacing: spacing) {
            content
        }
    }
}

// MARK: - Placeholders for widgets and destinations
struct RecentChatsWidgetPlaceholder: View {
    @EnvironmentObject var dataService : ProductionDataService

    let chats:[Chat]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right")
                    .foregroundStyle(.blue)
                Text("Recent Messages")
                    .font(.headline)
                Spacer()
                NavigationLink(value: Route.chats(dataService: dataService), label: {
                    Text("See All")
                        .modifier(RedLinkModifier())
                })
            }
            ForEach(chats) { idx in
                NavigationLink(value: Route.chat(chat: idx, dataService: dataService), label: {
                    ChatCardViewSmall(dataService: dataService, chat: idx)
                })
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: Color.darkGray.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

struct InvitesWidgetPlaceholder: View {
    @EnvironmentObject var dataService : ProductionDataService

    var invites: [Invite]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "envelope.open")
                    .foregroundStyle(.green)
                Text("Invites")
                    .font(.headline)
                Spacer()
                NavigationLink(value: Route.techInviteList(dataService: dataService), label: {
                    Text("See All")
                        .modifier(RedLinkModifier())
                })
            }
            ForEach(invites) { idx in
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(idx.companyName)").font(.subheadline).bold()
                        HStack{
                            Text(idx.displayStatus)
                            Text("Tap to view details").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    NavigationLink(value: Route.inviteDetailView(dataService: dataService, invite: idx ), label: {
                        Text("View")
                    })
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: Color.darkGray.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

// Destination placeholders to satisfy NavigationLinks
struct JobPostingsView: View { var body: some View { Text("Job Postings").padding() } }

#Preview {
    NoCompanySelectedView(dataService: MockDataService())
}
