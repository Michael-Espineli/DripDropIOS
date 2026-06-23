//
//  SettingsView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//

import SwiftUI

struct SettingsView: View {
    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @EnvironmentObject var masterDataManager: MasterDataManager
    private let dataService: any ProductionDataServiceProtocol

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard

                    UserSettings(dataService: dataService, isEmbedded: true)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension SettingsView {
    var headerCard: some View {
        HStack(alignment: .center, spacing: 14) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(companyName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    var avatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.accentColor.opacity(0.14))
                .frame(width: 56, height: 56)

            Text(initials)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .accessibilityHidden(true)
    }

    var displayName: String {
        guard let user = masterDataManager.user else {
            return "Settings"
        }

        let name = "\(user.firstName) \(user.lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? user.email : name
    }

    var companyName: String {
        if let company = masterDataManager.currentCompany {
            return company.name
        }

        return "Tech Hub"
    }

    var initials: String {
        guard let user = masterDataManager.user else {
            return "DD"
        }

        let first = user.firstName.first.map(String.init) ?? ""
        let last = user.lastName.first.map(String.init) ?? ""
        let combined = "\(first)\(last)"

        if combined.isEmpty {
            return user.email.first.map { String($0).uppercased() } ?? "DD"
        }

        return combined.uppercased()
    }
}
