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
    @Published var showCompanyUserPicker:Bool = false

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
        recurringServiceStopIdList: [],
        isActive: false,
        lastBilled: Date()
    )
    @Published  var selectedLaborContract:ReccuringLaborContract = ReccuringLaborContract(
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
        isActive: true,
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
    @Published private(set) var submitButtonDisabled : Bool = false
    @Published var isLoading : Bool = false

    //Received Varaibles From DataService
    @Published private(set) var companyTechList: [CompanyUser] = []

    @Published private(set) var termsTemplate:TermsTemplate? = nil
    @Published private(set) var contractTerm:ContractTerms? = nil
    @Published private(set) var customersList: [Customer] = []
    @Published private(set) var displayCustomerList: [Customer] = []
    @Published private(set) var termsTemplateList:[TermsTemplate] = []
    @Published private(set) var contractTermList:[ContractTerms] = []
    @Published private(set) var laborContractList:[ReccuringLaborContract] = []
    @Published private(set) var serviceLocationList: [ServiceLocation] = []

    @Published private(set) var laborContractRecurringWorkList:[LaborContractRecurringWork] = []
    @Published private(set) var jobTemplates: [JobTemplate] = []

    

    
    func onLoadGenerateRouteFromLaborContract(companyId:String,laborContractId:String) async throws {
        self.laborContractRecurringWorkList = try await dataService.getLaborContractRecurringWorkList(companyId: companyId, laborContractId: laborContractId)
        
        if let first = self.laborContractRecurringWorkList.first {
            self.selectedRecurringWork = first
            self.frequency = first.frequency
        }
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

            var recurrignServiceStopIdList:[IdInfo] = []
            for day in self.selectedDays {
                if self.selectedRecurringWork.customerId != "" || self.selectedRecurringWork.serviceLocationId != "" || self.selectedLaborContract.senderId != ""{
                    self.location = try await dataService.getServiceLocationById(companyId: self.selectedLaborContract.senderId, locationId: self.selectedRecurringWork.serviceLocationId)
                } else {
                    print("self.selectedRecurringWork.customerId \(self.selectedRecurringWork.customerId)")
                    print("self.selectedRecurringWork.serviceLocationId \(self.selectedRecurringWork.serviceLocationId)")
                    print("self.selectedLaborContract.senderId \(self.selectedLaborContract.senderId)")

                }
                //Add Recurring Service Stop to Receiving Company
                let rssCount = try await dataService.getRecurringServiceStopCount(companyId: companyId)
                let internalRSSID = "RSS" + String(rssCount)
                let RSSID = try await addNewRecurringServiceStopFromLaborContractHelper(
                    companyId: companyId,
                    recurringServiceStop: RecurringServiceStop(
                        id: "comp_rss_" + UUID().uuidString,
                        internalId: internalRSSID,
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
                        daysOfWeek: day,
                        description: self.description,
                        lastCreated: Date(),
                        serviceLocationId: self.selectedRecurringWork.serviceLocationId,
                        estimatedTime: self.estimatedTime,
                        otherCompany: true,
                        laborContractId: self.selectedLaborContract.id,
                        contractedCompanyId: self.selectedLaborContract.senderId,
                        mainCompanyId: self.selectedLaborContract.senderId
                    ),
                    laborContract: self.selectedLaborContract
                )
                if let RSSID {
                    recurrignServiceStopIdList.append(IdInfo(id: RSSID, internalId: internalRSSID))
                }
            }
            
            //Create New Labor Contract Recurring Work
            let newWorkReceivingCompany = LaborContractRecurringWork(
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
                recurringServiceStopIdList: recurrignServiceStopIdList,
                isActive: true,
                lastBilled: Date()
            )
            try await dataService.updateLaborContractIsActive(contractId: selectedLaborContract.id, isActive: true)
            //Upload to Receiver database
            try await dataService.addLaborContractRecurringWork(companyId: companyId, laborContractId: self.selectedLaborContract.id, laborContractRecurringWork: newWorkReceivingCompany)
            
            //Upload to Sender database
            try await dataService.addLaborContractRecurringWork(companyId: self.selectedLaborContract.senderId, laborContractId: self.selectedLaborContract.id, laborContractRecurringWork: newWorkReceivingCompany)

            self.laborContractRecurringWorkList[index] = newWorkReceivingCompany
            
            self.selectedRecurringWork = newWorkReceivingCompany
        }
    }
    func addNewRecurringServiceStopFromLaborContractHelper(companyId:String,recurringServiceStop:RecurringServiceStop,laborContract:ReccuringLaborContract) async throws ->(String?) {        print("addNewRecurringServiceStop - [DataService]")
        let startDate:Date = recurringServiceStop.startDate
        
        guard let endDate:Date = recurringServiceStop.endDate else {
            return nil
        }
        let noEndDate:Bool = recurringServiceStop.noEndDate
        //initial Creating of the Route
        

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"//String Day of the Week
        let dateDisplayFornmatter = DateFormatter()
        dateDisplayFornmatter.dateFormat = "MM-dd-yy"//this your string date format
        let numberOfWeek = DateFormatter()
        numberOfWeek.dateFormat = "EEEEE"//Number Day of the Week
        var pushRecurring = recurringServiceStop
        pushRecurring.mainCompanyId = laborContract.senderId
        
        switch recurringServiceStop.frequency{
        case .daily:
            print("Making Stops Daily")
            //Daily
        case .weekDay:
            //skipped weekends
            print("Making Stops on Week days")
            
        case .weekly:
            //weekly
            print("Making Stops Weekly")
            try await helpCreateWeeklyRecurringRoute(
                companyId: companyId,
                recurringServiceStop: pushRecurring,
                noEndDate: noEndDate,
                startDate: startDate,
                endDate: endDate,
                senderCompanyId: laborContract.senderId,
                receiverCompanyId: laborContract.receiverId
            )
            
        case .biWeekly:
            //weekly
            print("Making Stops Bi Weekly")
            
            
        case .monthly:
            //Monthly
            print("Making Stops Monthly")

        case .yearly:
            print("Developer Make Daily")
        }
        print("Finished Creating Recurring Route and Returning recurringServiceStopId >>\(pushRecurring.id)")

        return pushRecurring.id
    }
        //Weeekly
        func helpCreateWeeklyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                            noEndDate:Bool,startDate:Date,endDate:Date,senderCompanyId:String,receiverCompanyId:String) async throws{
            print("Create Weekly Recurring Route helper Function")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"//String Day of the Week
            let dateDisplayFornmatter = DateFormatter()
            dateDisplayFornmatter.dateFormat = "MM-dd-yy"//this your string date format
            let numberOfWeek = DateFormatter()
            numberOfWeek.dateFormat = "EEEEE"//Number Day of the Week
            
            var functionalStartDate:Date = Date()
            var functionalEndDate:Date = Date()
            let calendar = Calendar.current
            var lastCreated:Date = Date()
            
            var counter :Int = 0
            
            if noEndDate {
                print("No End Date")
                functionalStartDate = startDate
                functionalEndDate = calendar.date(byAdding: .day, value: 28, to: functionalStartDate)!
            } else {
                print("Has End Date")
                
                functionalStartDate = startDate
                functionalEndDate = endDate
            }
            let daysBetween = Calendar.current.dateComponents([.day], from: functionalStartDate, to: functionalEndDate).day!
            print("Creating standard Recurring service stop on ")
            print("Day \(recurringServiceStop.daysOfWeek)")
            print("\(daysBetween) Days Between")
            
            while counter < daysBetween {
                //Check to Make sure the day you are adding is the proper day.
                
                
                print("\(counter) / \(daysBetween)")
                var pushDate = Date()
                let startDayOfWeek = String(dateDisplayFornmatter.string(from:startDate))
                //Check if the start day is the day of the week you would like to be adding.
                if recurringServiceStop.daysOfWeek.contains(startDayOfWeek) {
                    pushDate = Calendar.current.date(byAdding: .day, value: counter, to: startDate)!
                } else {
                    //Get the actual start Day
                        
                        var serviceDayOfWeekAsNumber = 0
                        switch recurringServiceStop.daysOfWeek {
                        case "Sunday":
                            serviceDayOfWeekAsNumber = 1
                        case "Monday":
                            serviceDayOfWeekAsNumber = 2
                        case "Tuesday":
                            serviceDayOfWeekAsNumber = 3
                        case "Wednesday":
                            serviceDayOfWeekAsNumber = 4
                        case "Thursday":
                            serviceDayOfWeekAsNumber = 5
                        case "Friday":
                            serviceDayOfWeekAsNumber = 6
                        case "Saturday":
                            serviceDayOfWeekAsNumber = 7
                        default:
                            print("Error No days of Week Selected")
                            throw FireBasePublish.unableToPublish
                        }
                        var startDayOfWeekAsNumber = 0  //This ONly Works For Monday
                        switch dateFormatter.string(from:startDate) {
                        case "Sunday":
                            startDayOfWeekAsNumber = 1
                        case "Monday":
                            startDayOfWeekAsNumber = 2
                        case "Tuesday":
                            startDayOfWeekAsNumber = 3
                        case "Wednesday":
                            startDayOfWeekAsNumber = 4
                        case "Thursday":
                            startDayOfWeekAsNumber = 5
                        case "Friday":
                            startDayOfWeekAsNumber = 6
                        case "Saturday":
                            startDayOfWeekAsNumber = 7
                        default:
                            print("Error No days of Week Selected For Start Date")
                            throw FireBasePublish.unableToPublish
                        }
                        let difference = serviceDayOfWeekAsNumber - startDayOfWeekAsNumber
                        print("startDayOfWeekAsNumber \(startDayOfWeekAsNumber)")
                        print("serviceDayOfWeekAsNumber \(serviceDayOfWeekAsNumber)")
                        print("difference \(difference)")
                        
                        if difference >= 0 {
                            
                            pushDate = Calendar.current.date(byAdding: .day, value: difference + counter, to: startDate)!
                        } else {
                            pushDate = Calendar.current.date(byAdding: .day, value: difference + counter + 7, to: startDate)!
                        }
                }
                print("Create Stops on \(fullDate(date: pushDate)) - \(dateFormatter.string(from:pushDate)) - days Of Week \(recurringServiceStop.daysOfWeek)")
                
                let senderSSId = try await SettingsManager.shared.getServiceOrderCount(companyId: senderCompanyId)
                
                let receiverSSId = try await SettingsManager.shared.getServiceOrderCount(companyId: receiverCompanyId)

                var otherCompany = false
                if recurringServiceStop.otherCompany {
                    otherCompany = true
                } else {
                    otherCompany = true
                }
                
                let id = "comp_ss_" + UUID().uuidString
                let senderServiceStop = ServiceStop(
                    id: id,
                    internalId: "SS" + String(senderSSId),
                    companyId: companyId,
                    companyName: "",
                    customerId: recurringServiceStop.customerId,
                    customerName: recurringServiceStop.customerName,
                    address: recurringServiceStop.address,
                    dateCreated: Date(),
                    serviceDate: pushDate,
                    startTime: nil,
                    endTime: nil,
                    duration: 0,
                    estimatedDuration: Int(recurringServiceStop.estimatedTime) ?? 15,
                    tech: recurringServiceStop.tech,
                    techId: recurringServiceStop.techId,
                    recurringServiceStopId: recurringServiceStop.id,
                    description: recurringServiceStop.description,
                    serviceLocationId: recurringServiceStop.serviceLocationId,
                    typeId: recurringServiceStop.typeId,
                    type: recurringServiceStop.type,
                    typeImage: recurringServiceStop.typeImage,
                    jobId: "",
                    jobName: "",
                    operationStatus: .notFinished,
                    billingStatus: .notInvoiced,
                    includeReadings: true,
                    includeDosages: true,
                    otherCompany: otherCompany,
                    laborContractId: recurringServiceStop.laborContractId ?? "",
                    contractedCompanyId: recurringServiceStop.contractedCompanyId ?? "",
                    mainCompanyId: senderCompanyId,
                    isInvoiced: false
                )
                
                let receiverServiceStop = ServiceStop(
                    id: id,
                    internalId: "SS" + String(receiverSSId),
                    companyId: companyId,
                    companyName: "",
                    customerId: recurringServiceStop.customerId,
                    customerName: recurringServiceStop.customerName,
                    address: recurringServiceStop.address,
                    dateCreated: Date(),
                    serviceDate: pushDate,
                    startTime: nil,
                    endTime: nil,
                    duration: 0,
                    estimatedDuration: Int(recurringServiceStop.estimatedTime) ?? 15,
                    tech: recurringServiceStop.tech,
                    techId: recurringServiceStop.techId,
                    recurringServiceStopId: recurringServiceStop.id,
                    description: recurringServiceStop.description,
                    serviceLocationId: recurringServiceStop.serviceLocationId,
                    typeId: recurringServiceStop.typeId,
                    type: recurringServiceStop.type,
                    typeImage: recurringServiceStop.typeImage,
                    jobId: "",
                    jobName: "",
                    operationStatus: .notFinished,
                    billingStatus: .notInvoiced,
                    includeReadings: true,
                    includeDosages: true,
                    otherCompany: otherCompany,
                    laborContractId: recurringServiceStop.laborContractId ?? "",
                    contractedCompanyId: recurringServiceStop.contractedCompanyId ?? "",
                    mainCompanyId: senderCompanyId,
                    isInvoiced: false
                )
                
                //One For the receiver
                try await dataService.uploadServiceStop(companyId: companyId, serviceStop: receiverServiceStop)
                
                //One for the sender
                try await dataService.uploadServiceStop(companyId: senderCompanyId, serviceStop: senderServiceStop)
                
                if pushDate > lastCreated {
                    lastCreated = pushDate
                }
                counter = counter + 7
            }
            print("Last Created: \(String(dateDisplayFornmatter.string(from:lastCreated)))")
            var pushRecurring = recurringServiceStop
            pushRecurring.lastCreated = lastCreated
            print("Adding Recurring Service Stop with id - \(pushRecurring.id) helpCreateWeeklyRecurringRoute - [GenerateRouteFromLaborContractViewModel]")
            
            //One For the receiver
            try await dataService.uploadRecurringServiceStop(companyId: companyId, recurringServiceStop: pushRecurring)
            //One for the sender
            try await dataService.uploadRecurringServiceStop(companyId: senderCompanyId, recurringServiceStop: pushRecurring)

        }
        
    func onLoadNewReucrringFromLaborContract(companyId:String,laborContract:ReccuringLaborContract,laborContractRecurringWork:LaborContractRecurringWork) async throws {
        print("")
        print("On Load New Reucrring From Labor Contract")
        self.companyTechList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: CompanyUserStatus.active.rawValue)
        if self.companyTechList.count != 0 {
            self.techEntity = self.companyTechList.first!
        }
        //Get Customer Info From Company that sent Labor Contract
        let customers = try await dataService.getAllCustomers(companyId: laborContract.senderId)
        print("Customers Received From \(laborContract.senderName) \(customers.count)")
        self.customersList = customers.filter({$0.id == laborContractRecurringWork.customerId})
        print("Customers Filtered From \(laborContractRecurringWork.customerId) \(customersList.count)")
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
