//
//  AdminDashboardView.swift
//  DripDropAdmin
//

import SwiftUI

enum AdminPalette {
    static let background = Color(red: 15 / 255, green: 23 / 255, blue: 42 / 255)
    static let sidebar = Color(red: 2 / 255, green: 6 / 255, blue: 23 / 255)
    static let card = Color(red: 15 / 255, green: 23 / 255, blue: 42 / 255)
    static let cardRaised = Color(red: 17 / 255, green: 24 / 255, blue: 39 / 255)
    static let border = Color(red: 30 / 255, green: 41 / 255, blue: 59 / 255)
    static let gold = Color(red: 239 / 255, green: 177 / 255, blue: 47 / 255)
    static let text = Color(red: 248 / 255, green: 250 / 255, blue: 252 / 255)
    static let mutedText = Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255)
    static let blue = Color(red: 147 / 255, green: 197 / 255, blue: 253 / 255)
    static let green = Color(red: 134 / 255, green: 239 / 255, blue: 172 / 255)
    static let red = Color(red: 252 / 255, green: 165 / 255, blue: 165 / 255)
}

struct AdminDashboardView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager

    @State private var selectedSection: AdminSection = .dashboard

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width >= 760 {
                HStack(spacing: 0) {
                    AdminSidebar(selectedSection: $selectedSection)
                        .frame(width: 276)
                    content
                }
            } else {
                NavigationStack {
                    content
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Menu {
                                    ForEach(AdminSection.allCases) { section in
                                        Button(section.title) {
                                            selectedSection = section
                                        }
                                    }
                                    Divider()
                                    Button("Sign Out", role: .destructive) {
                                        signOut()
                                    }
                                } label: {
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundStyle(AdminPalette.gold)
                                }
                            }
                        }
                }
            }
        }
        .background(AdminPalette.background)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                summaryGrid
                developmentGrid
                communicationGrid
                quickActions
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: 1180, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AdminPalette.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedSection.title)
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(AdminPalette.gold)

                    Text(masterDataManager.currentCompany?.name ?? "System admin workspace")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AdminPalette.mutedText)
                }

                Spacer()

                if let user = masterDataManager.user {
                    AdminUserBadge(user: user)
                }
            }
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: adaptiveColumns(minimum: 180), spacing: 14) {
            AdminMetricCard(
                title: "Companies",
                value: "--",
                caption: "Signed up",
                systemImage: "building.2",
                accent: AdminPalette.gold
            )
            AdminMetricCard(
                title: "Active",
                value: "--",
                caption: "Companies",
                systemImage: "checkmark.seal",
                accent: AdminPalette.green
            )
            AdminMetricCard(
                title: "Unverified",
                value: "--",
                caption: "Review queue",
                systemImage: "exclamationmark.triangle",
                accent: AdminPalette.gold
            )
            AdminMetricCard(
                title: "Subscriptions",
                value: "--",
                caption: "Plans",
                systemImage: "creditcard",
                accent: AdminPalette.blue
            )
        }
    }

    private var developmentGrid: some View {
        AdminSectionPanel(title: "Development") {
            LazyVGrid(columns: adaptiveColumns(minimum: 210), spacing: 12) {
                AdminNavCard(title: "Universal Equipment", subtitle: "Equipment models and types", systemImage: "wrench.and.screwdriver", accent: AdminPalette.gold)
                AdminNavCard(title: "Feature Flags", subtitle: "Launch controls", systemImage: "flag", accent: AdminPalette.blue)
                AdminNavCard(title: "Product Feedback", subtitle: "Bugs and feature requests", systemImage: "bubble.left.and.exclamationmark.bubble.right", accent: AdminPalette.green)
                AdminNavCard(title: "Errors", subtitle: "Captured app errors", systemImage: "exclamationmark.octagon", accent: AdminPalette.red)
            }
        }
    }

    private var communicationGrid: some View {
        AdminSectionPanel(title: "Management") {
            LazyVGrid(columns: adaptiveColumns(minimum: 210), spacing: 12) {
                AdminNavCard(title: "Companies", subtitle: "Company records", systemImage: "building.2.crop.circle", accent: AdminPalette.gold)
                AdminNavCard(title: "Users", subtitle: "System users", systemImage: "person.2", accent: AdminPalette.blue)
                AdminNavCard(title: "Homeowners", subtitle: "Homeowner accounts", systemImage: "house", accent: AdminPalette.green)
                AdminNavCard(title: "Live Chat", subtitle: "Admin conversations", systemImage: "message", accent: AdminPalette.gold)
            }
        }
    }

    private var quickActions: some View {
        AdminSectionPanel(title: "Quick Actions") {
            HStack(spacing: 12) {
                Button {
                    selectedSection = .billingCalculator
                } label: {
                    Label("Billing Calculator", systemImage: "function")
                }
                .buttonStyle(AdminPrimaryButtonStyle())

                Button {
                    selectedSection = .subscriptions
                } label: {
                    Label("Manage Subscriptions", systemImage: "creditcard")
                }
                .buttonStyle(AdminSecondaryButtonStyle())

                Spacer(minLength: 0)
            }
        }
    }

    private func adaptiveColumns(minimum: CGFloat) -> [GridItem] {
        [GridItem(.adaptive(minimum: minimum), spacing: 14)]
    }

    private func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
            masterDataManager.showSignInView = true
            masterDataManager.user = nil
            masterDataManager.currentCompany = nil
            masterDataManager.companyUser = nil
        } catch {
            print("[AdminDashboardView][signOut] \(error)")
        }
    }
}

private struct AdminSidebar: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @Binding var selectedSection: AdminSection

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Drip Drop")
                    .font(.title2.weight(.black))
                    .foregroundStyle(AdminPalette.gold)
                Text("[Admin]")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AdminPalette.text.opacity(0.78))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 26)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AdminPalette.border.opacity(0.7))
                    .frame(height: 1)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AdminSidebarGroup(title: nil, sections: [.dashboard], selectedSection: $selectedSection)
                    AdminSidebarGroup(title: "Development", sections: [.universalEquipment, .readingsDosages, .featureFlags, .productFeedback, .errors, .documentation], selectedSection: $selectedSection)
                    AdminSidebarGroup(title: "Management", sections: [.companies, .users, .homeowners, .subscriptions, .billingCalculator, .poolProspects, .liveChat, .reachOutMessages], selectedSection: $selectedSection)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 18)
            }

            Button {
                do {
                    try AuthenticationManager.shared.signOut()
                    masterDataManager.showSignInView = true
                    masterDataManager.user = nil
                    masterDataManager.currentCompany = nil
                    masterDataManager.companyUser = nil
                } catch {
                    print("[AdminSidebar][signOut] \(error)")
                }
            } label: {
                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(AdminLogoutButtonStyle())
            .padding(16)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AdminPalette.border.opacity(0.7))
                    .frame(height: 1)
            }
        }
        .background(AdminPalette.sidebar)
    }
}

private struct AdminSidebarGroup: View {
    let title: String?
    let sections: [AdminSection]
    @Binding var selectedSection: AdminSection

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(AdminPalette.mutedText)
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
            }

            ForEach(sections) { section in
                Button {
                    selectedSection = section
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: section.systemImage)
                            .frame(width: 22)
                        Text(section.title)
                            .font(.subheadline.weight(.semibold))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(selectedSection == section ? AdminPalette.gold : AdminPalette.text.opacity(0.82))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selectedSection == section ? AdminPalette.cardRaised : Color.clear)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(selectedSection == section ? AdminPalette.gold.opacity(0.3) : Color.clear, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct AdminMetricCard: View {
    let title: String
    let value: String
    let caption: String
    let systemImage: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AdminPalette.mutedText)
                Text(value)
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(accent)
                Text(caption)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AdminPalette.mutedText.opacity(0.85))
            }
            Spacer(minLength: 0)
            Image(systemName: systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(accent)
                .frame(width: 42, height: 42)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(accent.opacity(0.22), lineWidth: 1)
                }
        }
        .padding(16)
        .frame(minHeight: 132, alignment: .top)
        .background(AdminPalette.sidebar, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AdminPalette.border.opacity(0.7), lineWidth: 1)
        }
    }
}

private struct AdminSectionPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.black))
                .foregroundStyle(AdminPalette.gold)
            content
        }
        .padding(16)
        .background(AdminPalette.sidebar, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AdminPalette.border.opacity(0.7), lineWidth: 1)
        }
    }
}

private struct AdminNavCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(accent)
                .frame(width: 38, height: 38)
                .background(AdminPalette.sidebar, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AdminPalette.border.opacity(0.8), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AdminPalette.text)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AdminPalette.mutedText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AdminPalette.card.opacity(0.68), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AdminPalette.border.opacity(0.65), lineWidth: 1)
        }
    }
}

private struct AdminUserBadge: View {
    let user: DBUser

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(AdminPalette.gold)
            VStack(alignment: .trailing, spacing: 2) {
                Text(user.firstName.isEmpty ? "Admin" : user.firstName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AdminPalette.text)
                Text(user.email)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AdminPalette.mutedText)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AdminPalette.sidebar, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AdminPalette.border.opacity(0.7), lineWidth: 1)
        }
    }
}

private struct AdminPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AdminPalette.sidebar)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(AdminPalette.gold.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AdminSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AdminPalette.gold)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(AdminPalette.gold.opacity(configuration.isPressed ? 0.18 : 0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AdminPalette.gold.opacity(0.3), lineWidth: 1)
            }
    }
}

private struct AdminLogoutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AdminPalette.red)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AdminPalette.red.opacity(configuration.isPressed ? 0.18 : 0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

enum AdminSection: String, CaseIterable, Identifiable {
    case dashboard
    case universalEquipment
    case readingsDosages
    case featureFlags
    case productFeedback
    case errors
    case documentation
    case companies
    case users
    case homeowners
    case subscriptions
    case billingCalculator
    case poolProspects
    case liveChat
    case reachOutMessages

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Admin Dashboard"
        case .universalEquipment: return "Universal Equipment"
        case .readingsDosages: return "Readings & Dosages"
        case .featureFlags: return "Feature Flags"
        case .productFeedback: return "Product Feedback"
        case .errors: return "Errors"
        case .documentation: return "Documentation"
        case .companies: return "Companies"
        case .users: return "Users"
        case .homeowners: return "Homeowners"
        case .subscriptions: return "Subscriptions"
        case .billingCalculator: return "Billing Calculator"
        case .poolProspects: return "Pool Prospects"
        case .liveChat: return "Live Chat"
        case .reachOutMessages: return "Reach Out Messages"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.100percent"
        case .universalEquipment: return "wrench.and.screwdriver"
        case .readingsDosages: return "list.clipboard"
        case .featureFlags: return "flag"
        case .productFeedback: return "bubble.left.and.exclamationmark.bubble.right"
        case .errors: return "exclamationmark.triangle"
        case .documentation: return "doc.text"
        case .companies: return "building.2"
        case .users: return "person.2"
        case .homeowners: return "house"
        case .subscriptions: return "creditcard"
        case .billingCalculator: return "function"
        case .poolProspects: return "water.waves"
        case .liveChat: return "message"
        case .reachOutMessages: return "envelope.badge"
        }
    }
}
