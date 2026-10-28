import SwiftUI

// Both dashboard perspectives use the same cards and type hierarchy.
extension View {
    func mobileMainCard(material: Bool = false) -> some View {
        self
            .padding(16)
            .background(
                material ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
    }
}

struct MobileDashboardSectionHeading: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var route: Route? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if let route {
                NavigationLink(value: route) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open \(title)")
            }
        }
    }
}

struct MobileDashboardSnapshotMetric: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.headline.weight(.bold)).foregroundStyle(tint)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct MobileDashboardSummaryMetric: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    var route: Route? = nil

    var body: some View {
        if let route {
            NavigationLink(value: route) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold)).foregroundStyle(tint)
                Spacer(minLength: 0)
                if route != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
                }
            }
            Text(value).font(.headline.weight(.bold)).foregroundStyle(.primary)
            Text(title).font(.caption2.weight(.medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct MobileDashboardQuickActionLabel: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        }
    }
}
