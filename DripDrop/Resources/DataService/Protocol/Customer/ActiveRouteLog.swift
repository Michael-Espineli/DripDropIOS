import Foundation

struct ActiveRouteLog: Identifiable, Codable, Hashable {
    let id: UUID
    let routeName: String
    let startTime: Date
    let endTime: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case routeName
        case startTime
        case endTime
    }
    
    static func == (lhs: ActiveRouteLog, rhs: ActiveRouteLog) -> Bool {
        return lhs.id == rhs.id &&
               lhs.routeName == rhs.routeName &&
               lhs.startTime == rhs.startTime &&
               lhs.endTime == rhs.endTime
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(routeName)
        hasher.combine(startTime)
        hasher.combine(endTime)
    }
}
