enum AppEnvironment: String {
    case dev
    case prod

    static let current: AppEnvironment = {
        #if DEBUG
        // For debug, prefer reading from a compile-time flag or Info.plist key
        if let env = Bundle.main.object(forInfoDictionaryKey: "APP_ENV") as? String,
           let value = AppEnvironment(rawValue: env) {
            return value
        }
        return .dev
        #else
        return .prod
        #endif
    }()
}