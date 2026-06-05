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

    @State var selectedCustomerPicker:Bool = false
    @State var selectedJobPicker:Bool = false
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
            invoiced = purchase.invoiced
            do {
                if let company = masterDataManager.currentCompany {
          
                    try await storeVM.getSingleStore(companyId: company.id, storeId: purchase.venderId)
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
                invoiced = item.invoiced
                customerSearchTerm = ""
                useablePurchaseItem = item
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
                            metricRow("Price", value: useablePurchaseItem.price.formatted(.currency(code: "USD")))
                            metricRow("Quantity", value: useablePurchaseItem.quantityString)
                            metricRow("Price After Tax", value: useablePurchaseItem.totalAfterTax.formatted(.currency(code: "USD")))
                            metricRow("Date", value: fullDate(date: useablePurchaseItem.date))
                            metricRow("Billable", value: useablePurchaseItem.billable ? "Yes" : "No")
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
                                Text("Price : \(useablePurchaseItem.price, format: .currency(code: "USD"))")
                                
                                Text("Quantity : \(useablePurchaseItem.quantityString)")
                                Text("Price After Tax : \(useablePurchaseItem.totalAfterTax, format: .currency(code: "USD"))")
                                
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
                    searchForJob
                    searchForCustomer
                }
                .padding(.horizontal, 12)
            } else {
                HStack(alignment: .top, spacing: 14){
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
                Label(displayJobName.isEmpty ? "Select Job" : "Change Job", systemImage: "link.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
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
                    Label(displayCustomerName.isEmpty ? "Select Customer" : "Change Customer", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .sheet(isPresented: $selectedCustomerPicker, content: {
                    CustomerPickerScreen(dataService: dataService, customer: $customerEntity)
                })
            }
            .purchaseSurface()
        
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
