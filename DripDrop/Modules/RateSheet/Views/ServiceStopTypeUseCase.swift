//
//  ServiceStopTypeUseCase.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/20/26.
//


import Foundation

enum ServiceStopTypeUseCase: String, Codable, Hashable, CaseIterable {
    case jobVisit
    case jobEstimate
    case serviceAgreementEstimate
    case customerRelationship
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
        case .jobVisit:
            return PayrollSystemSourceIds.jobServiceStop

        case .jobEstimate,
             .estimate:
            return PayrollSystemSourceIds.jobEstimateServiceStop

        case .serviceAgreementEstimate,
             .startup:
            return PayrollSystemSourceIds.serviceAgreementEstimateServiceStop

        case .customerRelationship,
             .serviceCall:
            return PayrollSystemSourceIds.customerRelationshipServiceStop

        case .recurringRoute,
             .routePlusSpa:
            return PayrollSystemSourceIds.recurringServiceStop

        case .commercialRoute,
             .commercialMultiBow:
            return PayrollSystemSourceIds.commercialRoute

        case .unknown:
            return PayrollSystemSourceIds.unknownServiceStop
        }
    }

    var category: ServiceStopCategory {
        switch self {
        case .jobVisit:
            return .job
        case .jobEstimate, .estimate:
            return .jobEstimate
        case .serviceAgreementEstimate, .startup:
            return .serviceAgreementEstimate
        case .customerRelationship, .serviceCall, .unknown:
            return .customerRelationship
        case .recurringRoute,
             .routePlusSpa,
             .commercialRoute,
             .commercialMultiBow:
            return .route
        }
    }

    var fallbackName: String {
        switch self {
        case .jobVisit:
            return "Filter Cleaning"
        case .jobEstimate:
            return "Estimate"
        case .serviceAgreementEstimate:
            return "Estimate"
        case .customerRelationship:
            return "Service Call"
        case .recurringRoute:
            return "Residential"
        case .routePlusSpa:
            return "Route + Spa"
        case .serviceCall:
            return "Service Call"
        case .commercialRoute:
            return "Commercial"
        case .commercialMultiBow:
            return "Commercial"
        case .startup:
            return "Estimate"
        case .estimate:
            return "Estimate"
        case .unknown:
            return "Unknown Service Stop"
        }
    }

    var fallbackImageName: String {
        switch self {
        case .jobVisit:
            return "sparkles"
        case .jobEstimate:
            return "doc.text.magnifyingglass"
        case .serviceAgreementEstimate:
            return "list.clipboard"
        case .customerRelationship:
            return "phone"
        case .recurringRoute:
            return "house"
        case .routePlusSpa:
            return "bubbles.and.sparkles"
        case .serviceCall:
            return "phone"
        case .commercialRoute:
            return "building.2"
        case .commercialMultiBow:
            return "building.2.crop.circle"
        case .startup:
            return "list.clipboard"
        case .estimate:
            return "doc.text.magnifyingglass"
        case .unknown:
            return "questionmark.circle"
        }
    }

    var candidateNames: [String] {
        switch self {
        case .jobVisit:
            return ["Filter Cleaning", "Salt Cell Cleaning", "Job Visit", "Job"]
        case .jobEstimate:
            return ["Estimate", "Job Estimate", "Estimate For Job", "Bid Visit"]
        case .serviceAgreementEstimate:
            return ["Estimate", "Service Agreement Estimate", "Recurring Service Estimate", "New Service Estimate", "Startup", "Start Up", "New Pool"]
        case .customerRelationship:
            return ["Service Call", "Customer Relationship", "Customer Visit", "Follow Up", "Courtesy Visit", "Mistake Fix"]
        case .recurringRoute:
            return ["Residential", "Residential Route", "Weekly Route", "Recurring Service Stop", "Standard Route", "Pool Route", "Route", "Routes"]
        case .routePlusSpa:
            return ["Route + Spa", "Residential + Spa", "Pool + Spa", "Weekly Route + Spa"]
        case .serviceCall:
            return ["Service Call", "Customer Relationship", "Customer Visit"]
        case .commercialRoute:
            return ["Commercial", "Commercial Route"]
        case .commercialMultiBow:
            return ["Commercial Multi-BOW", "Commercial Multi BOW", "Commercial Multi Body of Water", "Commercial"]
        case .startup:
            return ["Estimate", "Service Agreement Estimate", "Startup", "Start Up", "New Service Estimate"]
        case .estimate:
            return ["Estimate", "Job Estimate"]
        case .unknown:
            return []
        }
    }

    var filtersPayTypesByCategory: Bool {
        self != .unknown
    }
}

struct ServiceStopTypeFields {
    var typeId: String
    var type: String
    var typeImage: String
    var category: ServiceStopCategory = .customerRelationship

    var isSystemFallback: Bool {
        typeId == PayrollSystemSourceIds.recurringServiceStop ||
        typeId == PayrollSystemSourceIds.commercialRoute ||
        typeId == PayrollSystemSourceIds.jobServiceStop ||
        typeId == PayrollSystemSourceIds.jobSaltCellCleaning ||
        typeId == PayrollSystemSourceIds.jobEstimateServiceStop ||
        typeId == PayrollSystemSourceIds.serviceAgreementEstimateServiceStop ||
        typeId == PayrollSystemSourceIds.customerRelationshipServiceStop ||
        typeId == PayrollSystemSourceIds.unknownServiceStop
    }
}

enum ServiceStopTypeResolver {

    static func suggestedType(
        from serviceStopTypes: [CompanyServiceStopType],
        useCase: ServiceStopTypeUseCase
    ) -> CompanyServiceStopType? {
        let activeTypes = matchingTypes(
            from: serviceStopTypes,
            useCase: useCase
        )

        for candidateName in useCase.candidateNames {
            if let exact = activeTypes.first(where: {
                normalized($0.name) == normalized(candidateName)
            }) {
                return exact
            }
        }

        for candidateName in useCase.candidateNames {
            let candidateValue = normalized(candidateName)
            if let contains = activeTypes.first(where: {
                if shouldSkipCandidateMatch(typeName: $0.name, candidateValue: candidateValue, useCase: useCase) {
                    return false
                }

                return normalized($0.name).contains(candidateValue) ||
                candidateValue.contains(normalized($0.name))
            }) {
                return contains
            }
        }

        return nil
    }

    static func matchingTypes(
        from serviceStopTypes: [CompanyServiceStopType],
        useCase: ServiceStopTypeUseCase
    ) -> [CompanyServiceStopType] {
        serviceStopTypes
            .filter { $0.isActive }
            .filter { matches($0, useCase: useCase) }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.name < $1.name
                }

                return $0.sortOrder < $1.sortOrder
            }
    }

    static func matches(
        _ type: CompanyServiceStopType,
        useCase: ServiceStopTypeUseCase
    ) -> Bool {
        guard useCase.filtersPayTypesByCategory else {
            return true
        }

        return type.resolvedCategory(fallback: useCase.category) == useCase.category
    }

    static func serviceStopTypeFields(
        selectedType: CompanyServiceStopType?,
        useCase: ServiceStopTypeUseCase
    ) -> ServiceStopTypeFields {
        if let selectedType {
            return ServiceStopTypeFields(
                typeId: selectedType.id,
                type: selectedType.name,
                typeImage: selectedType.imageName ?? "",
                category: selectedType.resolvedCategory(fallback: useCase.category)
            )
        }

        return ServiceStopTypeFields(
            typeId: useCase.fallbackTypeId,
            type: useCase.fallbackName,
            typeImage: useCase.fallbackImageName,
            category: useCase.category
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

    private static func shouldSkipCandidateMatch(
        typeName: String,
        candidateValue: String,
        useCase: ServiceStopTypeUseCase
    ) -> Bool {
        guard useCase == .recurringRoute else { return false }
        guard candidateValue == "route" || candidateValue == "routes" else { return false }

        return normalized(typeName).contains("commercial")
    }
}

extension ProductionDataServiceProtocol {
    func resolvedServiceStopTypeFields(
        companyId: String,
        useCase: ServiceStopTypeUseCase,
        selectedType: CompanyServiceStopType? = nil,
        context: String
    ) async -> ServiceStopTypeFields {
        if let selectedType {
            return ServiceStopTypeResolver.serviceStopTypeFields(
                selectedType: selectedType,
                useCase: useCase
            )
        }

        do {
            let companyTypes = try await fetchCompanyServiceStopTypes(companyId: companyId)
            let suggestedType = ServiceStopTypeResolver.suggestedType(
                from: companyTypes,
                useCase: useCase
            )
            let fields = ServiceStopTypeResolver.serviceStopTypeFields(
                selectedType: suggestedType,
                useCase: useCase
            )

            if suggestedType == nil {
                print("[ServiceStopTypeResolver][fallback] context=\(context) companyId=\(companyId) useCase=\(useCase.rawValue) typeId=\(fields.typeId) type=\(fields.type)")
            }

            return fields
        } catch {
            let fields = ServiceStopTypeResolver.serviceStopTypeFields(
                selectedType: nil,
                useCase: useCase
            )
            print("[ServiceStopTypeResolver][error] context=\(context) companyId=\(companyId) useCase=\(useCase.rawValue) typeId=\(fields.typeId) type=\(fields.type) error=\(error.localizedDescription)")
            return fields
        }
    }
}
