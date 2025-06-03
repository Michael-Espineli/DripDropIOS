//
//  AddNewContractViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/29/24.
//

import Foundation
@MainActor
final class AddNewContractViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //Functional Variables
    @Published private(set) var formDisabled: Bool = true
    @Published var presentNewCustomer: Bool = false
    @Published var showWheels: Bool = false

    @Published private(set) var customerList:[Customer] = []
    @Published private(set) var filteredCustomerList:[Customer] = []

    @Published var customerSearchTerm:String = ""

    //Form Variables
    @Published private(set) var count: Int? = nil
    @Published var selectedCustomer: Customer = Customer(
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
    @Published var dateToAccept:Date = Date()
    @Published var daysToAccept:String = ""

    @Published var startDate:Date = Date()

    @Published var rate:String = "100"
    @Published var rateType:RecurringContractRateType = .perMonth

    @Published var laborType:RecurringContractLaborType = .perStop
    @Published var laborRate:String = "15"

    @Published var chemType:RecurringContractChemType = .withChems
    @Published var cleaningType:RecurringContractCleaningPlan = .basic

    @Published var repairType:BillingType = .billedSeparately
    @Published var repairMax:String = "500"

    @Published var filterType:BillingType = .included
    @Published var serviceFrequency:RecurringContractServiceFrequency = .perWeek
    @Published var serviceFrequencyAmount:String = "1"

    @Published var terms:String = ""
    
    @Published var internalNotes:String = ""
    @Published var externalNotes:String = ""
    
    @Published var status:RecurringContractStatus = .pending
    @Published var atWill = false
    @Published var serviceLocationIds:[String] = []

    @Published var errorMessage = ""
    @Published var showAlert = false
    @Published var isLoading = false

    //OnLoad
    func onLoad(companyId:String) async throws {
        self.customerList = try await dataService.getAllCustomers(companyId: companyId)
    }
    //Create
    func uploadContractWithValidation(companyId:String) async throws {
        if !isLoading {
            self.formDisabled = true
            self.isLoading = true
                //DEVELOPER BUILD VALIDATION
            guard let repairMaxDouble = Double(repairMax) else {
                throw FireBasePublish.unableToPublish
            }
            let repairMaxInt = Int(repairMaxDouble*100)
            
            guard let laborRateDouble = Double(laborRate) else {
                throw FireBasePublish.unableToPublish
            }
            let laborRateInt = Int(laborRateDouble*100)
            
            guard let rateDouble = Double(rate) else {
                throw FireBasePublish.unableToPublish
            }
            let rateInt = Int(rateDouble*100)
            
            guard let serviceFrequencyAmountInt = Int(self.serviceFrequencyAmount) else {
                throw FireBasePublish.unableToPublish
            }
            var fullName = ""
            if self.selectedCustomer.displayAsCompany {
                fullName = self.selectedCustomer.company ?? "Company"
            } else {
                fullName = selectedCustomer.firstName + " " + selectedCustomer.lastName
            }
            let contract:RecurringContract = RecurringContract(
                id: "rc_" + UUID().uuidString,
                chemType: self.chemType,
                cleaningPlan: self.cleaningType,
                repairType: self.repairType,
                repairAmountMax: repairMaxInt,
                filterServiceType: self.filterType,
                companyId: companyId,
                companyName: "",
                internalCustomerId: self.selectedCustomer.id,
                internalCustomerName: fullName,
                clientId: "",
                email: self.selectedCustomer.email,
                dateSent: Date(),
                dateToAccept: self.dateToAccept,
                laborRate: laborRateInt,
                laborType: self.laborType,
                locationCount: self.serviceLocationIds.count,
                internalNotes: self.internalNotes,
                rate: rateInt,
                rateType: self.rateType,
                serviceLocationIds: self.serviceLocationIds,
                status: self.status,
                terms: self.terms,
                priceId: "",
                productId: "",
                stripeCustomerId: "",
                connectedAccountId: "",
                subscriptionId: "",
                serviceFrequency: self.serviceFrequency,
                serviceFrequencyAmount: serviceFrequencyAmountInt,
                companySetUp: false,
                atWill: self.atWill,
                externalNotes: self.externalNotes
            )
            try await dataService.uploadContact(companyId: companyId, contract: contract)
            self.errorMessage = "Successfully Uploaded"
            self.showAlert = true
            self.isLoading = false
        }
    }
    //Functions
    func checkContractForm(){
        if self.selectedCustomer.id == "" || self.selectedCustomer.firstName == "" || self.selectedCustomer.lastName == ""  || self.rate == "" || self.laborRate == "" || repairMax == ""{
            self.formDisabled = true
        } else {
            self.formDisabled = false
        }
    }
    func filterCustomerList() {
        //very facncy Search Bar
        if self.customerSearchTerm != "" {
            var filteredListOfCustomers:[Customer] = []
            for customer in self.customerList {
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
                if customer.firstName.lowercased().contains(self.customerSearchTerm.lowercased()) || customer.lastName.lowercased().contains(self.customerSearchTerm.lowercased()) || replacedPhone6.lowercased().contains(self.customerSearchTerm.lowercased()) || customer.email.lowercased().contains(self.customerSearchTerm.lowercased()) || address.lowercased().contains(self.customerSearchTerm.lowercased()) || company.lowercased().contains(self.customerSearchTerm.lowercased()) || fullName.lowercased().contains(self.customerSearchTerm.lowercased()){
                    filteredListOfCustomers.append(customer)
                }
            }
            self.filteredCustomerList = filteredListOfCustomers
        }
    }
}
