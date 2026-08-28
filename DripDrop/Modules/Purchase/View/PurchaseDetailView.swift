//
//  PurchaseDetailView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/16/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct PurchaseDetailView: View {
    @EnvironmentObject var customerEnviromentalObject: CustomerViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var customerVM : CustomerViewModel
    @StateObject private var jobVM : JobViewModel
    @State private var purchase : PurchasedItem
    @State private var useablePurchaseItem : PurchasedItem? = nil

    
    init(purchase:PurchasedItem,dataService:any ProductionDataServiceProtocol){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _purchase = State(wrappedValue: purchase)
        _vm = StateObject(wrappedValue: PurchasesViewModel(dataService: dataService))

    }
    @StateObject private var storeVM = StoreViewModel()
    @StateObject private var vm : PurchasesViewModel
    
    
    
    @State var showEditNotesView:Bool = false
    @State private var showSplitPurchaseSheet = false
    @State private var isPurchaseWorkflowUpdating = false
    @State private var purchaseWorkflowError: String?
    @State var customerList:[Customer] = []
    @State var workOrderList:[Job] = []
    
    @State var loading = false
    @State var showStoreInfo = false
    
    @State var customerSearchTerm = ""
    @State var WOSearchTerm = ""
    
    @State var notes = ""
    @State var invoiced:Bool = false
    @State var displayCustomerName = ""
    @State var displayJobName = ""
    @State private var displayShoppingListItemName = ""

    @State var selectedCustomerPicker:Bool = false
    @State var selectedJobPicker:Bool = false
    @State private var selectedShoppingListPicker = false
    @State private var jobPickerStartDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var jobPickerEndDate = Date()

    @State var customerEntity:Customer = Customer(id: "", firstName: "", lastName: "", email: "", billingAddress: Address(streetAddress: "", city: "", state: "", zip: "",latitude: 0,longitude: 0), active: true, displayAsCompany: false, hireDate: Date(), billingNotes: "",
                                                  linkedInviteId: UUID().uuidString)
    @State var jobEntity:Job = Job(
        id: "",
        internalId: "",
        type: "",
        dateCreated: Date(),
        description: "",
        operationStatus: .estimatePending,
        billingStatus: .draft,
        customerId: "",
        customerName: "",
        serviceLocationId: "",
        serviceStopIds: [],
        laborContractIds: [],
        adminId: "",
        adminName: "",
        rate: 0,
        laborCost: 0,
        otherCompany: false,
        receivedLaborContractId: "",
        receiverId: "",
        senderId : "",
        dateEstimateAccepted: nil,
        estimateAcceptedById: nil,
        estimateAcceptType: nil,
        estimateAcceptedNotes: nil,
        invoiceDate: nil,
        invoiceRef: nil,
        invoiceType: nil,
        invoiceNotes: nil
    )
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        VStack{
            ScrollView{
                if !UIDevice.isIPhone {
                    HStack{
                        Spacer()
                        Button(action: {
                            masterDataManager.selectedPurchases = nil
                        }, label: {
                            Image(systemName: "xmark")
                                .modifier(DismissButtonTextModifier())
                        })
                        .padding(5)
                        .background(Color.red)
                        .cornerRadius(5)
                    }
                }
                purchaseView
                search
            }
        }
        .task{
            useablePurchaseItem = purchase
            notes = purchase.notes
            displayCustomerName = purchase.customerName
            displayJobName = purchase.jobId
            displayShoppingListItemName = purchase.shoppingListItemId?.isEmpty == false ? "Linked" : ""
            invoiced = purchase.invoiced
            do {
                if let company = masterDataManager.currentCompany {
          
                    try await storeVM.getSingleStore(companyId: company.id, storeId: purchase.venderId)
                    await loadLinkedShoppingListItemName(companyId: company.id, shoppingListItemId: purchase.shoppingListItemId)
                } else {
                    print("No Customer")
                }
            } catch {
                print("Error")
            }
        }
        
        
        .onChange(of: notes){ note in
            Task{
                if let company = masterDataManager.currentCompany, let useablePurchaseItem {
                    do {
                        try await vm.updateNotes(currentItem: useablePurchaseItem, notes: note, companyId: company.id)
                    } catch {
                        print(error)
                    }
                }
            }
        }
        
        .onChange(of: masterDataManager.selectedPurchases){ item in
            if let item = item {
                purchase = item
                notes = item.notes
                displayCustomerName = item.customerName
                displayJobName = item.jobId
                displayShoppingListItemName = item.shoppingListItemId?.isEmpty == false ? "Linked" : ""
                invoiced = item.invoiced
                customerSearchTerm = ""
                useablePurchaseItem = item
                if let company = masterDataManager.currentCompany {
                    Task {
                        await loadLinkedShoppingListItemName(companyId: company.id, shoppingListItemId: item.shoppingListItemId)
                    }
                }
            }
        }
        .onChange(of: jobEntity, perform: { job in
            Task{
                if let company = masterDataManager.currentCompany, let useablePurchaseItem{
                    do {
                        if job.id == "" {return}
                        try await vm.updateReceiptWorkOrder(currentItem: useablePurchaseItem, workOrderID:job.id , companyId: company.id)
                        try await jobVM.addPurchaseItemsToWorkOrder(workOrder: job, companyId: company.id, ids: [useablePurchaseItem.id])
                        displayJobName = job.internalId.isEmpty ? job.id : job.internalId
                        var updatedPurchase = useablePurchaseItem
                        updatedPurchase.jobId = job.id
                        updatedPurchase.workOrderId = job.id
                        updatedPurchase.assignedJobId = job.id
                        updatedPurchase.assignedToJob = true
                        updatedPurchase.assignmentStatus = "assignedToJob"
                        self.purchase = updatedPurchase
                        self.useablePurchaseItem = updatedPurchase
                    } catch {
                        print("")
                        print("Error Purchase Detail View")
                        print(error)
                        print("")
                    }
                }
            }
        })
        .onChange(of: customerEntity){ customer in
            Task{
                do {
                    if let company = masterDataManager.currentCompany , let useablePurchaseItem{
                        try await vm.updateReceiptCustomer(currentItem: useablePurchaseItem, newCustomer: customer, companyId: company.id)
                        displayCustomerName = customer.firstName  + " " + customer.lastName

                    } else {
                        print("No Customer")
                    }
                } catch {
                    print("Error")
                }
            }
        }
    }
}

extension PurchaseDetailView{
    
    var purchaseView: some View {
        ZStack{
            if UIDevice.isIPhone {
                VStack(spacing: 14){
                    info
                    money
                }
                .padding(.horizontal, 12)
            } else {
                HStack(alignment: .top, spacing: 14){
                    info
                    money
                }
                .padding(.horizontal, 12)
            }
            if loading {
                ProgressView()
            }
        }
    }
    var info: some View {
        ZStack{
                VStack(alignment: .leading, spacing: 14){
                    
                    VStack(alignment: .leading, spacing: 10){
                        Label("Purchase Details", systemImage: "cart")
                            .font(.headline.weight(.semibold))
                        HStack{
                            Text("Store")
                                .foregroundStyle(.secondary)
                            if let useablePurchaseItem {
                                Text(useablePurchaseItem.venderName)
                                    .fontWeight(.semibold)
                                    .textSelection(.enabled)
                            }
                            Button(action: {
                                showStoreInfo = true
                            }, label: {
                                Image(systemName: "info.circle")
                            })
                            .sheet(isPresented: $showStoreInfo, content: {
                                VStack{
                                    HStack{
                                        Spacer()
                                        Button(action: {
                                            showStoreInfo = false
                                        }, label: {
                                            Image(systemName: "xmark")
                                                .modifier(DismissButtonTextModifier())
                                        })
                                        .modifier(DismissButtonModifier())
                                    }
                                    Text("Store Info")
                                    HStack{
                                        Text("Store Name : ")
                                        Text(storeVM.store?.name ?? "...Loading")
                                    }
                                    Text(storeVM.store?.address.streetAddress ?? "")
                                    HStack{
                                        Text(storeVM.store?.address.city ?? "")
                                        Text(" ")
                                        Text(storeVM.store?.address.state ?? "")
                                        Text(" ")
                                        Text(storeVM.store?.address.zip ?? "")
                                    }
                                }
                                .background(Color.green)
                                .cornerRadius(10)
                                
                            })
                        }
                        if let useablePurchaseItem {
                            
                            detailRow("Name", useablePurchaseItem.name)
                            detailRow("Sku", useablePurchaseItem.sku)
                            detailRow("Invoice", useablePurchaseItem.invoiceNum)
                            detailRow("Tech", useablePurchaseItem.techName)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8){
                        Text("Notes")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextEditor(text: $notes)
                            .padding(8)
                            .frame(minHeight: 110)
                            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            }
                    }
                    Spacer()
                }
                .purchaseSurface()
            
        }
    }
    var money: some View {
        ZStack{
                VStack(alignment: .leading, spacing: 14){
                    Label("Money", systemImage: "dollarsign.circle")
                        .font(.headline.weight(.semibold))

                    if let useablePurchaseItem {
                        VStack(alignment: .leading, spacing: 10){
                            metricRow("Price", value: PurchaseMoneyFormatter.string(fromStoredCents: useablePurchaseItem.price))
                            metricRow("Quantity", value: useablePurchaseItem.quantityString)
                            metricRow("Price After Tax", value: PurchaseMoneyFormatter.string(fromStoredCents: useablePurchaseItem.totalAfterTax))
                            metricRow("Date", value: fullDate(date: useablePurchaseItem.date))
                            metricRow("Billable", value: useablePurchaseItem.billable ? "Yes" : "No")
                            metricRow("Returned", value: useablePurchaseItem.returned == true ? "Yes" : "No")
                        }
                    }

                    Divider()

                    HStack{
                        Text("Invoiced")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Button(action: {
                            if invoiced {
                                Task{
                                    try? await vm.updateReciptBillingStatus(currentItem: purchase, newBillingStatus: false, companyId: masterDataManager.currentCompany!.id)
                                    try? await vm.getSinglePurchasedItem(itemId: purchase.id, companyId: masterDataManager.currentCompany!.id)
                                    invoiced = false
                                }
                            } else {
                                Task{
                                    try? await vm.updateReciptBillingStatus(currentItem: purchase, newBillingStatus: true, companyId: masterDataManager.currentCompany!.id)
                                    try? await vm.getSinglePurchasedItem(itemId: purchase.id, companyId: masterDataManager.currentCompany!.id)
                                    invoiced = true
                                }
                            }
                        }, label: {
                            Label(invoiced ? "Invoiced" : "Not Invoiced", systemImage: invoiced ? "checkmark.square.fill" : "square")
                                .font(.caption.weight(.semibold))
                        })
                        .buttonStyle(.bordered)
                    }

                    if let purchaseWorkflowError {
                        Text(purchaseWorkflowError)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 8) {
                        Button(role: .destructive) {
                            Task {
                                await markCurrentPurchaseReturned()
                            }
                        } label: {
                            Label(isPurchaseWorkflowUpdating ? "Updating..." : "Mark Returned", systemImage: "arrow.uturn.backward.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isPurchaseWorkflowUpdating || purchase.returned == true)

                        Button {
                            showSplitPurchaseSheet = true
                        } label: {
                            Label("Split Purchase", systemImage: "rectangle.split.2x1")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isPurchaseWorkflowUpdating || purchase.returned == true || purchase.invoiced || purchase.quantity <= 0)
                    }
                    .font(.caption.weight(.semibold))
                    .sheet(isPresented: $showSplitPurchaseSheet) {
                        PurchasedItemSplitSheet(
                            dataService: dataService,
                            purchase: purchase,
                            isUpdating: isPurchaseWorkflowUpdating
                        ) { quantity, customer, job, splitNotes in
                            await splitCurrentPurchase(
                                quantity: quantity,
                                customer: customer,
                                job: job,
                                notes: splitNotes
                            )
                        }
                        .presentationDetents([.medium, .large])
                    }

                    Spacer()
                }
                .purchaseSurface()
            
        }
    }
    var oldMoneyUnused: some View {
        ZStack{
                VStack{
                    HStack{
                        if let useablePurchaseItem {
                            
                            VStack(alignment: .leading){
                                Text("Price : \(PurchaseMoneyFormatter.string(fromStoredCents: useablePurchaseItem.price))")
                                
                                Text("Quantity : \(useablePurchaseItem.quantityString)")
                                Text("Price After Tax : \(PurchaseMoneyFormatter.string(fromStoredCents: useablePurchaseItem.totalAfterTax))")
                                
                                Text(fullDate(date:useablePurchaseItem.date))
                                Text("Billable : \(useablePurchaseItem.billable ? "Yes" : "No")")
                                
                            }
                        }
                        Spacer()
                    }
                    HStack{
                        Text("Invoiced : ")
                        Button(action: {
                            if invoiced {
                                Task{
                                    try? await vm.updateReciptBillingStatus(currentItem: purchase, newBillingStatus: false, companyId: masterDataManager.currentCompany!.id)
                                    try? await vm.getSinglePurchasedItem(itemId: purchase.id, companyId: masterDataManager.currentCompany!.id)
                                    //                                    self.purchasedItem  = vm.purchasedItem!
                                    invoiced = false
                                }
                            } else {
                                Task{
                                    try? await vm.updateReciptBillingStatus(currentItem: purchase, newBillingStatus: true, companyId: masterDataManager.currentCompany!.id)
                                    try? await vm.getSinglePurchasedItem(itemId: purchase.id, companyId: masterDataManager.currentCompany!.id)
                                    //                                    self.purchasedItem  = vm.purchasedItem!
                                    invoiced = true
                                }
                            }
                        }, label: {
                            if invoiced {
                                Image(systemName: "checkmark.square")
                            }else {
                                Image(systemName: "square")
                            }
                        })
                    }
                    Spacer()
                }
            
        }
    }
    @ViewBuilder
    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value.isEmpty ? "-" : value)
                .textSelection(.enabled)
            Spacer()
        }
    }

    @ViewBuilder
    private func metricRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    var oldInfoUnused: some View {
        ZStack{
                VStack(alignment: .leading){
                    
                    VStack(alignment: .leading){
                        Divider()
                        HStack{
                            Text("Store : ")
                            if let useablePurchaseItem {
                                Text(useablePurchaseItem.venderName)
                                    .textSelection(.enabled)
                            }
                            Button(action: {
                                showStoreInfo = true
                            }, label: {
                                Image(systemName: "info.circle")
                            })
                        }
                        if let useablePurchaseItem {
                            
                            HStack{
                                Text("Name :")
                                Text(useablePurchaseItem.name)
                                    .textSelection(.enabled)
                            }
                            
                            HStack{
                                Text("Sku :")
                                Text(useablePurchaseItem.sku)
                                    .textSelection(.enabled)
                            }
                            HStack{
                                Text("Invoice Num : ")
                                Text(useablePurchaseItem.invoiceNum)
                                    .textSelection(.enabled)
                            }
                            
                            HStack{
                                Text("Tech Name :")
                                Text(useablePurchaseItem.techName)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    VStack(alignment: .leading){
                        HStack{
                            Text("Notes: ")
                            TextEditor(text: $notes)
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                                .frame(height: 100)
                            
                        }
                    }
                    Spacer()
                }
            
        }
    }
    var search: some View {
        ZStack{
            if UIDevice.isIPhone {
                VStack(spacing: 14){
                    searchForShoppingList
                    searchForJob
                    searchForCustomer
                }
                .padding(.horizontal, 12)
            } else {
                HStack(alignment: .top, spacing: 14){
                    searchForShoppingList
                    searchForJob
                    searchForCustomer
                }
                .padding(.horizontal, 12)
            }
        }
    }
    var searchForJob: some View {
        VStack(alignment: .leading, spacing: 12){
            Label("Job", systemImage: "briefcase")
                .font(.headline.weight(.semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("Connected Job")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(displayJobName.isEmpty ? "Not connected" : displayJobName)
                    .font(.subheadline.weight(.semibold))
                    .textSelection(.enabled)
            }

            Button {
                selectedJobPicker.toggle()
            } label: {
                purchaseAssignmentButtonLabel(
                    title: displayJobName.isEmpty ? "Select Job" : "Change Job",
                    systemImage: "link.badge.plus"
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $selectedJobPicker, content: {
                PurchaseJobPickerSheet(
                    selectedJob: $jobEntity,
                    startDate: $jobPickerStartDate,
                    endDate: $jobPickerEndDate
                )
                .presentationDetents([.medium, .large])
            })
        }
        .purchaseSurface()
    }
    var searchForCustomer: some View {
            VStack(alignment: .leading, spacing: 12){
                Label("Customer", systemImage: "person.crop.circle")
                    .font(.headline.weight(.semibold))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Connected Customer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(displayCustomerName.isEmpty ? "Not connected" : displayCustomerName)
                        .font(.subheadline.weight(.semibold))
                        .textSelection(.enabled)
                }

                Button {
                    selectedCustomerPicker.toggle()
                } label: {
                    purchaseAssignmentButtonLabel(
                        title: displayCustomerName.isEmpty ? "Select Customer" : "Change Customer",
                        systemImage: "person.badge.plus"
                    )
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $selectedCustomerPicker, content: {
                    CustomerPickerScreen(dataService: dataService, customer: $customerEntity)
                })
            }
            .purchaseSurface()
        
    }

    var searchForShoppingList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Shopping List", systemImage: "list.bullet.clipboard")
                .font(.headline.weight(.semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("Connected Item")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(displayShoppingListItemName.isEmpty ? "Not connected" : displayShoppingListItemName)
                    .font(.subheadline.weight(.semibold))
                    .textSelection(.enabled)
            }

            Button {
                selectedShoppingListPicker.toggle()
            } label: {
                purchaseAssignmentButtonLabel(
                    title: displayShoppingListItemName.isEmpty ? "Select Shopping Item" : "Change Shopping Item",
                    systemImage: "cart.badge.plus"
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $selectedShoppingListPicker) {
                PurchaseShoppingListPickerSheet(dataService: dataService) { item in
                    Task {
                        await connectShoppingListItem(item)
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
        .purchaseSurface()
    }

    private func purchaseAssignmentButtonLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.poolBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

}

private extension PurchaseDetailView {
    var purchaseWorkflowActorId: String {
        masterDataManager.companyUser?.userId ?? masterDataManager.user?.id ?? ""
    }

    var purchaseWorkflowActorName: String {
        let companyUserName = masterDataManager.companyUser?.userName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !companyUserName.isEmpty {
            return companyUserName
        }

        let firstName = masterDataManager.user?.firstName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = masterDataManager.user?.lastName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)

        return fullName.isEmpty ? "DripDrop" : fullName
    }

    func markCurrentPurchaseReturned() async {
        guard let company = masterDataManager.currentCompany else { return }

        isPurchaseWorkflowUpdating = true
        purchaseWorkflowError = nil
        defer { isPurchaseWorkflowUpdating = false }

        do {
            try await PurchasedItemWorkflowService.shared.markReturnedAndDetach(
                purchase: purchase,
                companyId: company.id,
                actorId: purchaseWorkflowActorId,
                actorName: purchaseWorkflowActorName
            )

            var updatedPurchase = purchase
            updatedPurchase.returned = true
            updatedPurchase.status = "Returned"
            updatedPurchase.shoppingListItemId = nil
            updatedPurchase.jobId = ""
            updatedPurchase.workOrderId = nil
            updatedPurchase.assignedJobId = nil
            updatedPurchase.assignedToJob = false
            updatedPurchase.assignmentStatus = "returned"
            updatedPurchase.billingOwner = nil
            updatedPurchase.jobBillingStatus = "returned"
            updatedPurchase.jobInternalId = nil
            updatedPurchase.jobName = nil
            purchase = updatedPurchase
            useablePurchaseItem = updatedPurchase
            displayJobName = ""
        } catch {
            purchaseWorkflowError = error.localizedDescription
            print("[PurchaseDetailView][markCurrentPurchaseReturned] \(error)")
        }
    }

    func splitCurrentPurchase(
        quantity: Double,
        customer: Customer?,
        job: Job?,
        notes: String
    ) async {
        guard let company = masterDataManager.currentCompany else { return }

        isPurchaseWorkflowUpdating = true
        purchaseWorkflowError = nil
        defer { isPurchaseWorkflowUpdating = false }

        do {
            _ = try await PurchasedItemWorkflowService.shared.splitPurchase(
                purchase: purchase,
                companyId: company.id,
                splitQuantity: quantity,
                customer: customer,
                job: job,
                notes: notes,
                actorId: purchaseWorkflowActorId,
                actorName: purchaseWorkflowActorName
            )

            var updatedPurchase = purchase
            updatedPurchase.quantityString = PurchaseSplitFormatting.quantity(purchase.quantity - quantity)
            purchase = updatedPurchase
            useablePurchaseItem = updatedPurchase
        } catch {
            purchaseWorkflowError = error.localizedDescription
            print("[PurchaseDetailView][splitCurrentPurchase] \(error)")
        }
    }

    func connectShoppingListItem(_ item: ShoppingListItem) async {
        guard let company = masterDataManager.currentCompany else { return }

        let currentPurchase = useablePurchaseItem ?? purchase
        let companyRef = Firestore.firestore()
            .collection("companies")
            .document(company.id)
        let purchaseRef = companyRef
            .collection("purchasedItems")
            .document(currentPurchase.id)
        let shoppingRef = companyRef
            .collection("shoppingList")
            .document(item.id)
        let now = Date()

        isPurchaseWorkflowUpdating = true
        purchaseWorkflowError = nil
        defer { isPurchaseWorkflowUpdating = false }

        do {
            if let previousShoppingItemId = currentPurchase.shoppingListItemId,
               !previousShoppingItemId.isEmpty,
               previousShoppingItemId != item.id {
                try? await companyRef
                    .collection("shoppingList")
                    .document(previousShoppingItemId)
                    .updateData([
                        "purchasedItem": FieldValue.delete(),
                        "status": ShoppingListStatus.needToPurchase.rawValue,
                        "needsAction": true,
                        "actionDate": now
                    ])
            }

            try await purchaseRef.updateData([
                "shoppingListItemId": item.id,
                "status": "Connected to Shopping List"
            ])

            try await shoppingRef.updateData([
                "purchasedItem": currentPurchase.id,
                "status": ShoppingListStatus.purchased.rawValue,
                "needsAction": ShoppingListStatus.purchased.needsShoppingAction,
                "datePurchased": now,
                "actionDate": now
            ])

            var updatedPurchase = currentPurchase
            updatedPurchase.shoppingListItemId = item.id
            updatedPurchase.status = "Connected to Shopping List"
            purchase = updatedPurchase
            useablePurchaseItem = updatedPurchase
            displayShoppingListItemName = item.name.isEmpty ? item.id : item.name
            selectedShoppingListPicker = false
        } catch {
            purchaseWorkflowError = error.localizedDescription
            print("[PurchaseDetailView][connectShoppingListItem] \(error)")
        }
    }

    func loadLinkedShoppingListItemName(companyId: String, shoppingListItemId: String?) async {
        guard let shoppingListItemId,
              !shoppingListItemId.isEmpty else {
            displayShoppingListItemName = ""
            return
        }

        do {
            let item = try await dataService.getSpecificShoppingListItem(
                companyId: companyId,
                shoppingListItemId: shoppingListItemId
            )
            displayShoppingListItemName = item.name.isEmpty ? shoppingListItemId : item.name
        } catch {
            displayShoppingListItemName = "Linked"
            print("[PurchaseDetailView][loadLinkedShoppingListItemName] \(error)")
        }
    }
}

private struct PurchaseSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
    }
}

private extension View {
    func purchaseSurface() -> some View {
        modifier(PurchaseSurfaceModifier())
    }
}

enum PurchaseSplitFormatting {
    static func quantity(_ quantity: Double) -> String {
        if quantity.rounded() == quantity {
            return String(Int(quantity))
        }

        return String(format: "%.3f", quantity)
            .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }
}

struct PurchasedItemSplitSheet: View {
    let dataService: any ProductionDataServiceProtocol
    let purchase: PurchasedItem
    let isUpdating: Bool
    let onSplit: (Double, Customer?, Job?, String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var quantityText: String
    @State private var splitNotes = ""
    @State private var selectedCustomer = PurchaseSplitDefaults.emptyCustomer()
    @State private var selectedJob = PurchaseSplitDefaults.emptyJob()
    @State private var showingCustomerPicker = false
    @State private var showingJobPicker = false
    @State private var isSaving = false

    init(
        dataService: any ProductionDataServiceProtocol,
        purchase: PurchasedItem,
        isUpdating: Bool,
        onSplit: @escaping (Double, Customer?, Job?, String) async -> Void
    ) {
        self.dataService = dataService
        self.purchase = purchase
        self.isUpdating = isUpdating
        self.onSplit = onSplit
        _quantityText = State(wrappedValue: purchase.quantity > 1 ? "1" : "")
    }

    private var splitQuantity: Double? {
        Double(quantityText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var remainingQuantity: Double? {
        guard let splitQuantity else { return nil }
        return purchase.quantity - splitQuantity
    }

    private var canSplit: Bool {
        guard let splitQuantity else { return false }
        return splitQuantity > 0 &&
            splitQuantity < purchase.quantity &&
            purchase.returned != true &&
            !purchase.invoiced &&
            !isUpdating &&
            !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    quantitySection
                    assignmentSection
                    notesSection
                }
                .padding(14)
            }
            .navigationTitle("Split Purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Splitting..." : "Split") {
                        Task {
                            await split()
                        }
                    }
                    .disabled(!canSplit)
                }
            }
            .sheet(isPresented: $showingCustomerPicker) {
                NavigationStack {
                    CustomerPickerScreen(dataService: dataService, customer: $selectedCustomer)
                }
            }
            .sheet(isPresented: $showingJobPicker) {
                NavigationStack {
                    JobPickerScreen(dataService: dataService, job: $selectedJob)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(purchase.name.isEmpty ? "Unnamed purchase" : purchase.name)
                .font(.headline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Text("\(purchase.venderName.isEmpty ? "Unknown vendor" : purchase.venderName) | \(shortDate(date: purchase.date))")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                splitPill(title: "Current Qty", value: PurchaseSplitFormatting.quantity(purchase.quantity))
                splitPill(title: "Unit Cost", value: PurchaseMoneyFormatter.string(fromStoredCents: purchase.price))
            }
        }
        .splitSheetCard()
    }

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Quantity", systemImage: "number")

            TextField("Quantity to split", text: $quantityText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)

            if let remainingQuantity {
                detailLine(
                    title: "Remaining",
                    value: remainingQuantity > 0 ? PurchaseSplitFormatting.quantity(remainingQuantity) : "Invalid"
                )
            }

            Text(validationText)
                .font(.caption)
                .foregroundStyle(canSplit ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.red))
                .fixedSize(horizontal: false, vertical: true)
        }
        .splitSheetCard()
    }

    private var assignmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("New Split Item", systemImage: "person.text.rectangle")

            detailLine(title: "Customer", value: selectedCustomer.id.isEmpty ? "No customer selected" : customerDisplayName(selectedCustomer))
            detailLine(title: "Job", value: selectedJob.id.isEmpty ? "No job selected" : jobDisplayName(selectedJob))

            HStack(spacing: 8) {
                Button {
                    showingCustomerPicker = true
                } label: {
                    Label(selectedCustomer.id.isEmpty ? "Add Customer" : "Change Customer", systemImage: "person.crop.circle.badge.plus")
                }
                .buttonStyle(.bordered)

                Button {
                    showingJobPicker = true
                } label: {
                    Label(selectedJob.id.isEmpty ? "Add Job" : "Change Job", systemImage: "briefcase")
                }
                .buttonStyle(.bordered)
            }
            .font(.caption.weight(.semibold))

            if !selectedCustomer.id.isEmpty || !selectedJob.id.isEmpty {
                Button {
                    selectedCustomer = PurchaseSplitDefaults.emptyCustomer()
                    selectedJob = PurchaseSplitDefaults.emptyJob()
                } label: {
                    Label("Clear Assignment", systemImage: "xmark.circle")
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
            }
        }
        .splitSheetCard()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Notes", systemImage: "note.text")

            TextEditor(text: $splitNotes)
                .frame(minHeight: 90)
                .padding(8)
                .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        }
        .splitSheetCard()
    }

    private var validationText: String {
        if purchase.invoiced {
            return "Already invoiced purchases cannot be split."
        }

        if purchase.returned == true {
            return "Returned purchases cannot be split."
        }

        guard let splitQuantity else {
            return "Enter how many units should move to the new purchased item."
        }

        if splitQuantity <= 0 {
            return "Split quantity must be greater than zero."
        }

        if splitQuantity >= purchase.quantity {
            return "Split quantity must be less than the current quantity."
        }

        return "The original purchase keeps the remaining quantity."
    }

    private func splitPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func detailLine(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private func customerDisplayName(_ customer: Customer) -> String {
        if customer.displayAsCompany {
            return firstNonEmpty(customer.company ?? "", "\(customer.firstName) \(customer.lastName)")
        }

        return firstNonEmpty("\(customer.firstName) \(customer.lastName)", customer.company ?? "")
    }

    private func jobDisplayName(_ job: Job) -> String {
        firstNonEmpty(job.internalId, job.type, job.id)
    }

    private func firstNonEmpty(_ values: String...) -> String {
        for value in values {
            let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanValue.isEmpty {
                return cleanValue
            }
        }

        return ""
    }

    private func split() async {
        guard let splitQuantity, canSplit else { return }

        isSaving = true
        defer { isSaving = false }

        await onSplit(
            splitQuantity,
            selectedCustomer.id.isEmpty ? nil : selectedCustomer,
            selectedJob.id.isEmpty ? nil : selectedJob,
            splitNotes
        )
        dismiss()
    }
}

private enum PurchaseSplitDefaults {
    static func emptyCustomer() -> Customer {
        Customer(
            id: "",
            firstName: "",
            lastName: "",
            email: "",
            billingAddress: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0),
            active: true,
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        )
    }

    static func emptyJob() -> Job {
        Job(
            id: "",
            internalId: "",
            type: "",
            dateCreated: Date(),
            description: "",
            operationStatus: .estimatePending,
            billingStatus: .draft,
            customerId: "",
            customerName: "",
            serviceLocationId: "",
            serviceStopIds: [],
            laborContractIds: [],
            adminId: "",
            adminName: "",
            rate: 0,
            laborCost: 0,
            otherCompany: false,
            receivedLaborContractId: "",
            receiverId: "",
            senderId: "",
            dateEstimateAccepted: nil,
            estimateAcceptedById: nil,
            estimateAcceptType: nil,
            estimateAcceptedNotes: nil,
            invoiceDate: nil,
            invoiceRef: nil,
            invoiceType: nil,
            invoiceNotes: nil
        )
    }
}

private struct SplitSheetCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

private extension View {
    func splitSheetCard() -> some View {
        modifier(SplitSheetCardModifier())
    }
}

private struct PurchaseShoppingListPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    let dataService: any ProductionDataServiceProtocol
    let onSelect: (ShoppingListItem) -> Void

    @State private var items: [ShoppingListItem] = []
    @State private var searchTerm = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var filteredItems: [ShoppingListItem] {
        let clean = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return sortedItems }

        return sortedItems.filter { item in
            [
                item.id,
                item.name,
                item.description,
                item.status.rawValue,
                item.category.rawValue,
                item.customerName ?? "",
                item.jobId ?? "",
                item.purchaserName,
                item.dbItemId ?? ""
            ]
            .joined(separator: " ")
            .lowercased()
            .contains(clean)
        }
    }

    private var sortedItems: [ShoppingListItem] {
        items.sorted {
            if $0.status == $1.status {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

            return $0.status.rawValue < $1.status.rawValue
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search shopping list", text: $searchTerm)
                        .submitLabel(.search)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(14)

                List {
                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                        }
                    }

                    Section {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Loading shopping list...")
                                Spacer()
                            }
                            .padding(.vertical, 24)
                        } else if filteredItems.isEmpty {
                            ContentUnavailableView(
                                "No Shopping Items Found",
                                systemImage: "cart",
                                description: Text("Adjust the search term or create a shopping list item first.")
                            )
                        } else {
                            ForEach(filteredItems) { item in
                                Button {
                                    onSelect(item)
                                    dismiss()
                                } label: {
                                    shoppingItemRow(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text("\(filteredItems.count) Shopping Items")
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Select Shopping Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadItems()
            }
        }
    }

    private func shoppingItemRow(_ item: ShoppingListItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.purchasedItem?.isEmpty == false ? "checkmark.circle.fill" : "cart")
                .font(.body.weight(.semibold))
                .foregroundStyle(item.purchasedItem?.isEmpty == false ? Color.poolGreen : .secondary)
                .frame(width: 30, height: 30)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name.isEmpty ? "Shopping Item" : item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(shoppingSubtitle(item))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(item.status.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func shoppingSubtitle(_ item: ShoppingListItem) -> String {
        [
            item.customerName ?? "",
            item.jobId ?? "",
            item.quantity.map { "Qty \($0)" } ?? "",
            item.purchaserName
        ]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .joined(separator: " / ")
    }

    @MainActor
    private func loadItems() async {
        guard let company = masterDataManager.currentCompany else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            items = try await dataService.getAllShoppingListItemsByCompany(companyId: company.id)
        } catch {
            errorMessage = "Could not load shopping list items."
            print("[PurchaseShoppingListPickerSheet][loadItems] \(error)")
        }
    }
}

private struct PurchaseJobPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    @Binding var selectedJob: Job
    @Binding var startDate: Date
    @Binding var endDate: Date

    @State private var jobs: [Job] = []
    @State private var searchTerm = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var filteredJobs: [Job] {
        let clean = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return jobs }

        return jobs.filter { job in
            job.id.lowercased().contains(clean) ||
            job.internalId.lowercased().contains(clean) ||
            job.customerName.lowercased().contains(clean) ||
            job.description.lowercased().contains(clean) ||
            job.operationStatus.rawValue.lowercased().contains(clean) ||
            job.billingStatus.rawValue.lowercased().contains(clean)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                controls

                List {
                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                        }
                    }

                    Section {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Loading jobs...")
                                Spacer()
                            }
                            .padding(.vertical, 24)
                        } else if filteredJobs.isEmpty {
                            ContentUnavailableView(
                                "No Jobs Found",
                                systemImage: "briefcase",
                                description: Text("Adjust the date range or search term.")
                            )
                        } else {
                            ForEach(filteredJobs) { job in
                                jobRow(job)
                            }
                        }
                    } header: {
                        Text("\(filteredJobs.count) Jobs")
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Select Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadJobs()
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                DatePicker("Start", selection: $startDate, displayedComponents: .date)
                DatePicker("End", selection: $endDate, displayedComponents: .date)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search jobs...", text: $searchTerm)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !searchTerm.isEmpty {
                    Button {
                        searchTerm = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    Task { await loadJobs() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
        }
        .padding(14)
        .background(.regularMaterial)
    }

    private func jobRow(_ job: Job) -> some View {
        Button {
            selectedJob = job
            dismiss()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: job.id == selectedJob.id ? "checkmark.circle.fill" : "briefcase")
                    .font(.title3)
                    .foregroundStyle(job.id == selectedJob.id ? Color.accentColor : .secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(job.internalId.isEmpty ? job.id : job.internalId)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(job.operationStatus.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                    }

                    Text(job.customerName.isEmpty ? "No customer" : job.customerName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(fullDate(date: job.dateCreated))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if !job.description.isEmpty {
                        Text(job.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private func loadJobs() async {
        guard let company = masterDataManager.currentCompany else {
            errorMessage = "Missing company."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate

        do {
            jobs = try await Firestore.firestore()
                .collection("companies/\(company.id)/workOrders")
                .whereField("dateCreated", isGreaterThanOrEqualTo: start)
                .whereField("dateCreated", isLessThanOrEqualTo: end)
                .order(by: "dateCreated", descending: true)
                .getDocuments(as: Job.self)
        } catch {
            print("[PurchaseJobPickerSheet][loadJobs] \(error)")
            errorMessage = "Could not load jobs for that date range."
        }
    }
}
