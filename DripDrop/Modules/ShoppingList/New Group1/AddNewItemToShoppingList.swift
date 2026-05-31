//
//  AddNewItemToShoppingList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI

struct AddNewItemToShoppingList: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @Environment(\.dismiss) private var dismiss

    @StateObject var receiptDatabaseVM: ReceiptDatabaseViewModel
    @StateObject var jobVM: JobViewModel
    @StateObject var shoppingVM: ShoppingListViewModel

    init(dataService: any ProductionDataServiceProtocol) {
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _shoppingVM = StateObject(wrappedValue: ShoppingListViewModel(dataService: dataService))
        _receiptDatabaseVM = StateObject(wrappedValue: ReceiptDatabaseViewModel(dataService: dataService))
    }

    @State private var description: String = ""
    @State private var type: ShoppingListCategory = .customer
    @State private var itemType: ShoppingListSubCategory = .dataBase
    @State private var quantity: String = "1"

    @State private var search: String = ""
    @State private var name: String = ""

    @State private var selectCustomer: Bool = false
    @State private var addNewItem: Bool = false
    @State private var addJob: Bool = false
    @State private var addUser: Bool = false

    @State private var isLoading: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @State private var dataBaseItem: DataBaseItem = DataBaseItem(
        id: "",
        name: "",
        rate: 0,
        storeName: "",
        venderId: "",
        category: .chems,
        subCategory: .bushing,
        description: "",
        dateUpdated: Date(),
        sku: "",
        billable: false,
        color: "",
        size: "",
        UOM: .ft
    )

    @State private var customer: Customer = Customer(
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

    @State private var job: Job = Job(
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

    @State private var companyUser: CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .employee
    )

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    categoryCard
                    ownerCard
                    itemCard
                    notesCard
                    submitButton
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }

            if isLoading {
                loadingOverlay
            }
        }
        .navigationTitle("Add Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    submit()
                    
                } label: {
                    Text(isSubmitting ? "Saving..." : "Submit")
                        .font(.caption.weight(.semibold))
                }
                .disabled(isSubmitting)
            }
        }
        .alert("Shopping List", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .task {
            await onLoad()
        }
        .onChange(of: dataBaseItem) { item in
            if item.id != "" {
                name = item.name
            }
        }
        .onChange(of: search) { term in
            if term != "" {
                receiptDatabaseVM.filterDataBaseList(
                    filterTerm: term,
                    items: receiptDatabaseVM.dataBaseItems
                )

                if let first = receiptDatabaseVM.dataBaseItemsFiltered.first {
                    dataBaseItem = first
                }
            }
        }
        .onChange(of: jobVM.searchTerm) { term in
            if term != "" {
                jobVM.filterWorkOrderList()
            }
        }
    }
    private var selectedUserId: String? {
        switch type {
        case .personal:
            return companyUser.userId.isEmpty ? companyUser.id : companyUser.userId

        case .customer, .job:
            return nil
        }
    }

    private var selectedUserName: String? {
        switch type {
        case .personal:
            return companyUser.userName

        case .customer, .job:
            return nil
        }
    }

    private var selectedServiceLocationId: String? {
        switch type {
        case .job:
            return job.serviceLocationId

        case .customer, .personal:
            return nil
        }
    }

    private var selectedServiceLocationName: String? {
        nil
    }
}

// MARK: - Sections

extension AddNewItemToShoppingList {

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                        .frame(width: 58, height: 58)

                    Image(systemName: "cart.badge.plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Add Shopping Item")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Create a personal, customer, or job shopping item.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(Date(), style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                headerPill(title: type.rawValue, systemImage: categoryIcon(type))
                headerPill(title: itemType.rawValue, systemImage: "shippingbox")
                headerPill(title: "Qty \(quantity.isEmpty ? "-" : quantity)", systemImage: "number")
                Spacer()
            }
        }
        .addShoppingCard(material: true)
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Category",
                subtitle: "Choose where this item belongs.",
                systemImage: "square.grid.2x2"
            )

            Picker("Category", selection: $type) {
                ForEach(ShoppingListCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }            }
            .pickerStyle(.segmented)
        }
        .addShoppingCard()
    }

    private var ownerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: ownerTitle,
                subtitle: ownerSubtitle,
                systemImage: categoryIcon(type)
            )

            switch type {
            case .customer:
                customerPickerRow

            case .personal:
                personalPickerRow

            case .job:
                jobPickerRow
            }
        }
        .addShoppingCard()
    }

    private var itemCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Item",
                subtitle: "Pick a database item or create a custom item.",
                systemImage: "shippingbox"
            )

            CreateShoppingListItemView(
                itemType: $itemType,
                name: $name,
                quantity: $quantity,
                addNewItem: $addNewItem,
                dataBaseItem: $dataBaseItem
            )
        }
        .addShoppingCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Notes",
                subtitle: "Optional details for the shopping item.",
                systemImage: "note.text"
            )

            TextField(
                "Description / notes...",
                text: $description,
                axis: .vertical
            )
            .lineLimit(3...6)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .addShoppingCard()
    }

    private var customerPickerRow: some View {
        pickerButtonRow(
            title: "Customer",
            value: customer.id == "" ? "Select Customer" : customerDisplayName,
            systemImage: "person.text.rectangle",
            isSelected: customer.id != ""
        ) {
            selectCustomer.toggle()
        }
        .sheet(isPresented: $selectCustomer) {
            CustomerPickerScreen(
                dataService: dataService,
                customer: $customer
            )
        }
    }

    private var personalPickerRow: some View {
        pickerButtonRow(
            title: "User",
            value: companyUser.id == "" ? "Select User" : "\(companyUser.userName) \(companyUser.roleName)",
            systemImage: "person.crop.circle",
            isSelected: companyUser.id != ""
        ) {
            addUser.toggle()
        }
        .sheet(isPresented: $addUser) {
            CompanyUserPicker(
                dataService: dataService,
                companyUser: $companyUser
            )
        }
    }

    private var jobPickerRow: some View {
        pickerButtonRow(
            title: "Job",
            value: job.id == "" ? "Select Job" : "\(job.internalId.isEmpty ? job.id : job.internalId) • \(job.customerName)",
            systemImage: "briefcase",
            isSelected: job.id != ""
        ) {
            addJob.toggle()
        }
        .sheet(isPresented: $addJob) {
            JobPickerScreen(
                dataService: dataService,
                job: $job
            )
        }
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                }

                Text(isSubmitting ? "Saving Item..." : "Submit Item")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                canSubmit
                ? Color.accentColor.opacity(0.18)
                : Color.primary.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit || isSubmitting)
    }
}

// MARK: - Loading / Submit

extension AddNewItemToShoppingList {

    private func onLoad() async {
        guard let company = masterDataManager.currentCompany else {
            alertMessage = "Missing company."
            showAlert = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            var testPrint = 0
            try await receiptDatabaseVM.getAllDataBaseItems(companyId: company.id)
            
            testPrint += 1
            print(testPrint)
            try await jobVM.getAllWorkOrders(companyId: company.id)
            testPrint += 1
            print(testPrint)
            try await shoppingVM.getCompanyUsers(companyId: company.id)
            testPrint += 1
            print(testPrint)

            if let firstItem = receiptDatabaseVM.dataBaseItems.first {
                dataBaseItem = firstItem
                name = firstItem.name
            }
            
            testPrint += 1
            print(testPrint)
            if let selectedCustomer = masterDataManager.selectedCustomer {
                customer = selectedCustomer
            }
            testPrint += 1
            print(testPrint)

            if let user = masterDataManager.user {
                testPrint += 1
                print(testPrint)
                if let matchingCompanyUser = shoppingVM.companyUsers.first(where: { $0.userId == user.id }) {
                    testPrint += 1
                    print(testPrint)
                    companyUser = matchingCompanyUser
                } else if let firstCompanyUser = shoppingVM.companyUsers.first {
                    testPrint += 1
                    print(testPrint)
                    companyUser = firstCompanyUser
                    testPrint += 1
                    print(testPrint)
                }
            } else if let firstCompanyUser = shoppingVM.companyUsers.first {
                testPrint += 1
                print(testPrint)
                companyUser = firstCompanyUser
            }
            testPrint += 1
            print(testPrint)
        } catch {
            print("Error loading AddNewItemToShoppingList")
            print(error)

            alertMessage = "Failed to load shopping item options."
            showAlert = true
        }
    }

    private func submit() {
        guard validateBeforeSubmit() else { return }

        Task {
            guard let company = masterDataManager.currentCompany,
                  let user = masterDataManager.user else {
                alertMessage = "Missing company or user."
                showAlert = true
                return
            }

            isSubmitting = true
            defer { isSubmitting = false }

            do {
                let purchaserName = "\(user.firstName) \(user.lastName)"

                try await shoppingVM.addNewShoppingListItemWithValidation(
                    companyId: company.id,
                    datePurchased: nil,
                    category: type,
                    subCategory: itemType,
                    purchaserId: user.id,
                    itemId: selectedDatabaseItemId,
                    quantiy: quantity,
                    description: description,
                    jobId: selectedJobId,
                    customerId: selectedCustomerId,
                    customerName: selectedCustomerName,
                    userId: selectedUserId,
                    userName: selectedUserName,
                    serviceLocationId: selectedServiceLocationId,
                    serviceLocationName: selectedServiceLocationName,
                    purchaserName: purchaserName,
                    name: selectedItemName
                )

                print("Successfully Added Shopping List Item")
                dismiss()
            } catch {
                print("Error Uploading New shopping List Item")
                print(error)

                alertMessage = "Failed to add shopping list item."
                showAlert = true
            }
        }
    }

    private func validateBeforeSubmit() -> Bool {
        if quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertMessage = "Please enter a quantity."
            showAlert = true
            return false
        }

        switch type {
        case .customer:
            if customer.id == "" {
                alertMessage = "Please select a customer."
                showAlert = true
                return false
            }

        case .personal:
            if companyUser.id == "" {
                alertMessage = "Please select a user."
                showAlert = true
                return false
            }

        case .job:
            if job.id == "" {
                alertMessage = "Please select a job."
                showAlert = true
                return false
            }
        }

        switch itemType {
        case .dataBase:
            if dataBaseItem.id == "" {
                alertMessage = "Please select a database item."
                showAlert = true
                return false
            }

        case .custom:
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                alertMessage = "Please enter a custom item name."
                showAlert = true
                return false
            }

        case .chemical, .part:
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               dataBaseItem.id == "" {
                alertMessage = "Please select or name the item."
                showAlert = true
                return false
            }
        }

        return true
    }
}

// MARK: - Computed Values

extension AddNewItemToShoppingList {

    private var canSubmit: Bool {
        if quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }

        switch type {
        case .customer:
            if customer.id == "" { return false }

        case .personal:
            if companyUser.id == "" { return false }

        case .job:
            if job.id == "" { return false }
        }

        switch itemType {
        case .dataBase:
            return dataBaseItem.id != ""

        case .custom:
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .chemical, .part:
            return dataBaseItem.id != "" || !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var customerDisplayName: String {
        let fullName = "\(customer.firstName) \(customer.lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return fullName.isEmpty ? customer.id : fullName
    }

    private var selectedItemName: String {
        if itemType == .dataBase, dataBaseItem.id != "" {
            return dataBaseItem.name
        }

        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedDatabaseItemId: String? {
        itemType == .dataBase ? dataBaseItem.id : nil
    }

    private var selectedJobId: String? {
        type == .job ? job.id : nil
    }

    private var selectedCustomerId: String? {
        switch type {
        case .customer:
            return customer.id

        case .job:
            return job.customerId

        case .personal:
            return nil
        }
    }

    private var selectedCustomerName: String? {
        switch type {
        case .customer:
            return customerDisplayName

        case .job:
            return job.customerName

        case .personal:
            return nil
        }
    }

    private var ownerTitle: String {
        switch type {
        case .customer:
            return "Customer"

        case .personal:
            return "Personal User"

        case .job:
            return "Job"
        }
    }

    private var ownerSubtitle: String {
        switch type {
        case .customer:
            return "Attach this item to a customer."

        case .personal:
            return "Assign this item to a company user."

        case .job:
            return "Attach this item to a job."
        }
    }

    private func categoryIcon(_ category: ShoppingListCategory) -> String {
        switch category {
        case .customer:
            return "person.text.rectangle"

        case .personal:
            return "person.crop.circle"

        case .job:
            return "briefcase"
        }
    }
}

// MARK: - UI Helpers

extension AddNewItemToShoppingList {

    private func sectionHeader(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    private func pickerButtonRow(
        title: String,
        value: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func headerPill(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()

                Text("Loading options...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

private extension View {
    func addShoppingCard(material: Bool = false) -> some View {
        self
            .padding(16)
            .background(
                material ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
    }
}
