struct EnvironmentBanner: View {
    var body: some View {
        #if DEBUG
        if AppEnvironment.current == .dev {
            Text("DEV")
                .font(.caption2)
                .bold()
                .padding(6)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding()
                .accessibilityHidden(true)
        }
        #endif
    }
}