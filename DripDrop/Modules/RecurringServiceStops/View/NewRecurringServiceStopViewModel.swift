//
//  NewRecurringServiceStopViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/14/24.
//
import Foundation
import SwiftUI

@MainActor
final class NewRecurringServiceStopViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //NewRecurringServiceStopFromLaborContract FORM
    @Published var startDate:Date = Date()
    @Published var endDate:Date = Date()
    
    @Published var noEndDate:Bool = true
    @Published var frequency:LaborContractFrequency = .daily
    @Published var timesPerFrequency:Int = 1
    

    @Published var description:String = "description"
    @Published var estimatedTime:String = "15"
    @Published var customersList: [Customer] = []
    @Published var filteredCustomerList: [Customer] = []
    @Published var customerSearch:String = ""
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = "Error"
    @Published var days:[String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    @Published var selectedDays:String = ""
    
    @Published var customer: Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "0",
            latitude: 0,
            longitude: 0
        ),
        active: false,
        displayAsCompany: false,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
    @Published var location:ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "0",
            latitude: 0,
            longitude: 0
        ),
        gateCode: "",
        mainContact: Contact(
            id: "",
            name: "",
            phoneNumber: "",
            email: ""
        ),
        bodiesOfWaterId: [],
        rateType: "",
        laborType: "",
        chemicalCost: "",
        laborCost: "",
        rate: "",
        customerId: "",
        customerName: "",
        preText: false
    )
    @Published var techEntity:CompanyUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .employee)
    @Published var jobType:JobTemplate = JobTemplate(id: "",
                                                 name: "Job Template",
                                                 type: "",
                                                 typeImage: "",
                                                 dateCreated: Date(),
                                                 rate: "",
                                                 color: "")
    //Data Service Provided
    @Published private(set) var customers: [Customer] = []
    @Published private(set) var displayCustomers: [Customer] = []

    @Published private(set) var serviceLocations: [ServiceLocation] = []
    @Published private(set) var companyTechList: [CompanyUser] = []
    @Published private(set) var jobTemplates: [JobTemplate] = []

    func onLoadNewReucrringFromLaborContract(companyId:String,laborContract:ReccuringLaborContract,laborContractRecurringWork:LaborContractRecurringWork) async throws {
        print("")
        print("onLoadNewReucrringFromLaborContract")
        self.companyTechList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: CompanyUserStatus.active.rawValue)
        if self.companyTechList.count != 0 {
            self.techEntity = self.companyTechList.first!
        }
        let customers = try await dataService.getAllCustomers(companyId: laborContract.senderId)
        self.customers = customers.filter({$0.id == laborContractRecurringWork.customerId})
        self.displayCustomers = self.customers
        if !self.customers.isEmpty {
            self.customer = self.customers.first!
        } else {
            print("Customers Empty")
        }
        
        let locations = try await dataService.getAllCustomerServiceLocationsId(companyId: laborContract.senderId, customerId: laborContractRecurringWork.customerId)
        self.serviceLocations = locations.filter({$0.id == laborContractRecurringWork.serviceLocationId})
        if self.serviceLocations.count != 0 {
            self.location = self.serviceLocations.first!
        } else {
            print("Location is empty")
        }
        
        let templates = try await SettingsManager.shared.getAllWorkOrderTemplates(companyId: laborContract.senderId)
        self.jobTemplates = templates.filter({$0.id == laborContractRecurringWork.jobTemplateId})
        if self.jobTemplates.count != 0 {
            self.jobType = self.jobTemplates.first!
        } else {
            print("Job Template is empty")

        }
        

        
 
    }
    func onLoadNewRecurring(companyId:String) async throws {
        self.customers = try await dataService.getAllCustomers(companyId: companyId)
        self.companyTechList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: CompanyUserStatus.active.rawValue)
        self.jobTemplates = try await SettingsManager.shared.getAllWorkOrderTemplates(companyId: companyId)
    }

    func filterCustomerList() {
        //very facncy Search Bar
        if self.customerSearch != "" {
            var filteredListOfCustomers:[Customer] = []
            for customer in customers {
                let phone = customer.phoneNumber ?? "0"
                let replacedPhone1 = phone.replacingOccurrences(of: ".", with: "")
                let replacedPhone2 = replacedPhone1.replacingOccurrences(of: "-", with: "")
                let replacedPhone3 = replacedPhone2.replacingOccurrences(of: " ", with: "")
                let replacedPhone4 = replacedPhone3.replacingOccurrences(of: ".", with: "")
                let replacedPhone5 = replacedPhone4.replacingOccurrences(of: "(", with: "")
                let replacedPhone6 = replacedPhone5.replacingOccurrences(of: ")", with: "")
                
                let address = (customer.billingAddress.streetAddress ) + " " + (customer.billingAddress.city ) + " " + (customer.billingAddress.state ) + " " + (customer.billingAddress.zip )
                let company:String = customer.company ?? "0"
                let fullName = customer.firstName + " " + customer.lastName
                if customer.firstName.lowercased().contains(self.customerSearch.lowercased()) || customer.lastName.lowercased().contains(self.customerSearch.lowercased()) || replacedPhone6.lowercased().contains(self.customerSearch.lowercased()) || customer.email.lowercased().contains(self.customerSearch.lowercased()) || address.lowercased().contains(self.customerSearch.lowercased()) || company.lowercased().contains(self.customerSearch.lowercased()) || fullName.lowercased().contains(self.customerSearch.lowercased()){
                    filteredListOfCustomers.append(customer)
                }
            }
            self.displayCustomers = filteredListOfCustomers
        } else {
            self.displayCustomers = self.customers

        }
    }
    func addNewRecurringServiceStop(companyId: String) async throws {

        //Validation Before Main Function
        print("DEVELOPER ADD SOME VALIDATION TO ADD NEW RECURRING SERVICE STOP")
        if jobType.id == "" {
            self.alertMessage = "No Job Selected"
            print(self.alertMessage)
            self.showAlert = true
            return
        }
        let jobId = jobType.name
        if jobType.name == "" {
            self.alertMessage = "No Job title Available, selected different job or update job title"
            print(self.alertMessage)
            self.showAlert = true
            return
        }
        let jobName = jobType.name
        let jobImage = jobType.typeImage
        
        if customer.id == "" || customer.firstName == "" ||  customer.lastName == ""{
            self.alertMessage = "No Customer Selected"
            print(self.alertMessage)
            self.showAlert = true
            return
        }
        let customerName = customer.firstName + " " + customer.lastName
        let customerId = customer.id
        if location.id == "" || location.nickName == "" ||  location.address.streetAddress == ""{
            
            self.alertMessage = "No Location Selected"
            print(self.alertMessage)
            self.showAlert = true
            return
        }
        let locationId = location.id
        let address = location.address
        if techEntity.id == "" {
            self.alertMessage = "No Tech Selected"
            print(self.alertMessage)
            self.showAlert = true
            return
        }
       
        let techFullName = techEntity.userName
        let techId = techEntity.userId
        var pushSelectedDays = selectedDays

        if selectedDays.isEmpty {
            pushSelectedDays = "Friday"
        }

        let pushEndDate = noEndDate
        let pushFrequency = frequency
        let pushTimesPerFrequency = timesPerFrequency
        let pushDescription = description
        let pushEstimatedTime = estimatedTime
        let daysOfWeek = pushSelectedDays
        let rssCount = try await dataService.getRecurringServiceStopCount(companyId: companyId)
        let recurringServiceStop = try await dataService.addNewRecurringServiceStop(companyId: companyId, recurringServiceStop: RecurringServiceStop(
            id: UUID().uuidString,
            internalId: "RSS" + String(rssCount),
            type: jobName,
            typeId: jobId ,
            typeImage: jobImage ?? "",
            customerName: customerName,
            customerId: customerId,
            address: address,
            tech: techFullName,
            techId: techId,
            dateCreated: Date(),
            startDate: Date(), 
            endDate: nil,
            noEndDate: pushEndDate,
            frequency: pushFrequency,
            daysOfWeek: pushSelectedDays,
            description: pushDescription,
            lastCreated: Date(),
            serviceLocationId:locationId,
            estimatedTime: pushEstimatedTime,
            otherCompany:true,
            laborContractId:"",
            contractedCompanyId:""
        ))
  
    }
}
