    //
    //  JobDetailView.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 12/30/23.
    //
    //
    //DEVELOPER NOTES - I ADDED UPDATES TO THE FIRST PAGE (INFO) I NEED TO ADD UPDATES TO CUSTOMER, PARTS, SCHEDULE


import SwiftUI
struct JobDetailView: View {
    init(job:Job,dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: JobDetailViewModel(dataService: dataService))
        
        _job = State(wrappedValue: job)
    }
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var VM : JobDetailViewModel

    @State var job:Job

    @State var view:String = "Info"
    @State var viewList:[String] = ["Info","Customer","Tasks","Schedule"]
    @State var jobId:String = "J"
    
    
        //Body Of Water
    @State var jobTemplate:JobTemplate = JobTemplate(id: "", name: "")
    @State var serviceStopTemplate:ServiceStopTemplate = ServiceStopTemplate(id: "", name: "", type: "", typeImage: "", dateCreated: Date(), color: "")
    
    @State var dateCreated:Date = Date()
    @State var description:String = ""
    
    @State var operationStatus:JobOperationStatus = .estimatePending
    
    @State var billingStatus:JobBillingStatus = .draft
    
    @State var customer:Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        active: true,
        displayAsCompany: true,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
    
    @State var serviceLocations:[ServiceLocation] = []
    @State var serviceLocation:ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
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
    
    @State var bodyOfWaterList:[BodyOfWater] = []
    @State var bodyOfWater:BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "", 
        lastFilled: Date()
    )
    
    @State var equipmentList:[Equipment] = []
    @State var equipment:Equipment = Equipment(
        id: "",
        name: "",
        category: .filter,
        make: "",
        model: "",
        dateInstalled: Date(),
        status: .operational,
        needsService: true,
        notes: "",
        customerName: "",
        customerId: "",
        serviceLocationId: "",
        bodyOfWaterId: "", 
        isActive: true
    )
    
    @State var admin:CompanyUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .contractor)
    @State var tech:DBUser = DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: "")
    
    @State var serviceStopIds:[String] = []
    
    @State var installationParts:[WODBItem] = []
    @State var installationPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @State var showInstallationParts:Bool = false
    @State var pvcParts:[WODBItem] = []
    @State var pvcPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @State var showpvcParts:Bool = false
    @State var electricalParts:[WODBItem] = []
    @State var electricalPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @State var showelectricalParts:Bool = false
    @State var chemicals:[WODBItem] = []
    @State var chemical:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @State var showchemicals:Bool = false
    @State var miscParts:[WODBItem] = []
    @State var miscPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @State var showmiscParts:Bool = false
    
    
    @State var rate:String = "0"
    @State var laborCost:String = "0"
    @State var showCustomerSelector:Bool = false
    @State var showPurchasedItemSelector:Bool = false
    
    
    @State var showBodyOfWaterSheet:Bool = false
    
    @State var showTreeSheet:Bool = false
    @State var showBushSheet:Bool = false
    @State var showDeleteConfirmation:Bool = false
        //Service Stop
    @State var showAddNewServiceStop:Bool = false
    @State var serviceDate:Date = Date()
    @State var includeReadings:Bool = false
    @State var includeDosages:Bool = false
    @State var checkList:[String] = []
    @State var duration:String = "0"
    @State var serviceStopDescription:String = "0"
    
    @State var serviceStopList:[ServiceStop] = []
    @State var workingJob:Job? = nil
    @State var isLoading:Bool = false
    
    @State var bodyOfWaterPicker:Bool = false
    @State var equipmentPicker:Bool = false
    @State var showCostBreakDown:Bool = false
    

    @State var showDeletePartConfirmation:Bool = false
    @State var partToDelete:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @State var categoryToDeleteFrom:String = ""
    @State var showInfoOptions:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if !VM.isEdit {
                    HStack{
                        ForEach(VM.viewOptionList,id: \.self){ datum in
                            if view == datum {
                                Text(datum)
//                                    .font(.footnote)
                                    .modifier(SubmitButtonModifier())
                                
                            } else {
                                let index = (VM.viewOptionList.firstIndex(where: {$0 == datum}) ?? 0)
                                let selectedIndex = (VM.viewOptionList.firstIndex(where: {$0 == view}) ?? 0)
                                
                                Button(action: {
                                    view = datum
                                }, label: {
                                    
                                    if index > selectedIndex {
                                        Text(datum)
//                                            .font(.footnote)
                                            .modifier(ListButtonModifier())
                                    } else {
                                        Text(datum)
//                                            .font(.footnote)
                                            .modifier(FadedGreenButtonModifier())
                                    }
                                })
                            }
                        }
                    }
                    .font(.footnote)
                    .fontDesign(.monospaced)
                    .frame(maxWidth: .infinity)
                } else {
                    Rectangle()
                        .foregroundColor(Color.poolGreen)
                        .frame(height: 30)
                        .overlay(
                            HStack{
                                Spacer()
                                Text("Editing")
                                Spacer()
                            }
                        )
                }
                switch view {
                    case "Info":
                        if VM.isEdit {
                            editInfo
                        } else {
                            info
                        }
                        if VM.isEdit {
                            Button(action: {
                                VM.isEdit.toggle()
                            }, label: {
                                Text("Cancel")
                            })
                        }
                    case "Tasks":
                        if VM.isEdit {
                            editTaskView
                            
                        } else {
                            taskView
                        }
                    case "Shopping":
                        if VM.isEdit {
                            Button(action: {
                                VM.isEdit.toggle()
                            }, label: {
                                Text("Cancel")
                            })
                        } else {
                            shoppingListView
                        }
                        
                    case "Schedule":
                        if VM.isEdit {
                            Button(action: {
                                VM.isEdit.toggle()
                            }, label: {
                                Text("Cancel")
                            })
                        } else {
                            schedule
                        }
                    default:
                        info
                }
                
            }
        }

        .navigationTitle("Job Id: \(job.internalId)")
        .navigationBarTitleDisplayMode(.inline)
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            
            do {
                if let company = masterDataManager.currentCompany {
                    workingJob = job
                    dateCreated = job.dateCreated
                    
                    description = job.description
                    operationStatus = job.operationStatus
                    billingStatus = job.billingStatus
                    customer.id = job.customerId
                    customer.firstName = job.customerName
                    
                    serviceStopIds = job.serviceStopIds
                    admin.id = job.adminId
                    admin.userName = job.adminName
                    laborCost = String(job.laborCost)
                    print(job.rate)
                    rate = String(job.rate)
                    print(rate)
                    
                    try await VM.onLoad(
                        companyId: company.id,
                        serviceLocationId: job.serviceLocationId,
                        job: job
                    )
                }
            } catch {
                print("")
                print("Job - task - [JobDetailView]")
                print(error)
                print("")
            }
        }
        .onChange(of: masterDataManager.selectedJob, perform: { job1 in
            Task {
                
                do {
                    if let company = masterDataManager.currentCompany,let job = job1 {
                        workingJob = job
                        dateCreated = job.dateCreated
                        jobTemplate.name = job.type
                        
                        description = job.description
                        operationStatus = job.operationStatus
                        billingStatus = job.billingStatus
                        customer.id = job.customerId
                        customer.firstName = job.customerName
                        
                        serviceStopIds = job.serviceStopIds
                        admin.id = job.adminId
                        admin.userName = job.adminName
                        rate = String(job.rate)
                        laborCost = String(job.laborCost)
                        
                        try await VM.onLoad(companyId: company.id, serviceLocationId: job.serviceLocationId, job: job)
                        
                        try await VM.getPurchaseCost(companyId: company.id, purchaseIds: job.purchasedItemsIds ?? [])
                    }
                } catch {
                    
                    print("")
                    print("Job - masterDataManager.selectedJob - [JobDetailView]")
                    print(error)
                    print("")
                }
                
            }
            
        })
        .onChange(of: jobTemplate, perform: { template in
            rate = template.rate ?? "0"
        })
        .alert(isPresented:$showDeleteConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(VM.alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    Task{
                        if let company = masterDataManager.currentCompany{
                            do {
                                try await VM.delete(
                                    companyId: company.id,
                                    jobId: job.id,
                                    serviceStopIds: job.serviceStopIds,
                                    laborContractIds: job.laborContractIds
                                )
                                VM.alertMessage = "Deleted"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch {
                                print(error)
                            }
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: customer, perform: { cus in
            Task{
                do {
                    if let company = masterDataManager.currentCompany {
                        if cus.id != "" {
                            try await VM.onChangeOfCustomer(companyId: company.id, customerId: cus.id)
                        }
                    }
                } catch {
                    print("")
                    print("Job - customer - [JobDetailView]")
                    print(error)
                    print("")
                }
            }
        })
        
        .onChange(of: serviceLocation, perform: { loc in
            Task{
                do {
                    if let company = masterDataManager.currentCompany {
                        if loc.id != "" {
                            try await VM.onChangeOfServiceLocation(companyId: company.id, serviceLocation: loc)
                        }
                    }
                } catch {
                    print("")
                    print("Job - serviceLocation - [JobDetailView]")
                    print(error)
                    print("")
                }
            }
        })
        .onChange(of: bodyOfWater,perform: {BOW in
            Task{
                do {
                    if let company = masterDataManager.currentCompany {
                        if BOW.id != "" {
                            try await VM.onChangeOfBodyOfWater(companyId: company.id, bodyOfWater: BOW)
                        }
                    }
                } catch {
                    print("")
                    print("Job - bodyOfWater - [JobDetailView]")
                    print(error)
                    print("")
                }
            }
        })
        .onChange(of: VM.description, perform: { description in
                Task{
                    do {
                        print(description)
                        if let company = masterDataManager.currentCompany {
                                try await VM.updateDescription(companyId: company.id, jobId: job.id)
                        }
                    } catch {
                        print("")
                        print(error)
                        print("")
                    }
                }
        })
    }

}

extension JobDetailView {
    
    var info: some View {
        ZStack{
            ScrollView {
                VStack(alignment: .leading,spacing: 8){
                    
                    if job.otherCompany {
                        if let currentCompany = masterDataManager.currentCompany {
                            if currentCompany.id == job.receiverId {
                                HStack{
                                    if let otherCompany = VM.senderCompany {
                                        CompanyCardView(company: otherCompany)
                                    }
                                    Spacer()
                                    if let laborContract = VM.laborContract {
                                        NavigationLink(value: Route.laborContractDetailView(dataService: dataService, contract: laborContract), label: {
                                            Text("Labor Contract Details")
                                                .modifier(RedLinkModifier())
                                        })
                                    }
                                }
                            }
                        }
                    }
                    HStack{
                        Text("Date Created: ")
                            .bold(true)
                        Spacer()
                        Text(fullDate(date: job.dateCreated))
                    }
                    HStack{
                        Text("Customer: ")
                            .bold(true)
                        Spacer()
                        Text("\(customer.firstName) \(customer.lastName)")
                    }
                    HStack{
                        Text("Admin: ")
                            .bold(true)
                        Spacer()
                        Text(job.adminName)
                        
                        Button(action: {
                            view = "Info"
                        }, label: {
                            Image(systemName: "pencil")
                        })
                    }
                    HStack{
                        Text("Operation: ")
                            .bold(true)
                        Spacer()
                        Text(job.operationStatus.rawValue)
                    }
                    HStack{
                        Text("Billing: ")
                            .bold(true)
                        Spacer()
                        Text(job.billingStatus.rawValue)
                    }
                    HStack{
                        Text("Address: ")
                            .bold(true)
                        Spacer()
                        if let location = VM.serviceLocation {
                            Text("\(location.address.streetAddress)")
                        }
                    }
                    HStack{
                        Text("Description:")
                            .bold(true)
                        Spacer()
                    }
                    TextField(
                        "Description",
                        text: $VM.description,
                        axis:.vertical
                    )
                    .lineLimit(5, reservesSpace: true)
                    .modifier(PlainTextFieldModifier())
                    VStack(alignment: .leading){
                        Rectangle()
                            .frame(height: 2)
                        VStack(alignment: .leading,spacing: 10){
                            HStack{
                                Text("Estimate Break down")
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    VM.showEstimate.toggle()
                                }, label: {
                                    HStack{
                                        if VM.showEstimate {
                                            
                                            Text("Hide Estiamte")
                                            Image(systemName: "chevron.up")
                                        } else {
                                            Text("Show Estiamte")
                                            Image(systemName: "chevron.down")
                                        }
                                    }
                                    .modifier(RedLinkModifier())
                                })
                                
                            }
                            if VM.showEstimate {
                                VStack(alignment:.leading){
                                    HStack{
                                        if let rate = Double(rate), let laborCost = Double(laborCost), let shoppingListCost = VM.shoppingListCost, let shoppingListPrice = VM.shoppingListPrice {
                                            Text("Ideal Rate")
                                            Spacer()
                                            Text("\(Double((2.4*laborCost) + shoppingListPrice)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                        }
                                    }
                                    Divider()
                                    HStack{
                                        if let updatedLaborCost = VM.updatedLaborCost {
                                            Button(action: {
                                                VM.showLaborCostBreakDown.toggle()
                                            }, label: {
                                                Image(systemName: "chevron.down")
                                            })
                                            .sheet(isPresented: $VM.showLaborCostBreakDown, content: {
                                                VStack(alignment:.leading){
                                                    ForEach(VM.jobTaskList){ item in
                                                        HStack{
                                                            Text("\(String(VM.jobTaskList.firstIndex(where:{$0 == item})! + 1)). \(item.name) ")
                                                            Spacer()
                                                            Text("\(Double(item.contractedRate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                                        }
                                                    }
                                                }
                                                .padding(8)
                                                .presentationDetents([.medium])
                                            })
                                            Text("Labor Cost: ")
                                            Spacer()
                                            Text("\(updatedLaborCost/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                        }
                                    }
                                    .padding(8)
                                    HStack{
                                        if let employeeLaborCost = VM.employeeLaborCost {
                                            Text("\(displayMinAsMinAndHour(min: Int(VM.employeeHours*60))) x \(VM.employeeHourlyRate/100, format: .currency(code: "USD").precision(.fractionLength(2))) = \(employeeLaborCost/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(.horizontal,16)
                                    HStack{
                                        if let shoppingListCost = VM.shoppingListCost {
                                            Button(action: {
                                                VM.showMaterialCostBreakDown.toggle()
                                            }, label: {
                                                Image(systemName: "chevron.down")
                                            })
                                            .sheet(isPresented: $VM.showMaterialCostBreakDown, content: {
                                                VStack(alignment:.leading){
                                                    ForEach(VM.shoppingItemList){ item in
                                                        HStack{
                                                            Text("\(String(VM.shoppingItemList.firstIndex(where:{$0 == item})! + 1 )). \(item.name)")
                                                            Spacer()
                                                            Text("1")
                                                        }
                                                    }
                                                }
                                                .padding(8)
                                                .presentationDetents([.medium])
                                            })
                                            Text("Estimated Material Cost: ")
                                            Spacer()
                                            Text("\(shoppingListCost/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                        }
                                    }
                                    .padding(8)
                                    Divider()
                                    HStack{
                                        if let laborCost = Double(laborCost), let shoppingListCost = VM.shoppingListCost, let shoppingListPrice = VM.shoppingListPrice {
                                            Text("Ideal Profit: ")
                                            Spacer()
                                            let idealRate = Double((2.4*laborCost) + shoppingListPrice)
                                            Text("\((idealRate-laborCost-shoppingListCost)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                        }
                                    }
                                }
                                .padding(.leading,16)
                                
                                .fontDesign(.monospaced)
                            }
                        }
                        Rectangle()
                            .frame(height: 2)
                        VStack(alignment: .leading,spacing: 10){
                            Text("Cost Review")
                                .font(.headline)
                            VStack{
                                HStack{
                                    if let rate = Double(rate){
                                        Text("Rate")
                                        Spacer()
                                        Text("\(rate/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                    }
                                }
                                Divider()
                                HStack{
                                    if let updatedLaborCost = VM.updatedLaborCost {
                                        Text("Labor Cost: ")
                                        Spacer()
                                        Text("\(updatedLaborCost/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                    }
                                }
                                HStack{
                                    if let shoppingListCost = VM.shoppingListCost {
                                        Text("Estimated Material Cost: ")
                                        Spacer()
                                        Text("\(shoppingListCost/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                    }
                                }
                                Divider()
                                HStack{
                                    if let rate = Double(rate), let laborCost = Double(laborCost),let shoppingListCost = VM.shoppingListCost {
                                        Text("Profit: ")
                                        Spacer()
                                        Text("\((rate-laborCost-shoppingListCost)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                    }
                                }
                            }
                            .padding(.leading,16)
//                            if let purchase = VM.purchasedPartCost, let rate = Double(rate), let labor = Double(laborCost) {
//                                
//                                VStack{
//                                    HStack{
//                                        Text("Rate")
//                                        Spacer()
//                                        Text("\(Double(rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
//
//                                    }
//                                    HStack{
//                                        Text("Ideal Rate: ")
//                                        Spacer()
//                                        Text("\(Double(2.4*(purchase + labor))/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
//
//                                    }
//                                    .font(.footnote)
//                                    .padding(.horizontal,8)
//                                    HStack{
//                                        Text("Total Cost: ")
//                                        Spacer()
//                                        Text("\(Double(purchase + labor)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
//
//                                    }
//                                    HStack{
//                                        Spacer()
//                                        Button(action: {
//                                            self.showCostBreakDown.toggle()
//                                        }, label: {
//                                            
//                                            Text("Show Break Down")
//                                                .font(.footnote)
//                                            Image(systemName: showCostBreakDown ? "chevron.down" : "chevron.forward")
//                                        })
//                                    }
//                                    if showCostBreakDown {
//                                        
//                                        HStack{
//                                            Text("Labor Cost: ")
//                                            Spacer()
//                                            Text("\(Double(laborCost)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
//
//                                        }
//                                        
//                                        HStack{
//                                            Text("Purchases Cost: ")
//                                            Spacer()
//                                            Text("$\(String(format:"%2.f",purchase))")
//                                            
//                                        }
//                                    }
//                                    Rectangle()
//                                        .frame(height: 1)
//                                    HStack{
//                                        Text("Profit: ")
//                                        Spacer()
//                                        Text("$\(String(format:"%2.f",rate - purchase - labor))")
//                                    }
//                                }
//                                .padding(.leading,16)
//                            }
                        }
                    }

                }
                .padding(5)
                Text("s")
                    .padding(16)
                    .foregroundColor(Color.clear)
            }
            VStack{
                Spacer()
                if job.otherCompany {
                    if let currentCompany = masterDataManager.currentCompany {
                        if currentCompany.id == job.senderId {
                            senderCompanyBillingInfo
                        } else {
                            //If you get sent JOb from other company you  dont get to send invoices and estiamtes
                            HStack{
                                
                                Button(action: {
                                    Task{
                                        do {
                                            if let company = masterDataManager.currentCompany {
                                                try await VM.markJobAsFinished(
                                                    companyId: company.id,
                                                    job: job
                                                )
                                                VM.alertMessage = "Finished"
                                                VM.showAlert.toggle()
                                            }
                                        } catch {
                                            print("")
                                            print("Job - markJobAsFinished - [JobDetailView]")
                                            print(error)
                                            print("")
                                        }
                                    }
                                }, label: {
                                    if VM.operationStatus == .finished {
                                        Text("Finished")
                                            .modifier(SubmitButtonModifier())
                                    } else {
                                        Text("Finish")
                                            .modifier(ListButtonModifier())
                                    }
                                })
                            }
                        }
                    }
                } else {
                    senderCompanyBillingInfo
                }
            }
        }
        .padding(5)
    }
    var senderCompanyBillingInfo: some View{
            HStack{
                Button(action: {
                    showInfoOptions.toggle()
                }, label: {
                    Text("More")
                        .modifier(ListButtonModifier())
                })
                .sheet(isPresented: $showInfoOptions, onDismiss: {
                    
                }, content: {
                    VStack{
                        Button(action: {
                            Task{
                                do {
                                    if let company = masterDataManager.currentCompany {
                                        try await VM.sendEstiamteToCustomer(
                                            companyId: company.id,
                                            job: job
                                        )
                                        VM.alertMessage = "Estimate Sent To Customer"
                                        VM.showAlert.toggle()
                                    }
                                } catch {
                                    print("")
                                    print("Job - sendEstiamteToCustomer - [JobDetailView]")
                                    print(error)
                                    print("")
                                }
                            }
                        }, label: {
                            Text("Send Estimate")
                        })
                        .modifier(ListButtonModifier())
                        
                        Button(action: {
                            VM.isPresentingMarkEstiamteAsAccepted.toggle()
                        }, label: {
                            Text("Mark Estimate As Accepted")
                        })
                        .modifier(ListButtonModifier())
                        .sheet(isPresented: $VM.isPresentingMarkEstiamteAsAccepted, onDismiss: {
                            
                        }, content: {
                            manualEstimateAcceptInfo
                        })
                        
                        Button(action: {
                            Task{
                                do {
                                    if let company = masterDataManager.currentCompany {
                                        if VM.billingStatus == .invoiced {
                                            if let type = VM.invoiceType {
                                                if type == .manual {
                                                    print("Resetting Invoice Info")
                                                    try await VM.markJobAsNotInvoiced(
                                                        companyId: company.id,
                                                        job: job
                                                    )
                                                    VM.alertMessage = "Invoiced"
                                                    VM.showAlert.toggle()
                                                }
                                            }
                                        } else {
                                            print("Presenting Invoice Info")
                                            VM.isPresentingMarkJobAsInvoiced.toggle()
                                        }
                                    }
                                }
                            }
                        }, label: {
                            if VM.billingStatus == .invoiced {
                                HStack{
                                    Text("Invoiced")
                                }
                                .modifier(SubmitButtonModifier())
                            } else {
                                HStack{
                                    Text("Mark As Invoiced")
                                }
                                .modifier(ListButtonModifier())
                            }
                        })
                        .sheet(isPresented: $VM.isPresentingMarkJobAsInvoiced, onDismiss: {
                        }, content: {
                            manualInvoicedInfo
                        })
                        
                        Button(action: {
                            showDeleteConfirmation.toggle()
                        }, label: {
                            Text("Delete")
                                .modifier(DismissButtonModifier())
                        })
                    }
                    .presentationDetents([.fraction(0.4),.large])
                })
                Spacer()
                if VM.operationStatus == .finished {
                    Button(action: {
                        print("Show Accepted Invoice Details")
                        
                    }, label: {
                            if VM.billingStatus == .invoiced {
                                HStack{
                                    
                                    Text("Invoiced")
                                    Image(systemName: "checkmark.circle.fill")

                                }
                                    .modifier(SubmitButtonModifier())
                            } else {
                                HStack{
                                    Text("Invoice")
                                    Image(systemName: "circle")
                                }
                                .modifier(ListButtonModifier())
                            }
                    })
                }
                Button(action: {
                    Task{
                        do {
                            if let company = masterDataManager.currentCompany {
                                if VM.operationStatus == .finished {
                                    try await VM.markJobAsUnFinished(
                                        companyId: company.id,
                                        job: job
                                    )
                                    VM.alertMessage = "Finished"
                                    VM.showAlert.toggle()
                                } else {
                                    
                                    try await VM.markJobAsFinished(
                                        companyId: company.id,
                                        job: job
                                    )
                                    VM.alertMessage = "Finished"
                                    VM.showAlert.toggle()
                                }
                            }
                        } catch {
                            print("")
                            print("Job - markJobAsFinished - [JobDetailView]")
                            print(error)
                            print("")
                        }
                    }
                }, label: {
                    if VM.operationStatus == .finished {
                            HStack{
                                Text("Finished")
                                Image(systemName: "checkmark.circle.fill")
                            }
                            .modifier(SubmitButtonModifier())
                    } else {
                        HStack{
                            Text("Finish")
                            Image(systemName: "circle")
                        }
                            .modifier(ListButtonModifier())
                    }
                })
            }
            .padding(.horizontal,8)
    }
    var editInfo: some View {
        ZStack{
            ScrollView {
                VStack(alignment: .leading,spacing: 8){
                    HStack{
                        Text("Admin")
                            .bold(true)
                        Picker("Admin", selection: $admin) {
                            Text("Pick Admin").tag( CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .contractor))
                            ForEach(VM.techList){ user in
                                Text(user.userName).tag(user)
                            }
                        }
                    }
                    HStack{
                        Text("Job Type")
                            .bold(true)
                        Picker("Job Type", selection: $jobTemplate) {
                            Text("Pick Type").tag(JobTemplate(id: "", name: ""))
                            ForEach(VM.jobTemplates){ template in
                                Text(template.name).tag(template)
                            }
                        }
                    }
                    HStack{
                        Text("Operation: ")
                            .bold(true)
                        Picker("Operation", selection: $operationStatus) {
                            ForEach(JobOperationStatus.allCases,id: \.self){ status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                    }
                    HStack{
                        Text("Billing: ")
                            .bold(true)
                        Picker("Billing", selection: $billingStatus) {
                            ForEach(JobBillingStatus.allCases,id: \.self){ status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                    }
                    
                    HStack{
                        Text("Rate")
                            .bold(true)
                        TextField(
                            "Rate",
                            text: $rate
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        .padding(5)
                    }
                    HStack{
                        Text("Labor Cost")
                            .bold(true)
                        TextField(
                            "laborCost",
                            text: $laborCost
                        )
                        .padding(3)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                        .padding(5)
                    }
                    HStack{
                        Text("Description")
                            .bold(true)
                        Spacer()
                    }
                    TextField(
                        "Description",
                        text: $description,
                        axis:.vertical
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    .padding(5)
                    
                    
                }
                .padding(5)
            }
            
            VStack{
                Spacer()
                HStack{
                    Button(action: {
                        print("Build in Save Changes")
                        Task{
                            if let company = masterDataManager.currentCompany{
                                do {
                                    if admin.id != job.adminId || admin.userName != job.adminName ||  jobTemplate.name != job.type || operationStatus != job.operationStatus || billingStatus != job.billingStatus  || String(job.rate) != rate || laborCost != String(job.laborCost) || description != job.description{
                                        try await VM.updateJobInfo(companyId:company.id,updatingJob: job,
                                                                      admin: admin,
                                                                      jobTemplate: jobTemplate,
                                                                      operationStatus: operationStatus,
                                                                      billingStatus: billingStatus,
                                                                      rate: rate,
                                                                      laborCost: laborCost,
                                                                      description: description)
                                    } else {
                                        
                                        VM.alertMessage = "No Change Made"
                                        print(VM.alertMessage)
                                        VM.showAlert = true
                                    }
                                } catch {
                                    
                                    print("Error Updating Job")
                                }
                            }
                        }
                    }, label: {
                        Text("Save Changes")
                    })
                    .modifier(SubmitButtonModifier())
                    Spacer()
                        //Check For Changes in Admin, jobTemplate, operationStatus, billingStatus, Rate, laborRate, and Description
                    Button(action: {
                        VM.isEdit = false
                        admin.id = job.adminId
                        admin.userName = job.adminName
                        
                        jobTemplate.name = job.type
                        
                        operationStatus = job.operationStatus
                        billingStatus = job.billingStatus
                        rate = String(job.rate)
                        laborCost = String(job.laborCost)
                        description = job.description
                    }, label: {
                        Text("Cancel")
                            .modifier(DeleteButtonModifier())
                    })
                }
                .padding(.horizontal,8)
            }
        }
        .padding(5)
        .cornerRadius(5)
    }
    
    var taskView: some View {
        ZStack{
            ScrollView {
                VStack(alignment: .center,spacing: 8){
                    Text("Task List")
                        .font(.headline)
                    ForEach(VM.jobTaskList){ task in
                            //                        Text("\(task.name)")
                        HStack{
                            JobTaskCardView(dataService: dataService, jobId: job.id, jobTask: task)
                        }
                    }
                    HStack{
                        Button(action: {
                            VM.isAddTask.toggle()
                        }, label: {
                            HStack{
                                Spacer()
                                Text("New Task")
                                Spacer()
                            }
                            .modifier(AddButtonModifier())
                        })
                        .sheet(isPresented: $VM.isAddTask, onDismiss: {
                            Task {
                                do {
                                    if let company = masterDataManager.currentCompany {
                                        try await VM.onDismissAddTaskSheet(companyId: company.id, serviceLocationId: job.serviceLocationId, jobId: job.id)
                                    }
                                } catch {
                                    print("")
                                    print("Dismiss Add Task Sheet Error")
                                    print(error)
                                    print("")
                                }
                            }
                        }, content: {
                            AddNewTaskToJob(dataService: dataService, jobId: job.id, taskTypes: VM.taskTypes,customerId: job.customerId,serviceLocationId: job.serviceLocationId)
                                .presentationDetents([.medium,.large])
                        })
                        Button(action: {
                            VM.isAddTaskGroup.toggle()
                        }, label: {
                            HStack{
                                Spacer()
                                Text("Task Group")
                                Spacer()
                            }
                            .modifier(AddButtonModifier())
                        })
                        .sheet(isPresented: $VM.isAddTaskGroup,
                               onDismiss: {
                            if let company = masterDataManager.currentCompany {
                                VM.addNewTasks(companyId: company.id, jobId: job.id)
                            }
                            
                        },
                               content: {
                            TaskGroupPickerView(dataService: dataService, tasks: $VM.taskGroupItems)
                        })
                    }
                }
                .padding(5)
            }
            VStack{
                Spacer()
                HStack{
                    Button(action: {
                        VM.isEdit = true
                    }, label: {
                        Text("Edit")
                            .modifier(SubmitButtonModifier())
                    })
                    
                    Spacer()
                    Button(action: {
                        view = "Shopping List"
                    }, label: {
                        Text("Next")
                            .modifier(AddButtonModifier())
                    })
                }
                .padding(.horizontal,8)
                .background(Color.listColor)
            }
        }
        .padding(5)
    }
    
    var editTaskView: some View {
        ZStack{
            ScrollView {
                VStack(alignment: .center,spacing: 8){
                    Text("Task List")
                        .font(.headline)
                    HStack{
                        Button(action: {
                            VM.isAddTask.toggle()
                        }, label: {
                            HStack{
                                Spacer()
                                Text("Add New Task")
                                Spacer()
                            }
                            .modifier(AddButtonModifier())
                        })
                        .sheet(isPresented: $VM.isAddTask, onDismiss: {
                            Task {
                                do {
                                    if let company = masterDataManager.currentCompany {
                                        try await VM.onDismissAddTaskSheet(companyId: company.id, serviceLocationId: job.serviceLocationId, jobId: job.id)
                                    }
                                } catch {
                                    print("")
                                    print("Dismiss Add Task Sheet Error")
                                    print(error)
                                    print("")
                                }
                            }
                        }, content: {
                            AddNewTaskToJob(dataService: dataService, jobId: job.id, taskTypes: VM.taskTypes,customerId: job.customerId,serviceLocationId: job.serviceLocationId)
                                .presentationDetents([.medium])
                        })
                        Spacer()
                    }
                    
                    ForEach(VM.jobTaskList){ task in
                            //                        Text("\(task.name)")
                        HStack{
                            Image(systemName: "square.and.pencil")
                                .modifier(SubmitButtonModifier())
                            JobTaskCardView(dataService: dataService, jobId: job.id, jobTask: task)
                            Button(action: {
                                Task{
                                    if let currentCompany = masterDataManager.currentCompany {
                                        do {
                                            try await VM.deleteJobTaskItem(companyId: currentCompany.id, jobId: jobId, task: task)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            }, label: {
                                Image(systemName: "trash.fill")
                                    .modifier(DismissButtonModifier())
                            })
                            .padding(4)
                        }
                    }
                }
                .padding(5)
            }
            VStack{
                Spacer()
                HStack{
                    Button(action: {
                        VM.isEdit.toggle()
                    }, label: {
                        Text("Save")
                            .modifier(SubmitButtonModifier())
                    })
                    Spacer()
                    Button(action: {
                        VM.isEdit.toggle()
                    }, label: {
                        Text("Cancel")
                            .modifier(DeleteButtonModifier())
                    })
                }
                .padding(.horizontal,8)
            }
        }
        .padding(5)
    }
    
    var shoppingListView: some View {
        ZStack{
            ScrollView {
                VStack(alignment: .leading,spacing: 8){
                    Text("Shopping List")
                    ForEach(VM.shoppingItemList){ item in
                        ShoppingListItemCardView(dataService: dataService, shoppingListItem: item)
                    }
                    HStack{
                        Button(action: {
                            VM.isAddShoppingList.toggle()
                        }, label: {
                            HStack{
                                Spacer()
                                Text("Add New Shopping List Item")
                                Spacer()
                            }
                            .modifier(AddButtonModifier())
                        })
                        .sheet(isPresented: $VM.isAddShoppingList){
                            AddNewShoppingListItemToJob(dataService: dataService, job: job)
                                .presentationDetents([.medium,.large])
                        }
                        Spacer()
                    }
                }
                .padding(5)
            }
            VStack{
                Spacer()
                HStack{
                    Button(action: {
                        VM.isEdit = true
                    }, label: {
                        Text("Edit")
                            .modifier(SubmitButtonModifier())
                    })
                    Spacer()
                    Button(action: {
                        view = "Schedule"
                    }, label: {
                        Text("Next")
                            .modifier(AddButtonModifier())
                    })
                }
                .padding(.horizontal,8)
            }
        }
        .padding(5)
    }
    
    var schedule: some View {
        ZStack{
            ScrollView{
                VStack(alignment: .center,spacing: 8){
                    Text("Service Stops")
                        .font(.headline)
                    Divider()
                    if VM.serviceStops.isEmpty {
                        ForEach(VM.serviceStopIds, id:\.self) { id in
                            ZStack {
                                if id != "" {
                                    ServiceStopIdCardView(dataService: dataService, serviceStopId: id)
                                }
                                ProgressView()
                            }
                        }
                    } else {
                        ForEach(VM.serviceStops) { stop in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.serviceStop(serviceStop: stop, dataService: dataService), label: {
                                    ServiceStopIdCardView(dataService: dataService, serviceStopId: stop.id)
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedCategory = .serviceStops
                                    masterDataManager.selectedID = stop.id
                                    masterDataManager.selectedServiceStops = stop
                                    
                                }, label: {
                                    ServiceStopIdCardView(dataService: dataService, serviceStopId: stop.id)
                                })
                            }
                        }
                    }
                    Button(action: {
                        VM.isPresentServiceStop.toggle()
                    }, label: {
                        Text("Schedule Service Stop")
                            .modifier(AddButtonModifier())
                    })
                    .sheet(isPresented: $VM.isPresentServiceStop,
                           onDismiss: {
                                Task{
                                    if let currentCompany = masterDataManager.currentCompany {
                                        do {
                                            try await VM.onDismissOfScheduleServiceStop(
                                                companyId: currentCompany.id,
                                                serviceLocationId: job.serviceLocationId,
                                                job: job
                                            )
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            },
                           content: {
                        ScheduleServiceStopView(
                            dataService: dataService,
                            job: job,
                            customerId: job.customerId,
                            customerName: job.customerName,
                            serviceLocationId: job.serviceLocationId,
                            description: job.description,
                            jobTaskList: VM.jobTaskList
                        )
                        .presentationDetents([.medium, .large])
                    })
                    Rectangle()
                        .frame(height: 1)
                    Text("Labor Contracts")
                        .font(.headline)
                    Divider()
                    if VM.laborContracts.isEmpty {
                        ForEach(VM.laborContractIds, id:\.self) { id in
                            ZStack {
                                if id != "" {
                                    
                                    LaborContractIdCardView(dataService: dataService, laborContractId: id)
                                }
                                ProgressView()
                            }
                        }
                    } else {
                        ForEach(VM.laborContracts) { laborContract in
                            NavigationLink(value: Route.laborContractDetailView(dataService: dataService, contract: laborContract), label: {
                                LaborContractCardView(laborContract: laborContract)
                            })
                        }
                    }
                    
                    Button(action: {
                        VM.isPresentLaborContract.toggle()
                        print("Presenting CreateNewLaborContractView")
                    }, label: {
                        Text("Offer New Labor Contract")
                            .modifier(AddButtonModifier())
                    })
                    
                    .sheet(isPresented: $VM.isPresentLaborContract,
                           onDismiss: {
                        Task{
                            if let currentCompany = masterDataManager.currentCompany {
                                do {
                                    try await VM.onDismissOfOfferLaborContract(
                                        companyId: currentCompany.id,
                                        serviceLocationId: job.serviceLocationId,
                                        job: job
                                    )
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    },
                           content: {
                        CreateNewLaborContractView(
                            dataService: dataService,
                            jobId: job.id,
                            customerId: job.customerId,
                            customerName: job.customerName,
                            serviceLocationId: job.serviceLocationId,
                            description: job.description,
                            jobTaskList: VM.jobTaskList
                        )
                        .presentationDetents([.medium,.large])
                    })
                    Rectangle()
                        .frame(height: 1)
                        //----------------------------------------
                        //Add Back in During Roll out of Phase 2
                        //----------------------------------------
//                    Text("Post To Job Board")
//                        .font(.headline)
//                        .background(Color.pink)
//                    Divider()
//                    ForEach(VM.laborContractIds, id: \.self) { id in
//                        Text(id)
//                    }
//                    Button(action: {
//                        VM.isPresentLaborContract.toggle()
//                    }, label: {
//                        Text("Post To Job Board")
//                            .modifier(AddButtonModifier())
//                    })
//                    .sheet(isPresented: $VM.isPresentLaborContract){
//                        
//                        CreateNewLaborContractView(
//                            dataService: dataService,
//                            jobId: job.id,
//                            customerId: job.customerId,
//                            customerName: job.customerName,
//                            serviceLocationId: job.serviceLocationId,
//                            description: job.description,
//                            jobTaskList: VM.jobTaskList
//                        )
//                        .presentationDetents([.medium,.large])
//                    }
                }
                .padding(5)
            }
            VStack{
                Spacer()
                HStack{
                    Button(action: {
                        VM.isEdit = true
                    }, label: {
                        Text("Edit")
                            .modifier(SubmitButtonModifier())
                    })
                    Spacer()
                    Button(action: {
                        view = "Info"
                    }, label: {
                        Text("Review")
                            .modifier(AddButtonModifier())
                    })
                }
                .padding(.horizontal,8)
            }
        }
        .padding(5)
    }
    
    var review: some View {
        ZStack{
            ScrollView {
            }
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    Button(action: {
                        showDeleteConfirmation.toggle()
                    }, label: {
                        Text("Delete")
                            .modifier(DismissButtonModifier())
                    })
                }
            }
        }
        .padding(5)
        .cornerRadius(5)
    }
    var manualEstimateAcceptInfo: some View {
        VStack{
            HStack{
                Text("Date Accepted :")
                    .bold(true)
                DatePicker(selection: $VM.estiamtedAcceptedDate, displayedComponents: .date) {
                }
            }
            HStack{
                Text("Who Accepted: ")
                    .bold(true)
                TextField(
                    "Who Accepted",
                    text: $VM.estimateAcceptedNotes
                )
                .modifier(PlainTextFieldModifier())
            }
            Button(action: {
                Task{
                    do {
                        if let company = masterDataManager.currentCompany {
                            if VM.estimateAcceptedNotes != "" {
                                try await VM.markEstimateAsAccepted(
                                    companyId: company.id,
                                    job: job
                                )
                                VM.alertMessage = "Successfully Accapted"
                                VM.showAlert.toggle()
                                VM.isPresentingMarkEstiamteAsAccepted.toggle()
                            } else {
                                VM.alertMessage = "Please Provide Notes"
                                VM.showAlert.toggle()
                            }
                        }
                    } catch {
                        print("")
                        print("Job - markEstimateAsAccepted - [JobDetailView]")
                        print(error)
                        print("")
                    }
                }
            }, label: {
                Text("Mark As Accepted")
                    .modifier(SubmitButtonModifier())
            })
        }
        .padding(8)
    }
    
    var manualInvoicedInfo: some View {
        VStack{
            HStack{
                Text("Invoice Ref: ")
                    .bold(true)
                TextField(
                    "Refrence Number...",
                    text: $VM.invoiceRef
                )
                .modifier(PlainTextFieldModifier())
            }
            HStack{
                Text("Invoice Notes: ")
                    .bold(true)
                TextField(
                    "notes...",
                    text: $VM.invoiceNotes
                )
                .modifier(PlainTextFieldModifier())
            }
            Button(action: {
                Task{
                    do {
                        if let company = masterDataManager.currentCompany {
                            if VM.billingStatus != .invoiced && VM.billingStatus != .paid {
                                try await VM.markJobAsInvoiced(
                                    companyId: company.id,
                                    job: job
                                )
                                VM.alertMessage = "Invoiced"
                                VM.showAlert.toggle()
                                VM.isPresentingMarkJobAsInvoiced.toggle()
                            }
                        }
                    } catch {
                        print("")
                        print("Job - markJobAsFinished - [JobDetailView]")
                        print(error)
                        print("")
                    }
                }
            }, label: {
                Text("Mark As Accepted")
                    .modifier(SubmitButtonModifier())
            })
        }
        .padding(8)
    }
}
