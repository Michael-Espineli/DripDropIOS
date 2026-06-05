//
//  EmailConfigurationViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 9/26/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ServiceStopCategoryCompletionSettings: Identifiable, Codable, Equatable {
    var category: String
    var sendEmailOnFinish: Bool
    var requirePhotoOnFinish: Bool
    var emailSubject: String
    var emailBody: String
    var emailFooter: String
    var sendGridTemplateId: String?

    var id: String { category }

    static func defaultSettings(
        for category: ServiceStopCategory,
        companyName: String = "your pool company"
    ) -> ServiceStopCategoryCompletionSettings {
        let subject: String
        let body: String

        switch category {
        case .route:
            subject = "\(companyName) Service Report"
            body = "Thank you for letting \(companyName) service your pool. Here is a summary of today's visit."
        case .job:
            subject = "\(companyName) Job Visit Summary"
            body = "Thank you for choosing \(companyName). Here is a summary of the work completed during this visit."
        case .jobEstimate:
            subject = "\(companyName) Estimate Visit Recap"
            body = "Thank you for meeting with \(companyName). Here is a recap of the information gathered for your estimate."
        case .serviceAgreementEstimate:
            subject = "\(companyName) Service Agreement Visit Recap"
            body = "Thank you for considering \(companyName) for recurring service. Here is a recap of the service location information we gathered."
        case .customerRelationship:
            subject = "\(companyName) Visit Recap"
            body = "Thank you for taking the time to meet with \(companyName). Here is a recap of the visit and any follow-up notes."
        }

        return ServiceStopCategoryCompletionSettings(
            category: category.rawValue,
            sendEmailOnFinish: false,
            requirePhotoOnFinish: false,
            emailSubject: subject,
            emailBody: body,
            emailFooter: "Please contact us with any questions.",
            sendGridTemplateId: nil
        )
    }

    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "category": category,
            "sendEmailOnFinish": sendEmailOnFinish,
            "requirePhotoOnFinish": requirePhotoOnFinish,
            "emailSubject": emailSubject,
            "emailBody": emailBody,
            "emailFooter": emailFooter
        ]

        if let sendGridTemplateId, !sendGridTemplateId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["sendGridTemplateId"] = sendGridTemplateId
        }

        return data
    }
}

struct CompanyEmailConfiguration:Identifiable,Codable {
    var id : String = UUID().uuidString
    var emailIsOn: Bool
    var emailBody : String
    var requirePhoto : Bool
    var serviceStopCategorySettings: [String: ServiceStopCategoryCompletionSettings]? = nil
}

extension CompanyEmailConfiguration {
    func resolvedCategorySettings(companyName: String = "your pool company") -> [String: ServiceStopCategoryCompletionSettings] {
        var settings = serviceStopCategorySettings ?? [:]

        for category in ServiceStopCategory.allCases {
            if settings[category.rawValue] == nil {
                var defaultSettings = ServiceStopCategoryCompletionSettings.defaultSettings(
                    for: category,
                    companyName: companyName
                )
                defaultSettings.sendEmailOnFinish = emailIsOn
                defaultSettings.requirePhotoOnFinish = requirePhoto
                if !emailBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    defaultSettings.emailBody = emailBody
                }
                settings[category.rawValue] = defaultSettings
            }
        }

        return settings
    }

    func completionSettings(
        for category: ServiceStopCategory,
        companyName: String = "your pool company"
    ) -> ServiceStopCategoryCompletionSettings {
        resolvedCategorySettings(companyName: companyName)[category.rawValue]
        ?? ServiceStopCategoryCompletionSettings.defaultSettings(for: category, companyName: companyName)
    }
}
struct CustomerEmailConfiguration:Identifiable,Codable {
    var id : String = UUID().uuidString
    var customerId : String
    var emailIsOn : Bool
}

@MainActor
final class EmailConfigurationViewModel: ObservableObject {
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published var emailIsOn:Bool = false
    @Published var isLoading:Bool = false
    @Published var requiresPhoto:Bool = false

    @Published var allCustomersSelected:Bool = false

    @Published var emailBody:String = "false"
    @Published var categorySettings: [String: ServiceStopCategoryCompletionSettings] = [:]
    @Published private(set) var emailConfig:CompanyEmailConfiguration? = nil
    @Published private(set) var customerConfigList:[CustomerEmailConfiguration] = []
    @Published private(set) var customers:[Customer] = []
    @Published var hasChanges:Bool = false

    var hasAnyCategoryEmailOn: Bool {
        categorySettings.values.contains { $0.sendEmailOnFinish }
    }

    func onLoad(companyId:String) async throws {
        self.isLoading = true

        // get Standard Company Email Body
        self.emailConfig = try await dataService.getEmailConfigurationSettings(companyId: companyId)
        print("Got Email Config")
        if let emailConfig = self.emailConfig {
            self.emailIsOn = emailConfig.emailIsOn
            self.emailBody = emailConfig.emailBody
            self.requiresPhoto = emailConfig.requirePhoto
            self.categorySettings = emailConfig.resolvedCategorySettings()
        }
        var customerList = try await dataService.getCustomersActive(companyId: companyId, active: true)
        customerList.sort(by: {$0.lastName < $1.lastName})
        self.customers = customerList

        print("Got Customer List \(customers.count)")
        self.customerConfigList = try await dataService.getCustomerEmailConfigurationSettings(companyId: companyId)
        print("Got Customer Config List \(customerConfigList.count)")
        if self.customerConfigList.isEmpty {
            print("Config List is empty")
            self.allCustomersSelected = false
        } else {
            print("Config List is not empty")
            if self.customerConfigList.contains(where: {$0.emailIsOn == false}) {
                print("Any Customer Config List Does Not Contains Email Is On: False")
                self.allCustomersSelected = false
            } else {
                print("Any Customer Config List Contains Only Email Is On: True")
                self.allCustomersSelected = true
            }
        }
        self.isLoading = false

    }
    func saveChanges(companyId:String) async throws {
        self.isLoading = true

        if let emailConfig = self.emailConfig {
            let derivedEmailIsOn = hasAnyCategoryEmailOn
            if emailConfig.emailIsOn != derivedEmailIsOn {
                try await dataService.updateEmailConfigurationIsOn(companyId: companyId, emailIsOn: derivedEmailIsOn)
            }
            if emailConfig.emailBody != self.emailBody {
                try await dataService.updateEmailConfigurationBody(companyId: companyId, newBody: self.emailBody)
            }
            if emailConfig.requirePhoto != self.requiresPhoto {
                try await dataService.updateEmailConfigurationRequirePhoto(companyId: companyId, requirePhoto: self.requiresPhoto)
            }
            if emailConfig.resolvedCategorySettings() != self.categorySettings {
                try await dataService.updateEmailConfigurationCategorySettings(
                    companyId: companyId,
                    categorySettings: self.categorySettings
                )
            }
            self.emailConfig = try await dataService.getEmailConfigurationSettings(companyId: companyId)
            print("Got Email Config")
            if let emailConfig = self.emailConfig {
                self.emailIsOn = emailConfig.emailIsOn
                self.emailBody = emailConfig.emailBody
                self.requiresPhoto = emailConfig.requirePhoto
                self.categorySettings = emailConfig.resolvedCategorySettings()
            }
        }
        self.isLoading = false
    }
    func checkChanges(){
        print("Check Changes")
        if let emailConfig = self.emailConfig {
            let derivedEmailIsOn = hasAnyCategoryEmailOn
            let savedCategorySettings = emailConfig.resolvedCategorySettings()
            if emailConfig.emailIsOn != derivedEmailIsOn && emailConfig.emailBody != self.emailBody {
                self.hasChanges = true
            } else if emailConfig.emailIsOn != derivedEmailIsOn {
                print("Has Changes in email is on")
                self.hasChanges = true
            } else if emailConfig.emailBody != self.emailBody {
                print("Has Changes In Email Body ")
                self.hasChanges = true
            } else if emailConfig.requirePhoto != self.requiresPhoto {
                self.hasChanges = true
            } else if savedCategorySettings != self.categorySettings {
                self.hasChanges = true
            } else {
                self.hasChanges = false
                print("Does Not Have Changes In Email Body")
            }
        } else {
            print("Email Config DNE")
        }
    }
    func resetChanges(){
        if let emailConfig = self.emailConfig {
            
            self.emailIsOn = emailConfig.emailIsOn
            self.emailBody = emailConfig.emailBody
            self.requiresPhoto = emailConfig.requirePhoto
            self.categorySettings = emailConfig.resolvedCategorySettings()
            
            self.hasChanges = false
        }
    }
    func updateCustomerConfig(companyId:String,customerEmailConfig:CustomerEmailConfiguration?,customer:Customer,emailIsOn:Bool) async throws {
        print("")
        self.isLoading = true

        var configId:String = UUID().uuidString
        if let config = customerEmailConfig {
            configId = config.id
            try await dataService.updateCustomerEmailConfig(companyId: companyId, customerEmailConfigId: config.id, emailIsOn: emailIsOn)
        } else {
            try await dataService.createCustomerEmailConfiguration(
                companyId: companyId,
                customerEmailConfig: CustomerEmailConfiguration(
                    id:configId,
                    customerId: customer.id,
                    emailIsOn: emailIsOn
                )
            )
        }
        // Re Get Customer Config
        let newCustomerConfig = try await dataService.getCustomerEmailConfigurationSettingDocument(companyId: companyId, id: configId)
        self.customerConfigList.removeAll(where: {$0.id == configId})
        self.customerConfigList.append(newCustomerConfig)
        print("Checking Config List")
        if self.customerConfigList.isEmpty {
            print("Config List is empty")
            self.allCustomersSelected = false
        } else {
            print("Config List is not empty")
            if self.customerConfigList.contains(where: {$0.emailIsOn == false}) {
                print("Any Customer Config List Does Not Contains Email Is On: False")
                self.allCustomersSelected = false
            } else {
                print("Any Customer Config List Contains Only Email Is On: True")
                self.allCustomersSelected = true
            }
        }
        self.isLoading = false
    }
    func updateAllCustomerEmailConfig(companyId:String,emailIsOn:Bool) async throws {
        print("")
        self.isLoading = true
        var isOn = emailIsOn
        print("All Customer Email Is on \(isOn)")
        isOn.toggle()
        print("New Email Is on \(isOn)")

        self.allCustomersSelected.toggle()

        for customer in customers {
            print("Customer \(customer.firstName) \(customer.lastName)")
            if let emailConfig = self.customerConfigList.first(where: {$0.customerId == customer.id}) {
                print("Has Config ")
                if emailConfig.emailIsOn != isOn {
                    print("Customer Email Config is not same as \(isOn) - Updating")
                    try await dataService.updateCustomerEmailConfig(companyId: companyId, customerEmailConfigId: emailConfig.id, emailIsOn: isOn)
                } else {
                    print("Already same \(isOn)")

                }
            } else {
                print("Creating New Customer Config")
                try await dataService.createCustomerEmailConfiguration(
                    companyId: companyId,
                    customerEmailConfig: CustomerEmailConfiguration(
                        customerId: customer.id,
                        emailIsOn: isOn
                    )
                )
            }
        }
        self.customerConfigList = try await dataService.getCustomerEmailConfigurationSettings(companyId: companyId)
        print("Got Customer Config List \(customerConfigList.count)")
        if self.customerConfigList.isEmpty {
            print("Config List is empty")
            self.allCustomersSelected = false
        } else {
            print("Config List is not empty")
            if self.customerConfigList.contains(where: {$0.emailIsOn == false}) {
                print("Any Customer Config List Does Not Contains Email Is On: False")
                self.allCustomersSelected = false
            } else {
                print("Any Customer Config List Contains Only Email Is On: True")
                self.allCustomersSelected = true
            }
        }
        self.isLoading = false
    }
}
