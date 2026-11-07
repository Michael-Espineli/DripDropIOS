import SwiftUI

/// A single launch session spans account and workspace loading.
@MainActor
final class AppLoadingState: ObservableObject {
    enum Phase: Equatable { case account, workspace, finishing, ready }
    @Published private(set) var phase: Phase = .account
    @Published private(set) var hasLoadedAccount = false
    private(set) var sessionID = UUID()

    var isVisible: Bool { phase != .ready }
    // Visual milestones, rather than a measured download percentage.
    var fillTarget: CGFloat {
        switch phase {
        case .account: return 0.46
        case .workspace: return 0.88
        case .finishing, .ready: return 1
        }
    }
    var message: String {
        switch phase {
        case .account: return "Getting things flowing…"
        case .workspace: return "Preparing your workspace…"
        case .finishing, .ready: return "Ready to dive in."
        }
    }
    func beginAccountLoad() {
        sessionID = UUID()
        hasLoadedAccount = false
        phase = .account
    }
    func accountLoaded(for session: UUID) {
        guard session == sessionID, phase == .account else { return }
        hasLoadedAccount = true
        phase = .workspace
    }
    func workspaceLoaded(for session: UUID) {
        guard session == sessionID, phase == .workspace else { return }
        phase = .finishing
    }
    func finish() {
        guard phase == .finishing else { return }
        phase = .ready
    }
    func showSignIn() {
        sessionID = UUID()
        hasLoadedAccount = false
        phase = .ready
    }
}

/// Interpolate on the drawing clock rather than starting a separate 60 Hz
/// SwiftUI animation. A new loading milestone continues from the visible level.
private struct LoadingFillTransition {
    private(set) var start: CGFloat = 0.025
    private(set) var target: CGFloat = 0.025
    private(set) var beganAt = Date()
    private(set) var duration: TimeInterval = 0

    func value(at date: Date) -> CGFloat {
        guard duration > 0 else { return target }
        let progress = min(max(date.timeIntervalSince(beganAt) / duration, 0), 1)
        guard progress > 0 else { return start }
        guard progress < 1 else { return target }
        let eased = progress * progress * (3 - 2 * progress)
        return start + (target - start) * eased
    }

    mutating func move(to newTarget: CGFloat, at date: Date, duration: TimeInterval) {
        start = value(at: date)
        target = max(start, min(max(newTarget, 0.025), 1))
        beganAt = date
        self.duration = max(duration, 0)
    }
}

struct WaterLevelLoading: View {
    var fillTarget: CGFloat = 0.88
    var message = "Getting things flowing…"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var fillTransition = LoadingFillTransition()
    @State private var startedAt = Date()
    @State private var isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.95, green: 0.98, blue: 0.99)
                // All changing geometry shares one bounded drawing clock.
                TimelineView(.animation(minimumInterval: 1.0 / (isLowPowerMode ? 15 : 24),
                                        paused: reduceMotion || scenePhase != .active)) { timeline in
                    let fill = fillTransition.value(at: timeline.date)
                    let level = geometry.size.height * (1 - fill)
                    let scale = min(geometry.size.width / 480, 1.05)
                    let spout = CGPoint(x: geometry.size.width * 0.66,
                                        y: max(geometry.safeAreaInsets.top + 150 * scale, geometry.size.height * 0.22))
                    ZStack {
                        PouringLiquid(fill: fill, time: reduceMotion ? 0 : timeline.date.timeIntervalSince(startedAt),
                                      reduceMotion: reduceMotion, lowPower: isLowPowerMode, spout: spout, scale: scale)

                        // The small static Canvas is retained independently of the
                        // water. Only its rectangular clip changes as water rises.
                        GallonJugArtwork()
                            .equatable()
                            .frame(width: 174 * scale, height: 172 * scale)
                            .clipShape(AboveWaterClip(height: level - (spout.y - 151 * scale)))
                            .position(x: spout.x + 75 * scale, y: spout.y - 65 * scale)

                        lettering(bottomInset: geometry.safeAreaInsets.bottom)
                            .foregroundStyle(Color(red: 0.09, green: 0.20, blue: 0.33))
                        lettering(bottomInset: geometry.safeAreaInsets.bottom)
                            .foregroundStyle(.white)
                            .mask(alignment: .bottom) {
                                Rectangle().frame(height: geometry.size.height * fill)
                            }
                    }
                }
            }
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Drip Drop. \(message)")
        .task(id: fillTarget) {
            fillTransition.move(to: fillTarget, at: Date(),
                                duration: reduceMotion ? 0 : (fillTarget >= 1 ? 0.65 : 6))
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { fillTransition.move(to: fillTarget, at: Date(), duration: 0) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    private func lettering(bottomInset: CGFloat) -> some View {
        brand.overlay(alignment: .bottom) {
            Text(message)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, max(bottomInset, 20) + 28)
        }
    }

    private var brand: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.system(size: 37, weight: .regular))
                .padding(.bottom, 5)
            Text("Drip Drop")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("POOL CARE, IN FLOW")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .tracking(2.5)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AboveWaterClip: Shape {
    let height: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: 0, y: 0, width: rect.width, height: min(max(height, 0), rect.height)))
    }
}

private struct PouringLiquid: View {
    let fill: CGFloat
    let time: TimeInterval
    let reduceMotion: Bool
    let lowPower: Bool
    let spout: CGPoint
    let scale: CGFloat

    var body: some View {
        Canvas { context, size in
            let level = size.height * (1 - fill)
            let amplitude: CGFloat = reduceMotion ? 0 : 7 * min(1, (1 - fill) * 12)
            if !reduceMotion, level > spout.y {
                drawStream(in: &context, level: level)
            }
            context.fill(wave(size: size, level: level - amplitude * 0.6, amplitude: amplitude, phase: time * 1.5 + 2),
                         with: .color(Color(red: 0.38, green: 0.82, blue: 0.92).opacity(0.5)))
            let water = wave(size: size, level: level, amplitude: amplitude, phase: -time * 1.9)
            context.fill(water, with: .linearGradient(
                Gradient(colors: [Color(red: 0.12, green: 0.69, blue: 0.85), Color(red: 0.04, green: 0.38, blue: 0.72)]),
                startPoint: CGPoint(x: 0, y: level),
                endPoint: CGPoint(x: size.width * 0.55, y: size.height)))
            if !reduceMotion {
                var underwater = context
                underwater.clip(to: water)
                drawBubbles(in: &underwater, size: size, level: level)
                if !lowPower, level > spout.y {
                    drawSplash(in: &context, level: level)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func wave(size: CGSize, level: CGFloat, amplitude: CGFloat, phase: Double) -> Path {
        guard amplitude > 0 else {
            return Path(CGRect(x: 0, y: level, width: size.width, height: max(0, size.height - level)))
        }
        // Twelve smooth cubic segments replace a line and two sine evaluations
        // every three points, keeping the work constant on phones and tablets.
        let frequency = 2 * CGFloat.pi / max(size.width, 1)
        func surface(_ x: CGFloat) -> (y: CGFloat, slope: CGFloat) {
            let angle = x * frequency
            return (level + sin(angle + phase) * amplitude + sin(angle * 2 - phase * 0.7) * amplitude * 0.3,
                    frequency * amplitude * (cos(angle + phase) + 0.6 * cos(angle * 2 - phase * 0.7)))
        }
        return Path { path in
            var previous = surface(0)
            path.move(to: CGPoint(x: 0, y: previous.y))
            for index in 0..<12 {
                let x0 = size.width * CGFloat(index) / 12
                let x1 = size.width * CGFloat(index + 1) / 12
                let next = surface(x1)
                let step = (x1 - x0) / 3
                path.addCurve(to: CGPoint(x: x1, y: next.y),
                              control1: CGPoint(x: x0 + step, y: previous.y + previous.slope * step),
                              control2: CGPoint(x: x1 - step, y: next.y - next.slope * step))
                previous = next
            }
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()
        }
    }

    private func drawStream(in context: inout GraphicsContext, level: CGFloat) {
        let width = (12 + sin(time * 5) * 1.4) * scale
        let sway = sin(time * 3) * 4
        var stream = Path()
        stream.move(to: CGPoint(x: spout.x - width * 0.4, y: spout.y - 4))
        stream.addCurve(to: CGPoint(x: spout.x - width * 0.7, y: level + 8),
                        control1: CGPoint(x: spout.x - width, y: spout.y + 50),
                        control2: CGPoint(x: spout.x + sway, y: level - 60))
        stream.addLine(to: CGPoint(x: spout.x + width * 0.7, y: level + 8))
        stream.addCurve(to: CGPoint(x: spout.x + width * 0.4, y: spout.y - 4),
                        control1: CGPoint(x: spout.x + width + sway, y: level - 60),
                        control2: CGPoint(x: spout.x + width * 0.3, y: spout.y + 50))
        stream.closeSubpath()
        context.fill(stream, with: .linearGradient(
            Gradient(colors: [Color.cyan.opacity(0.45), Color(red: 0.16, green: 0.70, blue: 0.86)]),
            startPoint: spout, endPoint: CGPoint(x: spout.x + width, y: level)))
    }

    private func drawBubbles(in context: inout GraphicsContext, size: CGSize, level: CGFloat) {
        let depth = max(size.height - level, 1)
        for index in 0..<(lowPower ? 4 : 8) {
            let seed = Double(index)
            let cycle = (time * (0.08 + Double(index % 4) * 0.016) + seed * 0.137).truncatingRemainder(dividingBy: 1)
            let x = size.width * CGFloat((seed * 0.618 + 0.08).truncatingRemainder(dividingBy: 1)) + sin(time + seed) * 9
            let y = size.height + 12 - cycle * (depth + 35)
            let radius = CGFloat(2 + index % 4)
            context.stroke(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
                           with: .color(.white.opacity(0.25)), lineWidth: 1)
        }
    }

    private func drawSplash(in context: inout GraphicsContext, level: CGFloat) {
        let ripple = CGFloat((time * 1.5).truncatingRemainder(dividingBy: 1))
        let width = (22 + ripple * 58) * scale
        context.stroke(Path(ellipseIn: CGRect(x: spout.x - width / 2, y: level - 3, width: width, height: 8 * scale)),
                       with: .color(.white.opacity(0.65 * (1 - ripple))), lineWidth: 1.5)
        for index in 0..<3 {
            let cycle = (time * 1.3 + Double(index) / 3).truncatingRemainder(dividingBy: 1)
            let side: CGFloat = index.isMultiple(of: 2) ? -1 : 1
            let dx = side * CGFloat(cycle) * 35 * scale
            let dy = -sin(cycle * .pi) * 25 * scale
            context.fill(Path(ellipseIn: CGRect(x: spout.x + dx, y: level + dy - 4, width: 3 * scale, height: 5 * scale)),
                         with: .color(Color.cyan.opacity(1 - cycle)))
        }
    }
}

/// Cached unit paths describe an upright gallon container; the drawing applies
/// one fixed pouring angle. This artwork has no animation or frame-clock input.
private enum GallonJugGeometry {
    static let silhouette = Path { path in
        path.move(to: CGPoint(x: 27, y: 11))
        path.addLine(to: CGPoint(x: 49, y: 11))
        path.addLine(to: CGPoint(x: 49, y: 22))
        path.addCurve(to: CGPoint(x: 92, y: 33), control1: CGPoint(x: 55, y: 25), control2: CGPoint(x: 79, y: 25))
        path.addCurve(to: CGPoint(x: 113, y: 81), control1: CGPoint(x: 108, y: 45), control2: CGPoint(x: 112, y: 61))
        path.addLine(to: CGPoint(x: 113, y: 148))
        path.addCurve(to: CGPoint(x: 97, y: 164), control1: CGPoint(x: 113, y: 160), control2: CGPoint(x: 106, y: 164))
        path.addCurve(to: CGPoint(x: 23, y: 164), control1: CGPoint(x: 76, y: 170), control2: CGPoint(x: 42, y: 170))
        path.addCurve(to: CGPoint(x: 7, y: 148), control1: CGPoint(x: 11, y: 163), control2: CGPoint(x: 7, y: 159))
        path.addLine(to: CGPoint(x: 7, y: 83))
        path.addCurve(to: CGPoint(x: 23, y: 37), control1: CGPoint(x: 7, y: 60), control2: CGPoint(x: 20, y: 48))
        path.addCurve(to: CGPoint(x: 27, y: 26), control1: CGPoint(x: 25, y: 32), control2: CGPoint(x: 27, y: 30))
        path.closeSubpath()
        // Integrated handle with the broad opening used on gallon bleach jugs.
        path.move(to: CGPoint(x: 50, y: 34))
        path.addCurve(to: CGPoint(x: 57, y: 48), control1: CGPoint(x: 51, y: 40), control2: CGPoint(x: 54, y: 45))
        path.addCurve(to: CGPoint(x: 75, y: 75), control1: CGPoint(x: 65, y: 58), control2: CGPoint(x: 67, y: 70))
        path.addCurve(to: CGPoint(x: 96, y: 81), control1: CGPoint(x: 83, y: 82), control2: CGPoint(x: 92, y: 86))
        path.addCurve(to: CGPoint(x: 93, y: 60), control1: CGPoint(x: 101, y: 76), control2: CGPoint(x: 99, y: 67))
        path.addCurve(to: CGPoint(x: 71, y: 40), control1: CGPoint(x: 87, y: 49), control2: CGPoint(x: 81, y: 44))
        path.addCurve(to: CGPoint(x: 50, y: 34), control1: CGPoint(x: 60, y: 35), control2: CGPoint(x: 54, y: 33))
        path.closeSubpath()
    }

    static let label = Path { path in
        path.move(to: CGPoint(x: 10, y: 94))
        path.addQuadCurve(to: CGPoint(x: 110, y: 94), control: CGPoint(x: 60, y: 102))
        path.addLine(to: CGPoint(x: 110, y: 134))
        path.addQuadCurve(to: CGPoint(x: 10, y: 134), control: CGPoint(x: 60, y: 143))
        path.closeSubpath()
    }

    static let shoulderSeam = Path { path in
        path.move(to: CGPoint(x: 9, y: 85))
        path.addQuadCurve(to: CGPoint(x: 111, y: 85), control: CGPoint(x: 60, y: 96))
    }

    static let baseRim = Path { path in
        path.move(to: CGPoint(x: 11, y: 149))
        path.addCurve(to: CGPoint(x: 109, y: 149), control1: CGPoint(x: 30, y: 158), control2: CGPoint(x: 90, y: 158))
    }
}

private struct GallonJugArtwork: View, Equatable {
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 174, y: size.height / 172)
            context.translateBy(x: 12, y: 151)
            context.rotate(by: .degrees(-115))
            context.translateBy(x: -37, y: -10)
            context.fill(GallonJugGeometry.silhouette, with: .linearGradient(
                Gradient(colors: [.white, Color(red: 0.94, green: 0.96, blue: 0.97),
                                  Color(red: 0.80, green: 0.86, blue: 0.90)]),
                startPoint: CGPoint(x: 5, y: 60), endPoint: CGPoint(x: 116, y: 80)),
                         style: FillStyle(eoFill: true))
            context.stroke(GallonJugGeometry.silhouette,
                           with: .color(Color(red: 0.57, green: 0.68, blue: 0.75).opacity(0.65)), lineWidth: 1.3)
            context.stroke(GallonJugGeometry.shoulderSeam, with: .color(.white.opacity(0.9)), lineWidth: 2)
            context.fill(GallonJugGeometry.label, with: .linearGradient(
                Gradient(colors: [Color(red: 0.12, green: 0.63, blue: 0.79), Color(red: 0.08, green: 0.42, blue: 0.67)]),
                startPoint: CGPoint(x: 10, y: 105), endPoint: CGPoint(x: 110, y: 130)))
            context.stroke(GallonJugGeometry.baseRim, with: .color(.white.opacity(0.85)), lineWidth: 2)
            var symbol = context.resolve(Image(systemName: "drop.fill"))
            symbol.shading = .color(.white)
            context.draw(symbol, in: CGRect(x: 52, y: 104, width: 18, height: 24))
            // Open neck and a molded lip: no cap obstructs the pour.
            let opening = Path(ellipseIn: CGRect(x: 24, y: 7, width: 27, height: 7))
            context.fill(opening, with: .color(Color(red: 0.10, green: 0.24, blue: 0.36)))
            context.stroke(opening, with: .color(Color(red: 0.65, green: 0.76, blue: 0.82)), lineWidth: 2)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    WaterLevelLoading()
}
