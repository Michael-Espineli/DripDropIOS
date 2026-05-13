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
        preText: false,
        isActive: true
    )
    
    @State var bodyOfWaterList:[BodyOfWater] = []
    @State var bodyOfWater:BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "", 
        lastFilled: Date(),
        isActive: true
    )
    
    @State var equipmentList:[Equipment] = []
    @State var equipment:Equipment = Equipment(
        id: "",
        name: "",
        type: .filter,
        typeId: "",
        make: "",
        makeId: "",
        model: "",
        modelId: "",
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
    
    
    @State var rate: Int = 0
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(VM.viewOptionList, id: \.self) { datum in
                            if view == datum {
                                Text(datum)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Capsule().fill(Color.primary.opacity(0.14)))
                                    .overlay(Capsule().stroke(Color.primary.opacity(0.20), lineWidth: 1))
                            } else {
                                let index = (VM.viewOptionList.firstIndex(where: { $0 == datum }) ?? 0)
                                let selectedIndex = (VM.viewOptionList.firstIndex(where: { $0 == view }) ?? 0)

                                Button(action: { view = datum }, label: {
                                    Text(datum)
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            Capsule().fill(
                                                index > selectedIndex
                                                ? Color.primary.opacity(0.06)
                                                : Color.primary.opacity(0.03)
                                            )
                                        )
                                        .overlay(Capsule().stroke(Color.primary.opacity(0.10), lineWidth: 1))
                                        .foregroundStyle(index > selectedIndex ? .primary : .secondary)
                                })
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            } else {
                // same semantics, just prettier
                HStack {
                    Spacer()
                    Text("Editing")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.poolGreen.opacity(0.95))
                )
                .padding(.horizontal, 12)
                .padding(.top, 6)
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
                            editShoppingListView
                            
                        } else {
                            shoppingListView
                        }
                        
                    case "Schedule":
                        if VM.isEdit {
                            editSchedule
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
                    rate = job.rate
                    
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
                        rate = job.rate
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
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {

                    if job.otherCompany {
                        if let currentCompany = masterDataManager.currentCompany {
                            if currentCompany.id == job.receiverId {
                                HStack(alignment: .top) {
                                    if let otherCompany = VM.senderCompany {
                                        CompanyCardView(company: otherCompany)
                                    }
                                    Spacer()
                                    if let laborContract = VM.laborContract {
                                        NavigationLink(
                                            value: Route.laborContractDetailView(dataService: dataService, contract: laborContract),
                                            label: {
                                                Text("Labor Contract Details")
                                                    .modifier(RedLinkModifier())
                                            }
                                        )
                                    }
                                }
                                .ddCard()
                            }
                        }
                    }

                    // Main Info Card
                    VStack(alignment: .leading, spacing: 10) {
                        DDFieldRow(title: "Date Created", value: fullDate(date: job.dateCreated))
                        DDFieldRow(title: "Customer", value: "\(customer.firstName) \(customer.lastName)")

                        HStack(alignment: .firstTextBaseline) {
                            Text("Admin")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(job.adminName)
                                .font(.subheadline.weight(.semibold))

                            Button(action: {
                                VM.isEdit.toggle()
                            }, label: {
                                Image(systemName: "pencil")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(8)
                                    .background(Circle().fill(Color.primary.opacity(0.06)))
                            })
                        }

                        DDFieldRow(title: "Operation", value: job.operationStatus.rawValue)
                        DDFieldRow(title: "Billing", value: job.billingStatus.rawValue)

                        HStack(alignment: .firstTextBaseline) {
                            Text("Address")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let location = VM.serviceLocation {
                                Text("\(location.address.streetAddress)")
                                    .font(.subheadline.weight(.semibold))
                                    .multilineTextAlignment(.trailing)
                            }
                        }

                        Divider().opacity(0.15)

                        Text("Description")
                            .font(.headline.weight(.semibold))

                        TextField("Description", text: $VM.description, axis: .vertical)
                            .lineLimit(5, reservesSpace: true)
                            .modifier(PlainTextFieldModifier())
                    }
                    .ddCard()

                    // Estimate Breakdown Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Estimate Breakdown")
                                .font(.headline.weight(.semibold))
                            Spacer()
                            Button(action: {
                                VM.showEstimate.toggle()
                            }, label: {
                                HStack(spacing: 6) {
                                    Text(VM.showEstimate ? "Hide Estimate" : "Show Estimate")
                                    Image(systemName: VM.showEstimate ? "chevron.up" : "chevron.down")
                                }
                                .modifier(RedLinkModifier())
                            })
                        }

                        if VM.showEstimate {
                            VStack(alignment: .leading, spacing: 10) {

                                if let laborCost = Double(laborCost),
                                   let shoppingListCost = VM.shoppingListCost,
                                   let shoppingListPrice = VM.shoppingListPrice {

                                    HStack {
                                        Text("Ideal Rate")
                                        Spacer()
                                        Text("\(Double((2.4*laborCost) + shoppingListPrice)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                }

                                Divider().opacity(0.15)

                                if let updatedLaborCost = VM.updatedLaborCost {
                                    HStack {
                                        Button(action: {
                                            VM.showLaborCostBreakDown.toggle()
                                        }, label: {
                                            Image(systemName: "chevron.down")
                                                .padding(8)
                                                .background(Circle().fill(Color.primary.opacity(0.06)))
                                        })
                                        .sheet(isPresented: $VM.showLaborCostBreakDown) {
                                            VStack(alignment: .leading) {
                                                ForEach(VM.jobTaskList) { item in
                                                    HStack {
                                                        Text("\(String(VM.jobTaskList.firstIndex(where: { $0 == item })! + 1)). \(item.name)")
                                                        Spacer()
                                                        Text("\(Double(item.contractedRate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                                    }
                                                }
                                            }
                                            .padding(12)
                                            .presentationDetents([.medium])
                                        }

                                        Text("Labor Cost")
                                        Spacer()
                                        Text("\(updatedLaborCost/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                }

                                if let employeeLaborCost = VM.employeeLaborCost {
                                    Text("\(displayMinAsMinAndHour(min: Int(VM.employeeHours*60))) x \(VM.employeeHourlyRate/100, format: .currency(code: "USD").precision(.fractionLength(2))) = \(employeeLaborCost/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                if let shoppingListCost = VM.shoppingListCost {
                                    HStack {
                                        Button(action: {
                                            VM.showMaterialCostBreakDown.toggle()
                                        }, label: {
                                            Image(systemName: "chevron.down")
                                                .padding(8)
                                                .background(Circle().fill(Color.primary.opacity(0.06)))
                                        })
                                        .sheet(isPresented: $VM.showMaterialCostBreakDown) {
                                            VStack(alignment: .leading) {
                                                ForEach(VM.shoppingItemList) { item in
                                                    HStack {
                                                        Text("\(String(VM.shoppingItemList.firstIndex(where: { $0 == item })! + 1)). \(item.name)")
                                                        Spacer()
                                                        Text("1")
                                                    }
                                                }
                                            }
                                            .padding(12)
                                            .presentationDetents([.medium])
                                        }

                                        Text("Estimated Material Cost")
                                        Spacer()
                                        Text("\(shoppingListCost/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                }

                                Divider().opacity(0.15)

                                if let laborCost = Double(laborCost),
                                   let shoppingListCost = VM.shoppingListCost,
                                   let shoppingListPrice = VM.shoppingListPrice {
                                    let idealRate = Double((2.4*laborCost) + shoppingListPrice)

                                    HStack {
                                        Text("Ideal Profit")
                                        Spacer()
                                        Text("\((idealRate-laborCost-shoppingListCost)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                }
                            }
                            .padding(.leading, 4)
                        }
                    }
                    .ddCard()

                    // Cost Review Card (your profit line left commented remains unchanged)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Cost Review")
                            .font(.headline.weight(.semibold))

                        HStack {
                            Text("Rate")
                            Spacer()
                            Text("\(rate/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                .font(.subheadline.weight(.semibold))
                        }

                        if let updatedLaborCost = VM.updatedLaborCost {
                            HStack {
                                Text("Labor Cost")
                                Spacer()
                                Text("\(updatedLaborCost/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }

                        if let shoppingListCost = VM.shoppingListCost {
                            HStack {
                                Text("Estimated Material Cost")
                                Spacer()
                                Text("\(shoppingListCost/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }

                        Divider().opacity(0.15)

                        HStack {
                            Text("Profit")
                            Spacer()
                            // your profit text is commented in original; leaving untouched
                        }
                    }
                    .ddCard()

                    // spacer so bottom bar doesn't cover content
                    Color.clear.frame(height: 90)
                }
                .padding(12)
            }
            VStack {
                Spacer()
                    senderCompanyBillingInfo
            }
        }
    }

    
    var senderCompanyBillingInfo: some View {
        HStack(spacing: 10) {
            Button(action: {
                showInfoOptions.toggle()
            }, label: {
                Text("More")
                    .modifier(ListButtonModifier())
            })
            .sheet(isPresented: $showInfoOptions) {
                VStack {
                    Button(action: {
                        Task {
                            do {
                                if let company = masterDataManager.currentCompany {
                                    try await VM.sendEstiamteToCustomer(companyId: company.id, job: job)
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
                    }, label: { Text("Send Estimate") })
                    .modifier(ListButtonModifier())

                    Button(action: {
                        VM.isPresentingMarkEstiamteAsAccepted.toggle()
                    }, label: { Text("Mark Estimate As Accepted") })
                    .modifier(ListButtonModifier())
                    .sheet(isPresented: $VM.isPresentingMarkEstiamteAsAccepted) { manualEstimateAcceptInfo }

                    Button(action: {
                        Task {
                            if let company = masterDataManager.currentCompany {
                                if VM.billingStatus == .invoiced {
                                    if let type = VM.invoiceType, type == .manual {
                                        try await VM.markJobAsNotInvoiced(companyId: company.id, job: job)
                                        VM.alertMessage = "Invoiced"
                                        VM.showAlert.toggle()
                                    }
                                } else {
                                    VM.isPresentingMarkJobAsInvoiced.toggle()
                                }
                            }
                        }
                    }, label: {
                        if VM.billingStatus == .invoiced {
                            Text("Invoiced").modifier(SubmitButtonModifier())
                        } else {
                            Text("Mark As Invoiced").modifier(ListButtonModifier())
                        }
                    })
                    .sheet(isPresented: $VM.isPresentingMarkJobAsInvoiced) { manualInvoicedInfo }

                    Button(action: { VM.isEdit.toggle() }, label: {
                        Text("Edit").modifier(BlueButtonModifier())
                    })

                    Button(action: { showDeleteConfirmation.toggle() }, label: {
                        Text("Delete").modifier(DismissButtonModifier())
                    })
                }
                .presentationDetents([.fraction(0.4), .large])
            }

            Spacer()

            if VM.operationStatus == .finished {
                Button(action: {
                    print("Show Accepted Invoice Details")
                }, label: {
                    if VM.billingStatus == .invoiced {
                        HStack {
                            Text("Invoiced")
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .modifier(SubmitButtonModifier())
                    } else {
                        HStack {
                            Text("Invoice")
                            Image(systemName: "circle")
                        }
                        .modifier(ListButtonModifier())
                    }
                })
            }

            Button(action: {
                Task {
                    do {
                        if let company = masterDataManager.currentCompany {
                            if VM.operationStatus == .finished {
                                try await VM.markJobAsUnFinished(companyId: company.id, job: job)
                                VM.alertMessage = "Finished"
                                VM.showAlert.toggle()
                            } else {
                                try await VM.markJobAsFinished(companyId: company.id, job: job)
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
                    HStack { Text("Finished"); Image(systemName: "checkmark.circle.fill") }
                        .modifier(SubmitButtonModifier())
                } else {
                    HStack { Text("Finish"); Image(systemName: "circle") }
                        .modifier(ListButtonModifier())
                }
            })
        }
        .ddBottomBar()
    }

    var editInfo: some View {
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
                        
                        Picker("Admin", selection: $admin) {
                            Text("Pick Admin").tag( CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .contractor))
                            ForEach(VM.techList){ user in
                                Text(user.userName).tag(user)
                            }
                        }
                    }
                    HStack{
                        Text("Operation: ")
                            .bold(true)
                        Spacer()
                    }
                    HStack{
                        Picker("Operation", selection: $operationStatus) {
                            ForEach(JobOperationStatus.allCases,id: \.self){ status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    HStack{
                        Text("Billing: ")
                            .bold(true)
                        Spacer()
                    }
                    HStack{
                        Picker("Billing", selection: $billingStatus) {
                            ForEach(JobBillingStatus.allCases,id: \.self){ status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
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
                                        if let laborCost = Double(laborCost), let shoppingListCost = VM.shoppingListCost, let shoppingListPrice = VM.shoppingListPrice {
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
                            }
                        }
                        Rectangle()
                            .frame(height: 2)
                        VStack(alignment: .leading,spacing: 10){
                            Text("Costs")
                                .font(.headline)
                            VStack{
                                HStack{
                                    Text("Rate")
                                        .bold(true)
                                    Spacer()
                                    Button(action: {
                                        
                                        if let laborCost = Double(laborCost), let shoppingListCost = VM.shoppingListCost, let shoppingListPrice = VM.shoppingListPrice {
                                            let idealRate = Double((2.4*laborCost) + shoppingListPrice)
//                                            rate = idealRate-Int(laborCost)-Int(shoppingListCost)
//                                            Here
                                            
                                        }
                                    }, label: {
                                        Text("Use Estimate")
                                    })
                                }
                                MoneyTextField(cents: $rate)
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
                                    if let laborCost = Double(laborCost),let shoppingListCost = VM.shoppingListCost {
                                        Text("Profit: ")
                                        Spacer()
//                                        Text("\((rate-Int(laborCost)-Int(shoppingListCost))/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                        
                                        //Here
                                    }
                                }
                            }
                            .padding(.leading,16)
                        }
                    }
                    Text("s")
                        .padding(16)
                        .foregroundColor(Color.clear)
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
                                    if admin.id != job.adminId || admin.userName != job.adminName ||  jobTemplate.name != job.type || operationStatus != job.operationStatus || billingStatus != job.billingStatus  || job.rate != rate || laborCost != String(job.laborCost) || description != job.description{
                                        try await VM.updateJobInfo(companyId:company.id,updatingJob: job,
                                                                      admin: admin,
                                                                      jobTemplate: jobTemplate,
                                                                      operationStatus: operationStatus,
                                                                      billingStatus: billingStatus,
                                                                      rate: rate,
                                                                      laborCost: laborCost,
                                                                      description: description)
                                        VM.isEdit.toggle()
                                    } else {
                                        VM.alertMessage = "No Change Made"
                                        print(VM.alertMessage)
                                        VM.showAlert = true
                                    }
                                } catch {
                                    print("[][Error Updating Job] Error: \(error)")
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
                        rate = job.rate
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
        .ddBottomBar()
    }
    
    var taskView: some View {
        ZStack{
            ScrollView {
                VStack(alignment: .center,spacing: 8){
                    Text("Task List")
                        .font(.headline)
                    ForEach(VM.jobTaskList){ task in
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
                            if let company = masterDataManager.currentCompany {
                                VM.onDismissAddTaskSheet(companyId: company.id, serviceLocationId: job.serviceLocationId, jobId: job.id)
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
                                VM.onDismissAddTaskSheet(companyId: company.id, serviceLocationId: job.serviceLocationId, jobId: job.id)
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
                        view = "Shopping"
                    }, label: {
                        Text("Next")
                            .modifier(AddButtonModifier())
                    })
                }
                .padding(.horizontal,8)
                .background(Color.listColor)
            }
        }
        .ddBottomBar()
    }
    
    var editTaskView: some View {
        ZStack{
            ScrollView {
                VStack(alignment: .center,spacing: 8){
                    Text("Task List")
                        .font(.headline)
                        .sheet(item: $VM.editTaskItem, onDismiss: {
                            //Get updated Task List Item List
                            if let company = masterDataManager.currentCompany {
                                VM.onDismissAddTaskSheet(companyId: company.id, serviceLocationId: job.serviceLocationId, jobId: job.id)
                            }
                          
                        }) { item in
                            EditTaskView(dataService: dataService, task: item)
                        }
                    ForEach(VM.jobTaskList){ task in
                        HStack{
                            Button(action: {
                                VM.editTaskItem = task
                            }, label: {
                                Image(systemName: "square.and.pencil")
                                    .modifier(SubmitButtonModifier())
                            })
                            .padding(4)
                            JobTaskCardView(dataService: dataService, jobId: job.id, jobTask: task)
                            Button(action: {
                                if let currentCompany = masterDataManager.currentCompany {
                                    VM.deleteJobTaskItem(companyId: currentCompany.id, jobId: jobId, task: task)
                                    VM.onDismissAddTaskSheet(companyId: currentCompany.id, serviceLocationId: job.serviceLocationId, jobId: job.id)
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
        .ddBottomBar()
    }
    
    var editShoppingListView: some View {
        ZStack{
            ScrollView {
                VStack(alignment: .leading,spacing: 8){
                    Text("Shopping List")
                        .sheet(item: $VM.editShoppingItem, onDismiss: {
                            //Get updated shopping List Item List
                            if let currentCompany = masterDataManager.currentCompany {
                                VM.onDismissAddShoppingListItem(companyId: currentCompany.id, serviceLocationId: job.serviceLocationId, jobId: jobId)
                            }
                        }) { item in
                            EditShoppingListItem(dataService: dataService, item: item)
                        }
                    ForEach(VM.shoppingItemList){ item in
                        HStack{
                            Button(action: {
                                VM.editShoppingItem = item
                            }, label: {
                                Image(systemName: "square.and.pencil")
                                    .modifier(SubmitButtonModifier())
                            })
                            .padding(4)
                            
                            ShoppingListItemCardView(dataService: dataService, shoppingListItem: item)
                            Button(action: {
                                if let currentCompany = masterDataManager.currentCompany {
                                    VM.onDismissAddShoppingListItem(companyId: currentCompany.id, serviceLocationId: job.serviceLocationId, jobId: jobId)

                                    VM.deleteShoppingListItem(companyId: currentCompany.id, jobId: jobId, item: item)
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
                        VM.isEdit = true
                    }, label: {
                        Text("Edit")
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
        .ddBottomBar()
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
                        .sheet(isPresented: $VM.isAddShoppingList, onDismiss: {
                            if let currentCompany = masterDataManager.currentCompany {
                                VM.onDismissAddShoppingListItem(companyId: currentCompany.id, serviceLocationId: job.serviceLocationId, jobId: jobId)
                            }
                        }, content: {
                            AddNewShoppingListItemToJob(dataService: dataService, job: job)
                                .presentationDetents([.medium,.large])
                        })
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
        .ddBottomBar()
    }
    
    var editSchedule: some View {
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
                    /*
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
                    */

                }
                .padding(5)
            }
            VStack{
                Spacer()
                HStack{
                    Button(action: {
                        VM.isEdit = true
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
        .ddBottomBar()
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
        .ddBottomBar()
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
        .ddBottomBar()
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
        .ddBottomBar()
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
        .ddBottomBar()
    }
}

private extension View {
    func ddCard() -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)
                    .shadow(color: Color.darkGray.opacity(0.06), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
    }

    func ddBottomBar() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Color.black.opacity(0.02)
                }
                .ignoresSafeArea(edges: .bottom)
            )
            .overlay(Divider().opacity(0.12), alignment: .top)
    }
}

private struct DDFieldRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }
}
