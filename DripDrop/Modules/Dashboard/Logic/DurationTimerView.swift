import SwiftUI
import Combine

/// A view that displays the duration between a start date and now (or an optional end date),
/// updating in real time.
public struct DurationTimerView: View {
    private let start: Date
    private let end: Date?
    private let updateInterval: TimeInterval
    private let showsHoursWhenZero: Bool

    @State private var now: Date = Date()
    @State private var timerCancellable: AnyCancellable?

    /// - Parameters:
    ///   - start: The start time for the timer.
    ///   - end: If provided, the timer shows the fixed duration between `start` and `end`.
    ///          If nil, it counts up continuously from `start` to now.
    ///   - updateInterval: How often the view updates while counting up. Default is 1 second.
    ///   - showsHoursWhenZero: If true, shows 00:MM:SS even when hours are zero; otherwise shows MM:SS.
    public init(start: Date, end: Date? = nil, updateInterval: TimeInterval = 1.0, showsHoursWhenZero: Bool = false) {
        self.start = start
        self.end = end
        self.updateInterval = updateInterval
        self.showsHoursWhenZero = showsHoursWhenZero
    }

    private var effectiveEnd: Date { end ?? now }

    private var duration: TimeInterval {
        max(0, effectiveEnd.timeIntervalSince(start))
    }

    private func formatted(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 || showsHoursWhenZero {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    public var body: some View {
        Text(formatted(duration))
            .monospacedDigit()
            .onAppear(perform: startTimerIfNeeded)
            .onDisappear(perform: stopTimer)
            .onChange(of: end) { _, _ in
                // If end becomes non-nil, stop the timer
                if end != nil { stopTimer() }
            }
    }

    private func startTimerIfNeeded() {
        guard end == nil else { return }
        stopTimer()
        timerCancellable = Timer.publish(every: updateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { date in
                self.now = date
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

// MARK: - Previews
#Preview("Counting Up From Now") {
    DurationTimerView(start: Date().addingTimeInterval(-125)) // 2m 5s ago
        .font(.title)
        .padding()
}

#Preview("Fixed Duration") {
    let start = Date().addingTimeInterval(-3600)
    let end = Date().addingTimeInterval(-1800)
    return DurationTimerView(start: start, end: end, showsHoursWhenZero: true)
        .font(.title)
        .padding()
}
