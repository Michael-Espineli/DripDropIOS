//
//  ButtonViewModifiers.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/26/23.
//

import Foundation
import SwiftUI

// Shared with the web workspace palette: Jobs controls + Profile headers.
enum WorkspaceTone: String, CaseIterable {
    case blue, emerald, amber, rose, slate, cyan, violet

    static func jobStatusTone(_ value: String) -> WorkspaceTone {
        let status = value.filter { $0.isLetter || $0.isNumber }.lowercased()
        if ["draft", "unscheduled", "rejected", "unspecified"].contains(status) { return .rose }
        if ["estimate", "estimatepending", "inprogress"].contains(status) { return .amber }
        if ["accepted", "scheduled", "finished", "paid", "comped", "customerresolved", "completed", "complete"].contains(status) { return .emerald }
        if ["invoiced", "sent", "open"].contains(status) { return .blue }
        if ["waitingforparts", "blocked"].contains(status) { return .violet }
        return .slate
    }

    private var colors: (light: (UInt32, UInt32, UInt32), dark: (UInt32, UInt32, UInt32)) {
        switch self {
        case .blue: return ((0xeff6ff, 0xbfdbfe, 0x1d4ed8), (0x203c58, 0x476b97, 0xbfdbfe))
        case .emerald: return ((0xecfdf5, 0xa7f3d0, 0x047857), (0x163f38, 0x3f7667, 0xa7f3d0))
        case .amber: return ((0xfffbeb, 0xfde68a, 0x92400e), (0x46391f, 0x8a7040, 0xfde68a))
        case .rose: return ((0xfff1f2, 0xfecdd3, 0xbe123c), (0x452831, 0x875264, 0xfecdd3))
        case .slate: return ((0xf8fafc, 0xcbd5e1, 0x334155), (0x374757, 0x708397, 0xe2e8f0))
        case .cyan: return ((0xecfeff, 0xa5f3fc, 0x0e7490), (0x163d48, 0x427b88, 0xa5f3fc))
        case .violet: return ((0xf5f3ff, 0xddd6fe, 0x6d28d9), (0x352e50, 0x75659a, 0xddd6fe))
        }
    }
    private func color(_ hex: UInt32) -> Color {
        Color(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
    func background(in scheme: ColorScheme) -> Color { color((scheme == .dark ? colors.dark : colors.light).0) }
    func border(in scheme: ColorScheme) -> Color { color((scheme == .dark ? colors.dark : colors.light).1) }
    func foreground(in scheme: ColorScheme) -> Color { color((scheme == .dark ? colors.dark : colors.light).2) }
    var accent: Color {
        switch self {
        case .blue: return .poolBlue
        case .emerald: return .poolGreen
        case .amber: return .orange
        case .rose: return .poolRed
        case .slate: return .gray
        case .cyan: return .teal
        case .violet: return .purple
        }
    }
}

struct WorkspaceControlModifier: ViewModifier {
    var tone: WorkspaceTone = .blue
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .foregroundColor(tone.foreground(in: colorScheme))
            .background(tone.background(in: colorScheme), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(tone.border(in: colorScheme), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .opacity(isEnabled ? 1 : 0.6)
    }
}

struct WorkspaceOutlinedButtonStyle: ButtonStyle {
    var tone: WorkspaceTone = .blue
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.modifier(WorkspaceControlModifier(tone: tone)).opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct WorkspaceIdentityHeader: View {
    let title: String
    let eyebrow: String
    var subtitle: String = ""
    var systemImage: String = ""
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !systemImage.isEmpty {
                Image(systemName: systemImage).font(.headline).foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow.uppercased()).font(.caption2.weight(.bold)).tracking(1.2).foregroundStyle(.white.opacity(0.75))
                Text(title).font(compact ? .headline.weight(.bold) : .title2.weight(.bold)).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
                if !subtitle.isEmpty { Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.85)).fixedSize(horizontal: false, vertical: true) }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(compact ? 12 : 16)
        .background(Color(.sRGB, red: 14/255, green: 36/255, blue: 92/255, opacity: 1), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct WorkspaceSectionHeading: View {
    let title: String
    let systemImage: String
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage).font(.subheadline.weight(.semibold))
                .foregroundStyle(WorkspaceTone.blue.foreground(in: colorScheme))
                .frame(width: 32, height: 32)
                .background(WorkspaceTone.blue.background(in: colorScheme), in: RoundedRectangle(cornerRadius: 6))
            Text(title).font(.headline.weight(.semibold)).foregroundStyle(.primary)
        }
    }
}

// MARK: - Dismiss / Delete

struct DismissButtonModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(WorkspaceControlModifier(tone: .rose)) }
}

struct DeleteButtonModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(WorkspaceControlModifier(tone: .rose)) }
}

struct DismissButtonTextModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content.foregroundColor(WorkspaceTone.rose.foreground(in: colorScheme)).font(.subheadline.weight(.semibold))
    }
}

struct KeyboardDismissButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.body.weight(.semibold))
        }
        .accessibilityLabel("Dismiss keyboard")
    }
}

// MARK: - Edit

struct EditButtonModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(WorkspaceControlModifier(tone: .blue)) }
}

struct EditButtonTextModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content.foregroundColor(WorkspaceTone.blue.foreground(in: colorScheme)).font(.subheadline.weight(.semibold))
    }
}

// MARK: - Calendar

struct CalendarButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.15))
            )
    }
}

struct CalendarButtonTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.basicFontText)
            .font(.subheadline.weight(.medium))
    }
}

// MARK: - List Cards

struct ListButtonModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color.poolBlack : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
            .foregroundColor(Color.basicFontText)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Cards

struct BasicCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.poolBlack)
            )
            .foregroundColor(Color.poolWhite)
            .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

struct HeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline.weight(.semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color(.sRGB, red: 14/255, green: 36/255, blue: 92/255, opacity: 1))
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

struct ListButtonTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.basicFontText)
            .font(.subheadline)
    }
}

// MARK: - Standard Buttons

struct BasicButtonModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(WorkspaceControlModifier(tone: .blue)) }
}

struct MockButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.medium))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.pink.opacity(0.8))
            .foregroundColor(.black)
            .cornerRadius(12)
    }
}

struct SubmitButtonModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(WorkspaceControlModifier(tone: .emerald)) }
}

struct InvertedSubmitButtonModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(WorkspaceControlModifier(tone: .emerald)) }
}

struct UploadButtonModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(WorkspaceControlModifier(tone: .cyan)) }
}

struct AddButtonModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(WorkspaceControlModifier(tone: .blue)) }
}

struct CustomerCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.9))
            )
            .foregroundColor(.white)
            .shadow(color: Color.orange.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

struct YellowButtonModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(WorkspaceControlModifier(tone: .amber)) }
}

struct OrangeButtonModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(WorkspaceControlModifier(tone: .amber)) }
}

struct BlueButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.poolBlue)
            .foregroundColor(Color.poolWhite)
            .cornerRadius(12)
            .shadow(color: Color.poolBlue.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct GreenCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green)
            )
            .foregroundColor(.white)
            .shadow(color: Color.green.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

struct BlueTagModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.poolBlue)
            .clipShape(Capsule())
            .foregroundColor(.white)
    }
}

struct RedLinkModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.footnote.weight(.medium))
            .padding(4)
            .foregroundColor(Color.poolRed)
    }
}

struct FadedGreenButtonModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(WorkspaceControlModifier(tone: .emerald)) }
}

struct OutLineButtonModifier: ViewModifier {
    func body(content: Content) -> some View { content.modifier(WorkspaceControlModifier(tone: .slate)) }
}

// MARK: - Filter Sheets

struct DripDropFilterSheet<Content: View>: View {
    @Binding private var isPresented: Bool

    private let title: String
    private let resetTitle: String
    private let isResetDisabled: Bool
    private let onReset: (() -> Void)?
    private let content: Content

    init(
        title: String = "Filters",
        isPresented: Binding<Bool>,
        resetTitle: String = "Reset",
        isResetDisabled: Bool = true,
        onReset: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._isPresented = isPresented
        self.resetTitle = resetTitle
        self.isResetDisabled = isResetDisabled
        self.onReset = onReset
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        content
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onReset {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(resetTitle) {
                            onReset()
                        }
                        .disabled(isResetDisabled)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

struct DripDropFilterSummaryCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = .poolBlue

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

struct DripDropFilterSection<Content: View>: View {
    let title: String
    let systemImage: String
    var tint: Color = .poolBlue
    private let content: Content

    init(
        title: String,
        systemImage: String,
        tint: Color = .poolBlue,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(title)
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

struct DripDropFilterRow<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let systemImage: String
    var tint: Color = .poolBlue
    private let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        tint: Color = .poolBlue,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: 8)

            content
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct DripDropFilterMenuLabel: View {
    let title: String
    var tint: Color = .poolBlue

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.bold))
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: 190, alignment: .trailing)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/*
struct DismissButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolRed)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)

    }
}
struct DeleteButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolRed)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)

    }
}
struct DismissButtonTextModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.white)


    }
}
struct EditButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolBlue)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}
struct EditButtonTextModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.white)
    }
}
struct CalendarButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .background(Color.red)
            .cornerRadius(5)
    }
}
struct CalendarButtonTextModifier:ViewModifier{
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.basicFontText)
    }
}
struct ListButtonModifier:ViewModifier{
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
//            .background(Color.poolGray) // I am trying new color schemes
            .background(Color.gray.opacity(0.5))
            .cornerRadius(4)
            .foregroundColor(Color.basicFontText)
            .fontDesign(.monospaced)
    }
}
struct BasicCardModifier:ViewModifier{
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolBlack)
            .cornerRadius(4)
            .foregroundColor(Color.poolWhite)
            .fontDesign(.monospaced)
    }
}
struct HeaderModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.darkGray)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}
struct ListButtonTextModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.basicFontText)
    }
}
struct BasicButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolBlue)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}
struct MockButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.pink)
            .cornerRadius(4)
            .foregroundColor(Color.black)
            .fontDesign(.monospaced)
    }
}
struct SubmitButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolGreen)
            .cornerRadius(4)
            .foregroundColor(Color.poolWhite)
            .fontDesign(.monospaced)
    }
}
struct InvertedSubmitButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.listColor)
            .cornerRadius(4)
            .padding(1)
            .background(Color.poolGreen)
            .cornerRadius(5)
            .foregroundColor(Color.poolBlack)
            .fontDesign(.monospaced)
    }
}
struct UploadButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.teal)
            .cornerRadius(4)
            .foregroundColor(Color.black)
            .fontDesign(.monospaced)
    }
}
struct AddButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolBlue)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}
struct CustomerCardModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.orange)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}

struct YellowButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.realYellow)
            .cornerRadius(4)
            .foregroundColor(Color.black)
            .fontDesign(.monospaced)
    }
}
struct OrangeButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.orange)
            .cornerRadius(4)
            .foregroundColor(Color.black)
            .fontDesign(.monospaced)
    }
}
struct BlueButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolBlue)
            .cornerRadius(4)
            .foregroundColor(Color.poolWhite)
            .fontDesign(.monospaced)
    }
}
struct GreenCardModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.green)
            .cornerRadius(4)
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}
struct BlueTagModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .background(Color.poolBlue )
            .clipShape(Capsule())
            .foregroundColor(Color.white)
            .fontDesign(.monospaced)
    }
}
struct RedLinkModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .font(.footnote)
            .padding(3)
            .foregroundColor(Color.poolRed)
            .fontDesign(.monospaced)
    }
}
struct FadedGreenButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(.horizontal,6)
            .padding(.vertical,4)
            .background(Color.poolGreen.opacity(0.5))
            .cornerRadius(4)
            .foregroundColor(Color.black)
            .fontDesign(.monospaced)
    }
}

struct OutLineButtonModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .padding(1)
            .background(Color.black)
            .cornerRadius(5)
    }
}
*/
