//
//  StoreCardView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/21/23.
//

import SwiftUI

struct StoreCardView: View {
    let store: Vender

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "storefront.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 44, height: 44)
                .background(Color.poolBlue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(vendorName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text(vendorAddress.isEmpty ? "No address on file" : vendorAddress)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        vendorPill(store.phoneNumber?.isEmpty == false ? store.phoneNumber! : "No phone", tint: .orange, systemImage: "phone")
                        vendorPill(store.email?.isEmpty == false ? store.email! : "No email", tint: .poolGreen, systemImage: "envelope")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        vendorPill(store.phoneNumber?.isEmpty == false ? store.phoneNumber! : "No phone", tint: .orange, systemImage: "phone")
                        vendorPill(store.email?.isEmpty == false ? store.email! : "No email", tint: .poolGreen, systemImage: "envelope")
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.poolBlue)
                .frame(width: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var vendorName: String {
        let name = store.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Unnamed vendor" : name
    }

    private var vendorAddress: String {
        [
            store.address.streetAddress,
            store.address.city,
            store.address.state,
            store.address.zip
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }

    private func vendorPill(_ text: String, tint: Color, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10), in: Capsule())
    }
}
