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
struct CompanyEmailConfiguration:Identifiable,Codable {
    var id : String = UUID().uuidString
    var emailIsOn:Bool
    var emailBody : String
    var requirePhoto : Bool
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
    @Published private(set) var emailConfig:CompanyEmailConfiguration? = nil
    @Published private(set) var customerConfigList:[CustomerEmailConfiguration] = []
    @Published private(set) var customers:[Customer] = []
    @Published var hasChanges:Bool = false

    func onLoad(companyId:String) async throws {
        self.isLoading = true

        // get Standard Company Email Body
        self.emailConfig = try await dataService.getEmailConfigurationSettings(companyId: companyId)
        print("Got Email Config")
        if let emailConfig = self.emailConfig {
            self.emailIsOn = emailConfig.emailIsOn
            self.emailBody = emailConfig.emailBody
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
            if emailConfig.emailIsOn != self.emailIsOn {
                try await dataService.updateEmailConfigurationIsOn(companyId: companyId, emailIsOn: self.emailIsOn)
            }
            if emailConfig.emailBody != self.emailBody {
                try await dataService.updateEmailConfigurationBody(companyId: companyId, newBody: self.emailBody)
            }
            if emailConfig.requirePhoto != self.requiresPhoto {
                try await dataService.updateEmailConfigurationRequirePhoto(companyId: companyId, requirePhoto: self.requiresPhoto)
            }
            self.emailConfig = try await dataService.getEmailConfigurationSettings(companyId: companyId)
            print("Got Email Config")
            if let emailConfig = self.emailConfig {
                self.emailIsOn = emailConfig.emailIsOn
                self.emailBody = emailConfig.emailBody
            }
        }
        self.isLoading = false
    }
    func checkChanges(){
        print("Check Changes")
        if let emailConfig = self.emailConfig {
            if emailConfig.emailIsOn != self.emailIsOn {
                self.hasChanges = true
            } else {
                self.hasChanges = false
            }
            if emailConfig.emailBody != self.emailBody {
                self.hasChanges = true
            } else {
                self.hasChanges = false
            }
        } else {
            print("Email Config is false")
        }
    }
    func resetChanges(){
        if let emailConfig = self.emailConfig {
            
            self.emailIsOn = emailConfig.emailIsOn
            self.emailBody = emailConfig.emailBody
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
