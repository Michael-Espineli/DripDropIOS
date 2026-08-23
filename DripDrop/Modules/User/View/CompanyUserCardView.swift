//
//  CompanyUserCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import SwiftUI

struct CompanyUserCardView: View {
    let companyUser: CompanyUser

    init(dataService: any ProductionDataServiceProtocol, companyUser: CompanyUser) {
        self.companyUser = companyUser
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(initials)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(statusTint, in: Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(companyUser.userName.isEmpty ? "Unknown User" : companyUser.userName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text(companyUser.roleName.isEmpty ? "No role assigned" : companyUser.roleName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        userPill(companyUser.status.rawValue, tint: statusTint, systemImage: "checkmark.seal")
                        userPill(companyUser.workerType.rawValue.isEmpty ? "Not assigned" : companyUser.workerType.rawValue, tint: .poolBlue, systemImage: "person.text.rectangle")
                        userPill(vehicleLabel, tint: .orange, systemImage: "car")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            userPill(companyUser.status.rawValue, tint: statusTint, systemImage: "checkmark.seal")
                            userPill(companyUser.workerType.rawValue.isEmpty ? "Not assigned" : companyUser.workerType.rawValue, tint: .poolBlue, systemImage: "person.text.rectangle")
                        }
                        userPill(vehicleLabel, tint: .orange, systemImage: "car")
                    }
                }

                HStack(spacing: 10) {
                    if companyUser.workerType == .contractor, let linkedCompanyName = companyUser.linkedCompanyName, !linkedCompanyName.isEmpty {
                        Label(linkedCompanyName, systemImage: "building.2")
                            .lineLimit(1)
                    }

                    Label(shortDate(date: companyUser.dateCreated), systemImage: "calendar")
                        .lineLimit(1)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(statusTint)
                .frame(width: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var initials: String {
        let pieces = companyUser.userName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }

        let value = String(pieces).uppercased()
        return value.isEmpty ? "U" : value
    }

    private var statusTint: Color {
        switch companyUser.status {
        case .active:
            return .poolGreen
        case .pending:
            return .orange
        case .past:
            return .secondary
        }
    }

    private var vehicleLabel: String {
        switch companyUser.normalizedRouteVehicleAccess {
        case "personal":
            return "Personal"
        case "both":
            return "Company or personal"
        default:
            return "Company"
        }
    }

    private func userPill(_ text: String, tint: Color, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10), in: Capsule())
    }
}
