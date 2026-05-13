import Foundation

struct ActiveRouteLog:Identifiable, Codable,Hashable{
    
    var id:String = UUID().uuidString
    var activeRouteId:String

    var startTime:Date
    var startLatitude:Double
    var startLongitude:Double
    
    var endTime:Date?
    var endLatitude:Double?
    var endLongitude:Double?
    
    var type:WorkLogType
    var companyId:String
    var companyName:String
    var userId:String
    var userName:String
    var current:Bool
    init(
        id: String,
        activeRouteId: String,

        startTime :Date,
        startLatitude :Double,
        startLongitude :Double,
        
        endTime :Date? = nil,
        endLatitude :Double? = nil,
        endLongitude :Double? = nil,

        type: WorkLogType,
        companyId: String,
        companyName: String,
        userId: String,
        userName: String,
        current: Bool

    ){
        self.id = id
        self.activeRouteId = activeRouteId

        self.startTime = startTime
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        
        self.endTime = endTime
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        
        self.type = type
        self.companyId = companyId
        self.companyName = companyName
        self.userId = userId
        self.userName = userName
        self.current = current

    }
    enum CodingKeys:String, CodingKey {
        case id = "id"
        case activeRouteId = "activeRouteId"

        case startTime = "startTime"
        case startLatitude = "startLatitude"
        case startLongitude = "startLongitude"
        
        case endTime = "endTime"
        case endLatitude = "endLatitude"
        case endLongitude = "endLongitude"
        
        case type = "type"
        case companyId = "companyId"
        case companyName = "companyName"
        
        case userId = "userId"
        case userName = "userName"
        case current = "current"
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(startTime)
        hasher.combine(endTime)
    }
    static func == (lhs: ActiveRouteLog, rhs: ActiveRouteLog) -> Bool {
        return lhs.id == rhs.id &&
        lhs.startTime == rhs.startTime
    }
}
