//
//  ServiceStopTypeUseCase.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/20/26.
//


//
//  ServiceStopTypeUseCase.swift
//  DripDrop
//

import Foundation

enum ServiceStopTypeUseCase: String, Codable, Hashable, CaseIterable {
    case jobVisit
    case recurringRoute
    case routePlusSpa
    case serviceCall
    case commercialRoute
    case commercialMultiBow
    case startup
    case estimate
    case unknown

    var fallbackTypeId: String {
        switch self {
        case .jobVisit, .serviceCall:
            return PayrollSystemSourceIds.jobServiceStop

        case .recurringRoute,
             .routePlusSpa,
             .commercialRoute,
             .commercialMultiBow:
            return PayrollSystemSourceIds.recurringServiceStop

        case .startup,
             .estimate,
             .unknown:
            return PayrollSystemSourceIds.unknownServiceStop
        }
    }

    var fallbackName: String {
        switch self {
        case .jobVisit:
            return "Job Visit"
        case .recurringRoute:
            return "Recurring Service Stop"
        case .routePlusSpa:
            return "Route + Spa"
        case .serviceCall:
            return "Service Call"
        case .commercialRoute:
            return "Commercial Route"
        case .commercialMultiBow:
            return "Commercial Multi-BOW"
        case .startup:
            return "Startup"
        case .estimate:
            return "Estimate"
        case .unknown:
            return "Unknown Service Stop"
        }
    }

    var fallbackImageName: String {
        switch self {
        case .jobVisit:
            return "briefcase"
        case .recurringRoute:
            return "figure.pool.swim"
        case .routePlusSpa:
            return "bubbles.and.sparkles"
        case .serviceCall:
            return "phone"
        case .commercialRoute:
            return "building.2"
        case .commercialMultiBow:
            return "building.2.crop.circle"
        case .startup:
            return "play.circle"
        case .estimate:
            return "doc.text.magnifyingglass"
        case .unknown:
            return "questionmark.circle"
        }
    }

    var candidateNames: [String] {
        switch self {
        case .jobVisit:
            return ["Job Visit", "Service Call", "Job"]
        case .recurringRoute:
            return ["Weekly Route", "Recurring Service Stop", "Route", "Routes"]
        case .routePlusSpa:
            return ["Route + Spa", "Pool + Spa", "Weekly Route + Spa"]
        case .serviceCall:
            return ["Service Call", "Job Visit"]
        case .commercialRoute:
            return ["Commercial Route", "Commercial"]
        case .commercialMultiBow:
            return ["Commercial Multi-BOW", "Commercial Multi BOW", "Commercial Multi Body of Water"]
        case .startup:
            return ["Startup", "Start Up"]
        case .estimate:
            return ["Estimate"]
        case .unknown:
            return []
        }
    }
}

struct ServiceStopTypeFields {
    var typeId: String
    var type: String
    var typeImage: String
}

enum ServiceStopTypeResolver {

    static func suggestedType(
        from serviceStopTypes: [CompanyServiceStopType],
        useCase: ServiceStopTypeUseCase
    ) -> CompanyServiceStopType? {
        let activeTypes = serviceStopTypes
            .filter { $0.isActive }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.name < $1.name
                }

                return $0.sortOrder < $1.sortOrder
            }

        for candidateName in useCase.candidateNames {
            if let exact = activeTypes.first(where: {
                normalized($0.name) == normalized(candidateName)
            }) {
                return exact
            }
        }

        for candidateName in useCase.candidateNames {
            if let contains = activeTypes.first(where: {
                normalized($0.name).contains(normalized(candidateName)) ||
                normalized(candidateName).contains(normalized($0.name))
            }) {
                return contains
            }
        }

        return activeTypes.first
    }

    static func serviceStopTypeFields(
        selectedType: CompanyServiceStopType?,
        useCase: ServiceStopTypeUseCase
    ) -> ServiceStopTypeFields {
        if let selectedType {
            return ServiceStopTypeFields(
                typeId: selectedType.id,
                type: selectedType.name,
                typeImage: selectedType.imageName ?? ""
            )
        }

        return ServiceStopTypeFields(
            typeId: useCase.fallbackTypeId,
            type: useCase.fallbackName,
            typeImage: useCase.fallbackImageName
        )
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "&", with: "and")
    }
}