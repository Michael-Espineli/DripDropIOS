import Foundation

enum ShoppingPrepKeyBuilder {

    static func user(_ userId: String) -> String {
        "user:\(userId)"
    }

    static func customer(_ customerId: String) -> String {
        "customer:\(customerId)"
    }

    static func serviceLocation(_ serviceLocationId: String) -> String {
        "serviceLocation:\(serviceLocationId)"
    }

    static func job(_ jobId: String) -> String {
        "job:\(jobId)"
    }

    static func serviceStop(_ serviceStopId: String) -> String {
        "serviceStop:\(serviceStopId)"
    }

    static func keysForServiceStop(_ stop: ServiceStop) -> [String] {
        var keys: [String] = []

        if !stop.id.isEmpty {
            keys.append(serviceStop(stop.id))
        }

        if !stop.customerId.isEmpty {
            keys.append(customer(stop.customerId))
        }

        if !stop.serviceLocationId.isEmpty {
            keys.append(serviceLocation(stop.serviceLocationId))
        }

        if !stop.jobId.isEmpty {
            keys.append(job(stop.jobId))
        }

        return Array(Set(keys))
    }

    static func keysForRoute(
        serviceStops: [ServiceStop],
        userId: String
    ) -> [String] {
        var keys: [String] = [
            user(userId)
        ]

        for stop in serviceStops {
            keys.append(contentsOf: keysForServiceStop(stop))
        }

        return Array(Set(keys))
    }

    static func keysForJobMaterial(
        jobId: String,
        customerId: String,
        serviceLocationId: String
    ) -> [String] {
        var keys: [String] = []

        if !jobId.isEmpty {
            keys.append(job(jobId))
        }

        if !customerId.isEmpty {
            keys.append(customer(customerId))
        }

        if !serviceLocationId.isEmpty {
            keys.append(serviceLocation(serviceLocationId))
        }

        return Array(Set(keys))
    }
}