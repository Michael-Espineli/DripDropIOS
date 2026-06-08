//
//  InviteDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/12/23.
//

import SwiftUI

struct InviteDetailView: View {
    init(dataService: any ProductionDataServiceProtocol, invite: Invite) {
        _VM = StateObject(wrappedValue: InviteDetailViewModel(dataService: dataService))
        self._invite = .init(initialValue: invite)
    }

    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject private var VM: InviteDetailViewModel
    @State private var invite: Invite

    private var displayInvite: Invite {
        VM.updatedInvite ?? invite
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    companyCard
                    inviteCard
                    reviewsCard

                    if InviteStatusValue.isPending(displayInvite.status) {
                        actionCard
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Invite Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await VM.onLoad(invite: invite)
        }
        .alert(VM.alertMessage, isPresented: Binding(
            get: { VM.showAlert },
            set: { isPresented in
                if !isPresented {
                    VM.dismissAlert()
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        }
    }
}

private extension InviteDetailView {
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                    Image(systemName: "envelope.open.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 6) {
                    Text(displayInvite.companyName.isEmpty ? "Company Invitation" : displayInvite.companyName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Invited as \(displayInvite.roleName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    statusPill(displayInvite.status)
                }

                Spacer()
            }

            Divider()

            HStack(spacing: 10) {
                statTile(title: "Worker Type", value: displayInvite.workerType.rawValue, systemImage: "person.badge.key")
                statTile(title: "Invitee", value: inviteeName, systemImage: "person.crop.circle")
            }
        }
        .cardStyle()
    }

    var companyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Company Public Information", systemImage: "building.2")

            if VM.isLoadingCompany {
                ProgressView("Loading company details...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let company = VM.company {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.gray.opacity(0.12))
                        if let photoUrl = company.photoUrl, let url = URL(string: photoUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    Image(systemName: "building.2.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(company.name)
                            .font(.headline)
                        Text(company.ownerName.isEmpty ? "Owner not listed" : company.ownerName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if !company.verified {
                            Text("Public profile")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        } else {
                            Label("Verified", systemImage: "checkmark.seal.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                    }
                    Spacer()
                }

                detailRow("Email", company.email, systemImage: "envelope")
                detailRow("Phone", company.phoneNumber, systemImage: "phone")

                if !company.websiteURL.isEmpty, let url = URL(string: safeExternalURL(company.websiteURL)) {
                    Link(destination: url) {
                        Label("Website", systemImage: "globe")
                            .font(.subheadline.weight(.semibold))
                    }
                }

                if !company.services.isEmpty {
                    chipSection(title: "Services", values: company.services)
                }

                if !company.serviceZipCodes.isEmpty {
                    chipSection(title: "Service Area", values: company.serviceZipCodes)
                }
            } else {
                Text("Company public information could not be loaded.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    var inviteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Invite Information", systemImage: "info.circle")
            detailRow("First Name", displayInvite.firstName, systemImage: "person")
            detailRow("Last Name", displayInvite.lastName, systemImage: "person")
            detailRow("Email", displayInvite.email, systemImage: "envelope")
            detailRow("Role", displayInvite.roleName, systemImage: "key")
            detailRow("Company ID", displayInvite.companyId, systemImage: "number")

            #if os(iOS)
            Button {
                UIPasteboard.general.string = displayInvite.id
            } label: {
                Label("Copy Invite ID", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            #endif
        }
        .cardStyle()
    }

    var reviewsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Reviews", systemImage: "star")
                Spacer()
                if let averageRating {
                    Text("\(averageRating, specifier: "%.1f") / 5")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if VM.reviews.isEmpty {
                Text("No public reviews yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(VM.reviews.prefix(3)) { review in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(review.reviewerName)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 3) {
                            ForEach(0..<5, id: \.self) { index in
                                Image(systemName: index < Int(round(review.rating)) ? "star.fill" : "star")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                            }
                            if review.verified {
                                Text("Verified")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.green)
                                    .padding(.leading, 4)
                            }
                        }
                        if !review.description.isEmpty {
                            Text(review.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .cardStyle()
    }

    var actionCard: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await VM.acceptInvite(user: masterDataManager.user, invite: displayInvite)
                }
            } label: {
                Label(VM.isUpdatingInvite ? "Accepting Invite" : "Accept Invite", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(VM.isUpdatingInvite)

            Button(role: .destructive) {
                Task {
                    await VM.rejectInvite(user: masterDataManager.user, invite: displayInvite)
                }
            } label: {
                Label(VM.isUpdatingInvite ? "Rejecting Invite" : "Reject Invite", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(VM.isUpdatingInvite)
        }
        .cardStyle()
    }

    var inviteeName: String {
        let name = "\(displayInvite.firstName) \(displayInvite.lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? displayInvite.email : name
    }

    var averageRating: Double? {
        let ratings = VM.reviews.map(\.rating).filter { $0 > 0 }
        guard !ratings.isEmpty else { return nil }
        return ratings.reduce(0, +) / Double(ratings.count)
    }

    func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    func statusPill(_ status: String) -> some View {
        Text(InviteStatusValue.display(status))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(statusColor(status).opacity(0.14), in: Capsule())
            .foregroundStyle(statusColor(status))
    }

    func statusColor(_ status: String) -> Color {
        switch InviteStatusValue.normalized(status) {
        case InviteStatusValue.accepted.rawValue:
            return .green
        case InviteStatusValue.rejected.rawValue:
            return .red
        default:
            return .orange
        }
    }

    func statTile(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "Not provided" : value)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func detailRow(_ label: String, _ value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "Not provided" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }
            Spacer()
        }
    }

    func chipSection(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(values, id: \.self) { value in
                    Text(value)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.1), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    func safeExternalURL(_ value: String) -> String {
        if value.lowercased().hasPrefix("http://") || value.lowercased().hasPrefix("https://") {
            return value
        }
        return "https://\(value)"
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.gray.opacity(0.14), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}
