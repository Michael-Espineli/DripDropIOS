//
//  GenerateRouteFromLaborContractViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/17/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class GenerateRouteFromLaborContractViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //View Side Variables
    @Published var startDate:Date = Date()
    @Published var endDate:Date = Date()
    
    @Published var noEndDate:Bool = true
    @Published var generateRouteFromLaborContract:Bool = false
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = ""
    @Published var customerSearch:String = ""
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
    @Published var techEntity:CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .employee
    )
    @Published var selectedRecurringWork:LaborContractRecurringWork = LaborContractRecurringWork(
        id: "",
        customerId: "",
        customerName: "",
        serviceLocationId: "",
        serviceLocationName: "",
        jobTemplateId: "",
        jobTemplateName: "",
        rate: 0,
        laborType: .hour,
        frequency: .daily,
        timesPerFrequency: 0,
        timesPerFrequencySetUp: 0,
        routeSetUp: false,
        recurringServiceStopIdList: []
    )
    @Published  var selectedLaborContract:RepeatingLaborContract = RepeatingLaborContract(
        id: "",
        senderName: "",
        senderId: "",
        senderAcceptance: false,
        receiverName: "",
        receiverId: "",
        receiverAcceptance: false,
        dateSent: Date(),
        lastDateToAccept: Date(),
        dateAccepted: Date(),
        startDate: Date(),
        endDate: Date(),
        status: .accepted,
        terms: [],
        notes: "",
        atWill: false,
        contractLengthInMonths: 0
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
    
    @Published var description:String = "description"
    @Published var estimatedTime:String = "15"
    @Published var frequency:LaborContractFrequency = .daily
    @Published var days:[String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    @Published var selectedDays:[String] = []
    @Published var jobType:JobTemplate = JobTemplate(id: "",
                                                 name: "Job Template",
                                                 type: "",
                                                 typeImage: "",
                                                 dateCreated: Date(),
                                                 rate: "",
                                                 color: "")
    @Published private(set) var submitButtonDisabled:Bool = false

    //Received Varaibles From DataService
    @Published private(set) var companyTechList: [CompanyUser] = []

    @Published private(set) var termsTemplate:TermsTemplate? = nil
    @Published private(set) var contractTerm:ContractTerms? = nil
    @Published private(set) var customersList: [Customer] = []
    @Published private(set) var displayCustomerList: [Customer] = []
    @Published private(set) var termsTemplateList:[TermsTemplate] = []
    @Published private(set) var contractTermList:[ContractTerms] = []
    @Published private(set) var laborContractList:[RepeatingLaborContract] = []
    @Published private(set) var serviceLocationList: [ServiceLocation] = []

    @Published private(set) var laborContractRecurringWorkList:[LaborContractRecurringWork] = []
    @Published private(set) var jobTemplates: [JobTemplate] = []

    

    
    func onLoadGenerateRouteFromLaborContract(companyId:String,laborContractId:String) async throws {
        self.laborContractRecurringWorkList = try await dataService.getLaborContractRecurringWork(companyId: companyId, laborContractId: laborContractId)
    }
    func generateRecurringStopFromRecurringWork(companyId:String) async throws {
        print("")
        print("Trying to Input generateRecurringStopFromRecurringWork")
        if self.selectedRecurringWork.id == "" {
            print("selectedRecurringWork ID is Empty")
            return
        }
        if self.selectedRecurringWork.routeSetUp {
            print("selectedRecurringWork is true")

            return
        }
        if self.selectedRecurringWork.timesPerFrequency == selectedRecurringWork.timesPerFrequencySetUp {
            print("selectedRecurringWork timesPerFrequency Equals timesPerFrequencySetUp")

            return
        }
         let index = self.laborContractRecurringWorkList.firstIndex(where: {$0.id == self.selectedRecurringWork.id})
        if let index {
            let times = selectedRecurringWork.timesPerFrequencySetUp + self.selectedDays.count
            var routeSetUp = false
            if times == selectedRecurringWork.timesPerFrequency {
                routeSetUp = true
            }
            print("timesPerFrequency \(selectedRecurringWork.timesPerFrequency)")
            print("timesPerFrequencySetUp \(selectedRecurringWork.timesPerFrequencySetUp)")

            print("times \(times)")
            //Update Labor Contract
            print("timesPerFrequencySetUp \(self.selectedRecurringWork)")

            var recurrignServiceStopIdList:[String] = []
            for day in self.selectedDays {
                if self.selectedRecurringWork.customerId != "" || self.selectedRecurringWork.serviceLocationId != "" || self.selectedLaborContract.senderId != ""{
                    self.location = try await dataService.getServiceLocationsCustomerAndLocationId(companyId: self.selectedLaborContract.senderId, customerId: self.selectedRecurringWork.customerId, locationId: self.selectedRecurringWork.serviceLocationId)
                } else {
                    print("self.selectedRecurringWork.customerId \(self.selectedRecurringWork.customerId)")
                    print("self.selectedRecurringWork.serviceLocationId \(self.selectedRecurringWork.serviceLocationId)")
                    print("self.selectedLaborContract.senderId \(self.selectedLaborContract.senderId)")

                }
                let RSSID = try await dataService.addNewRecurringServiceStop(
                    companyId: companyId,
                    recurringServiceStop: RecurringServiceStop(
                        id: UUID().uuidString,
                        type: self.jobType.name,
                        typeId: self.jobType.id,
                        typeImage: self.jobType.typeImage ?? "",
                        customerName: self.selectedRecurringWork.customerName,
                        customerId: self.selectedRecurringWork.customerId,
                        address: self.location.address, //DEVELOPER GET ADDRESS FOR RECURRING SERVICE STOP
                        tech: self.techEntity.userName,
                        techId: self.techEntity.userId,
                        dateCreated: Date(),
                        startDate: self.startDate,
                        endDate: self.endDate,
                        noEndDate: self.noEndDate,
                        frequency: self.selectedRecurringWork.frequency,
                        daysOfWeek: [day],
                        description: self.description,
                        lastCreated: Date(),
                        serviceLocationId: self.selectedRecurringWork.serviceLocationId,
                        estimatedTime: self.estimatedTime,
                        otherCompany: true,
                        laborContractId: self.selectedLaborContract.id,
                        contractedCompanyId: self.selectedLaborContract.senderId
                    )
                )
                if let RSSID {
                    recurrignServiceStopIdList.append(RSSID)
                }
            }
            //Create New Labor Contract
            let newWork = LaborContractRecurringWork(
                id: selectedRecurringWork.id,
                customerId: selectedRecurringWork.customerId,
                customerName: selectedRecurringWork.customerName,
                serviceLocationId: selectedRecurringWork.serviceLocationId,
                serviceLocationName: selectedRecurringWork.serviceLocationName,
                jobTemplateId: selectedRecurringWork.jobTemplateId,
                jobTemplateName: selectedRecurringWork.jobTemplateName,
                rate: selectedRecurringWork.rate,
                laborType: selectedRecurringWork.laborType,
                frequency: selectedRecurringWork.frequency,
                timesPerFrequency: selectedRecurringWork.timesPerFrequency,
                timesPerFrequencySetUp: times,
                routeSetUp: routeSetUp,
                recurringServiceStopIdList: recurrignServiceStopIdList
            )
            //Upload to Receiver database
            
            try await dataService.addLaborContractRecurringWork(companyId: companyId, laborContractId: self.selectedLaborContract.id, laborContractRecurringWork: newWork)
            //Upload to Sender database
            try await dataService.addLaborContractRecurringWork(companyId: self.selectedLaborContract.senderId, laborContractId: self.selectedLaborContract.id, laborContractRecurringWork: newWork)

            self.laborContractRecurringWorkList[index] = newWork
            
            self.selectedRecurringWork = newWork
        }
    }
    func onLoadNewReucrringFromLaborContract(companyId:String,laborContract:RepeatingLaborContract,laborContractRecurringWork:LaborContractRecurringWork) async throws {
        print("")
        print("onLoadNewReucrringFromLaborContract")
        self.companyTechList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: CompanyUserStatus.active.rawValue)
        if self.companyTechList.count != 0 {
            self.techEntity = self.companyTechList.first!
        }
        let customers = try await dataService.getAllCustomers(companyId: laborContract.senderId)
        self.customersList = customers.filter({$0.id == laborContractRecurringWork.customerId})
        self.displayCustomerList = self.customersList
        if !self.customersList.isEmpty {
            self.customer = self.customersList.first!
        } else {
            print("Customers Empty")
        }
        
        let locations = try await dataService.getAllCustomerServiceLocationsId(companyId: laborContract.senderId, customerId: laborContractRecurringWork.customerId)
        self.serviceLocationList = locations.filter({$0.id == laborContractRecurringWork.serviceLocationId})
        if self.serviceLocationList.count != 0 {
            self.location = self.serviceLocationList.first!
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
    func filterCustomerList() {
        //very facncy Search Bar
        if self.customerSearch != "" {
            var filteredListOfCustomers = BasicFunctions.shared.filterCustomerList(searchTerm: self.customerSearch, customers: self.customersList)
            self.displayCustomerList = filteredListOfCustomers
        } else {
            self.displayCustomerList = self.customersList

        }
    }
}
