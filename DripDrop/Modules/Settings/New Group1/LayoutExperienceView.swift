//
//  LayoutExperienceView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct LayoutExperienceView: View {
    @Binding var selectedLayoutExperience: LayoutExperienceSetting?

    private var columns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 138), spacing: 10)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Layout Configuration", systemImage: "rectangle.grid.2x2")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(LayoutExperienceSetting.allCases) { item in
                    Button {
                        withAnimation(.snappy) {
                            selectedLayoutExperience = item
                        }
                    } label: {
                        LayoutExperienceSelectionView(
                            selectedItem: $selectedLayoutExperience,
                            item: item
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

struct LayoutExperienceSelectionView: View {
    @State private var isHovering = false
    @Binding var selectedItem: LayoutExperienceSetting?

    let item: LayoutExperienceSetting

    private var isSelected: Bool {
        selectedItem == item
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: item.imageName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : Color.accentColor)
                    .frame(width: 34, height: 34)
                    .background(iconBackground, in: Circle())

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.78) : .secondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(12)
        .background(background)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        }
        .scaleEffect(isHovering ? 1.015 : 1)
        .onHover { hovering in
            withAnimation(.snappy) {
                isHovering = hovering
            }
        }
    }

    private var iconBackground: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(.white.opacity(0.2))
        }

        return AnyShapeStyle(Color.accentColor.opacity(0.12))
    }

    private var background: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor)
        }

        return AnyShapeStyle(.background.opacity(0.48))
    }

    private var borderColor: Color {
        if isSelected || isHovering {
            return Color.accentColor.opacity(0.45)
        }

        return Color.primary.opacity(0.08)
    }
}

struct LayoutExperienceView_Previews: PreviewProvider {
    static var previews: some View {
        LayoutExperienceView(selectedLayoutExperience: .constant(.twoColumn))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
