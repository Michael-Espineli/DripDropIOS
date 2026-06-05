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
        case .jobVisit, .serviceCall:
            return PayrollSystemSourceIds.jobServiceStop

        case .jobEstimate,
             .estimate:
            return PayrollSystemSourceIds.jobEstimateServiceStop

        case .serviceAgreementEstimate,
             .startup:
            return PayrollSystemSourceIds.serviceAgreementEstimateServiceStop

        case .customerRelationship:
            return PayrollSystemSourceIds.customerRelationshipServiceStop

        case .recurringRoute,
             .routePlusSpa,
             .commercialRoute,
             .commercialMultiBow:
            return PayrollSystemSourceIds.recurringServiceStop

        case .unknown:
            return PayrollSystemSourceIds.unknownServiceStop
        }
    }

    var category: ServiceStopCategory {
        switch self {
        case .jobVisit, .serviceCall:
            return .job
        case .jobEstimate, .estimate:
            return .jobEstimate
        case .serviceAgreementEstimate, .startup:
            return .serviceAgreementEstimate
        case .customerRelationship, .unknown:
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
            return "Job Visit"
        case .jobEstimate:
            return "Job Estimate"
        case .serviceAgreementEstimate:
            return "Service Agreement Estimate"
        case .customerRelationship:
            return "Customer Relationship"
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
            return "Job Estimate"
        case .unknown:
            return "Unknown Service Stop"
        }
    }

    var fallbackImageName: String {
        switch self {
        case .jobVisit:
            return "briefcase"
        case .jobEstimate:
            return "doc.text.magnifyingglass"
        case .serviceAgreementEstimate:
            return "list.clipboard"
        case .customerRelationship:
            return "person.wave.2"
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
            return ["Job Visit", "Service Call", "Job"]
        case .jobEstimate:
            return ["Job Estimate", "Estimate For Job", "Estimate", "Bid Visit"]
        case .serviceAgreementEstimate:
            return ["Service Agreement Estimate", "Recurring Service Estimate", "New Service Estimate", "Startup", "Start Up", "New Pool"]
        case .customerRelationship:
            return ["Customer Relationship", "Customer Visit", "Follow Up", "Courtesy Visit", "Mistake Fix"]
        case .recurringRoute:
            return ["Weekly Route", "Residential Route", "Recurring Service Stop", "Standard Route", "Pool Route", "Route", "Routes"]
        case .routePlusSpa:
            return ["Route + Spa", "Pool + Spa", "Weekly Route + Spa"]
        case .serviceCall:
            return ["Service Call", "Job Visit"]
        case .commercialRoute:
            return ["Commercial Route", "Commercial"]
        case .commercialMultiBow:
            return ["Commercial Multi-BOW", "Commercial Multi BOW", "Commercial Multi Body of Water"]
        case .startup:
            return ["Service Agreement Estimate", "Startup", "Start Up", "New Service Estimate"]
        case .estimate:
            return ["Job Estimate", "Estimate"]
        case .unknown:
            return []
        }
    }
}

struct ServiceStopTypeFields {
    var typeId: String
    var type: String
    var typeImage: String
    var category: ServiceStopCategory = .customerRelationship

    var isSystemFallback: Bool {
        typeId == PayrollSystemSourceIds.recurringServiceStop ||
        typeId == PayrollSystemSourceIds.jobServiceStop ||
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
