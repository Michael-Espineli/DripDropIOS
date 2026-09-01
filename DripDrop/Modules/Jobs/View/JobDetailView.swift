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

    @State var view:String = "Plans"
    @State var jobId:String = "J"

    @State private var showAdminSelector: Bool = false
    @State private var showOperationStatusSelector: Bool = false
    @State private var showBillingStatusSelector: Bool = false
    
    @State private var showSaveJobAsTemplateSheet: Bool = false
    @State private var showDuplicateJobSheet: Bool = false
    
    @State private var showBillingActionsSheet: Bool = false
    @State private var showCommentsSheet: Bool = false

        //Body Of Water

    @State var jobTemplate:JobTemplate = JobTemplate(companyId: "", name: "", createdByUserId: "")
    @State var serviceStopTemplate:ServiceStopTemplate = ServiceStopTemplate(id: "", name: "", type: "", typeImage: "", dateCreated: Date(), color: "")
    
    @State var dateCreated:Date = Date()
    @State var description:String = ""
    
    @State var operationStatus:JobOperationStatus = .estimatePending
    
    @State var billingStatus:JobBillingStatus = .draft

    private var jobDeleteLocked: Bool {
        job.operationStatus == .finished || VM.operationStatus == .finished
    }
    
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
    
//    @State var installationParts:[WODBItem] = []
//    @State var installationPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
//    @State var showInstallationParts:Bool = false
//    @State var pvcParts:[WODBItem] = []
//    @State var pvcPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
//    @State var showpvcParts:Bool = false
//    @State var electricalParts:[WODBItem] = []
//    @State var electricalPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
//    @State var showelectricalParts:Bool = false
//    @State var chemicals:[WODBItem] = []
//    @State var chemical:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
//    @State var showchemicals:Bool = false
//    @State var miscParts:[WODBItem] = []
//    @State var miscPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
//    @State var showmiscParts:Bool = false
    
    
    @State var rate: Int = 0
    @State var laborCost:String = "0"
    @State var showCustomerSelector:Bool = false
    @State var showPurchasedItemSelector:Bool = false
    
    
    @State var showBodyOfWaterSheet:Bool = false
    
    @State var showTreeSheet:Bool = false
    @State var showBushSheet:Bool = false
    @State var showDeleteConfirmation:Bool = false
    @State private var pendingDeleteConfirmation: Bool = false

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
            VStack(spacing: 0){
                if !VM.isEdit {
                    jobDetailSummaryHeader
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                    jobDetailTabs
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
                case "Plans", "Overview":
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

                case "Planned":
                    plannedWebDetailView

                case "Tasks":
                    if VM.isEdit {
                        editTaskView
                    } else {
                        taskView
                    }

                case "Offers":
                    offersView
                    

                case "Schedule":
                    if VM.isEdit {
                        editSchedule
                    } else {
                        schedule
                    }
                    
                case "Materials":
                    if VM.isEdit {
                        editShoppingListView
                    } else {
                        shoppingListView
                    }

                case "Actual":
                    actualWorkView
                    
                case "Billing":
                    billingView
                case "History":
                    historyView
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
        .sheet(isPresented: $showCommentsSheet) {
            NavigationStack {
                commentsView
                    .navigationTitle("Job Comments")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showCommentsSheet = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
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
                    applyJobAdmin(job)
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
                        applyJobAdmin(job)
                        rate = job.rate
                        laborCost = String(job.laborCost)
                        
                        try await VM.onLoad(companyId: company.id, serviceLocationId: job.serviceLocationId, job: job)
                    }
                } catch {
                    
                    print("")
                    print("Job - masterDataManager.selectedJob - [JobDetailView]")
                    print(error)
                    print("")
                }
                
            }
            
        })
        .alert("Delete Job?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    guard !jobDeleteLocked else {
                        VM.alertMessage = "Finished jobs cannot be deleted."
                        VM.showAlert = true
                        return
                    }

                    guard let company = masterDataManager.currentCompany else {
                        VM.alertMessage = "Missing Company"
                        VM.showAlert = true
                        return
                    }

                    do {
                        try await VM.delete(
                            companyId: company.id,
                            jobId: job.id,
                            serviceStopIds: job.serviceStopIds,
                            laborContractIds: job.laborContractIds
                        )

                        VM.alertMessage = "Deleted"
                        VM.showAlert = true
                        dismiss()
                    } catch {
                        print(error)
                        VM.alertMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                        VM.showAlert = true
                    }
                }
            }
            .disabled(jobDeleteLocked)

            Button("Cancel", role: .cancel) { }
        } message: {
            Text(jobDeleteLocked
                ? "Finished jobs cannot be deleted."
                : "This will delete this job and related records. This cannot be undone.")
        }
        .onChange(of: showBillingActionsSheet) { isShowing in
            guard !isShowing, pendingDeleteConfirmation else { return }

            pendingDeleteConfirmation = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                VM.alertMessage = "Are you sure you want to delete this job?"
                showDeleteConfirmation = true
            }
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
    private var jobDetailSummaryHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "briefcase.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 36, height: 36)
                .background(Color.poolBlue.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(job.type.isEmpty ? "Job \(job.internalId)" : job.type)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(job.customerName.isEmpty ? job.internalId : "\(job.customerName) • \(job.internalId)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        compactJobDetailChip(
                            title: job.operationStatus.rawValue,
                            systemImage: operationStatusIcon(job.operationStatus),
                            tint: jobDetailOperationTint(job.operationStatus)
                        )

                        compactJobDetailChip(
                            title: job.billingStatus.rawValue,
                            systemImage: billingStatusIcon(job.billingStatus),
                            tint: jobDetailBillingTint(job.billingStatus)
                        )

                        commentsInfoBarButton
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var jobDetailTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VM.viewOptionList, id: \.self) { option in
                    jobDetailTabButton(option)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial)
    }

    private func jobDetailTabButton(_ option: String) -> some View {
        let isSelected = jobDetailTabIsSelected(option)

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                view = option
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: jobDetailTabIcon(option))
                    .font(.caption.weight(.semibold))

                Text(option)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func jobDetailTabIsSelected(_ option: String) -> Bool {
        if view == option {
            return true
        }

        switch option {
        case "Plans":
            return view == "Overview"
        case "Planned":
            return ["Tasks", "Offers", "Schedule", "Materials"].contains(view)
        default:
            return false
        }
    }

    private func compactJobDetailChip(title: String, systemImage: String, tint: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(tint.opacity(0.10), in: Capsule())
    }

    private var commentsInfoBarButton: some View {
        Button {
            showCommentsSheet = true
        } label: {
            Label(jobCommentSummaryTitle, systemImage: "text.bubble.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(jobDetailCommentsTint)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(jobDetailCommentsTint.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(jobCommentAccessibilityLabel))
    }

    private var jobCommentSummaryTitle: String {
        let openCount = VM.comments.filter { !$0.resolved }.count

        if openCount > 0 {
            return "\(openCount) Open"
        }

        return "Comments"
    }

    private var jobCommentAccessibilityLabel: String {
        let openCount = VM.comments.filter { !$0.resolved }.count
        let totalCount = VM.comments.count

        if VM.commentsLoading && totalCount == 0 {
            return "Job comments loading"
        }

        return "\(totalCount) job comments, \(openCount) open"
    }

    private var jobDetailCommentsTint: Color {
        VM.comments.contains { !$0.resolved } ? .orange : .poolBlue
    }

    private func jobDetailTabIcon(_ option: String) -> String {
        switch option {
        case "Plans": return "square.grid.2x2.fill"
        case "Planned": return "checklist"
        case "Overview": return "doc.text.fill"
        case "Tasks": return "checklist"
        case "Offers": return "paperplane.fill"
        case "Schedule": return "calendar"
        case "Materials": return "cart.fill"
        case "Actual": return "hammer.fill"
        case "Billing": return "creditcard.fill"
        case "History": return "clock.arrow.circlepath"
        default: return "square.grid.2x2.fill"
        }
    }

    private func jobDetailOperationTint(_ status: JobOperationStatus) -> Color {
        switch status {
        case .finished:
            return .poolGreen
        case .scheduled, .inProgress:
            return .poolBlue
        case .unscheduled:
            return .orange
        case .draft, .estimatePending, .waitingForParts:
            return .poolRed
        }
    }

    private func jobDetailBillingTint(_ status: JobBillingStatus) -> Color {
        switch status {
        case .paid, .accepted, .comped:
            return .poolGreen
        case .estimate, .invoiced:
            return .poolBlue
        case .inProgress:
            return .orange
        case .draft, .expired, .rejected:
            return .poolRed
        }
    }
    
    // MARK: info
    var info: some View {
        JobDashboardView(
            job: job,
            summary: VM.dashboardSummary(for: job),
            healthReport: VM.workflowHealthReport(for: job),
            serviceLocation: VM.serviceLocation,
            sourceRepairRequest: VM.sourceRepairRequest,
            dataService: dataService,
            operationStatus: VM.operationStatus,
            billingStatus: VM.billingStatus,
            onNavigateToHealthIssue: { destination in
                view = destination
            },
            onGoToPlan: {
                view = "Planned"
            },
            onGoToOffers: {
                view = "Offers"
            },
            onGoToSchedule: {
                view = "Schedule"
            },
            onGoToActual: {
                view = "Actual"
            },
            onGoToMaterials: {
                view = "Materials"
            },
            onGoToBilling: {
                view = "Billing"
            },
            onEditInfo: {
                VM.isEdit = true
            },
            onSendEstimate: {
                Task {
                    do {
                        if let company = masterDataManager.currentCompany {
                            try await VM.sendEstiamteToCustomer(
                                companyId: company.id,
                                job: job
                            )
                            
                            VM.alertMessage = "Estimate Sent To Customer"
                            VM.showAlert = true
                        }
                    } catch {
                        print("[][sendEstimate dashboard] Error \(error)")
                    }
                }
            },
            onMarkAccepted: {
                VM.isPresentingMarkEstiamteAsAccepted = true
            },
            onMarkInvoiced: {
                if VM.billingStatus == .invoiced {
                    Task {
                        do {
                            if let company = masterDataManager.currentCompany,
                               VM.invoiceType == .manual {
                                try await VM.markJobAsNotInvoiced(
                                    companyId: company.id,
                                    job: job
                                )
                            }
                        } catch {
                            print("[][mark not invoiced dashboard] Error \(error)")
                        }
                    }
                } else {
                    VM.isPresentingMarkJobAsInvoiced = true
                }
            },
            onToggleFinished: {
                Task {
                    do {
                        if let company = masterDataManager.currentCompany {
                            if VM.operationStatus == .finished {
                                try await VM.markJobAsUnFinished(
                                    companyId: company.id,
                                    job: job
                                )
                            } else {
                                try await VM.markJobAsFinished(
                                    companyId: company.id,
                                    job: job,
                                    completedByUserId: masterDataManager.user?.id ?? "",
                                    completedByUserName: currentUserDisplayName
                                )
                            }
                        }
                    } catch {
                        print("[][toggle finished dashboard] Error \(error)")
                    }
                }
            }
        )
        .sheet(isPresented: $VM.isPresentingMarkEstiamteAsAccepted) {
            manualEstimateAcceptInfo
        }
        .sheet(isPresented: $VM.isPresentingMarkJobAsInvoiced) {
            manualInvoicedInfo
        }
        
        .safeAreaInset(edge: .bottom) {
            infoBottomBar
        }
    }
    private var infoBottomBar: some View {
        HStack(spacing: 12) {
//            Button {
//                showBillingActionsSheet = true
//            } label: {
//                Label("Actions", systemImage: "ellipsis.circle")
//                    .font(.subheadline.weight(.semibold))
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 12)
//                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
//            }
//            .buttonStyle(.plain)

            Button {
                view = "Planned"
            } label: {
                Label("Planned", systemImage: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
//        .sheet(isPresented: $showBillingActionsSheet) {
//            billingActionsSheet
//                .presentationDetents([.medium, .large])
//        }
    }

    var plannedWebDetailView: some View {
        let summary = VM.dashboardSummary(for: job)

        return ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Planned")
                                    .font(.title3.weight(.semibold))

                                Text("Tasks, visits, work offers, and materials for \(job.internalId).")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: "checklist")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(.thinMaterial, in: Circle())
                        }

                        HStack(spacing: 10) {
                            JobDashboardSummaryChip(
                                title: "Revenue",
                                value: JobDashboardMoneyFormatter.money(summary.plannedRevenueCents),
                                systemImage: "dollarsign.circle"
                            )

                            JobDashboardSummaryChip(
                                title: "Labor",
                                value: JobDashboardMoneyFormatter.money(summary.plannedLaborCents),
                                systemImage: "person.text.rectangle"
                            )

                            JobDashboardSummaryChip(
                                title: "Products",
                                value: JobDashboardMoneyFormatter.money(summary.plannedMaterialPriceCents),
                                systemImage: "cart"
                            )
                        }
                    }
                    .basicCard()

                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Planned Work", systemImage: "square.grid.2x2")

                        Button {
                            view = "Tasks"
                        } label: {
                            JobDashboardNavigationRow(
                                title: "Tasks",
                                subtitle: "\(VM.jobTaskList.count) task(s), \(VM.plannedLaborMinutes) planned minutes.",
                                systemImage: "checklist"
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            view = "Schedule"
                        } label: {
                            JobDashboardNavigationRow(
                                title: "Planned & Scheduled Visits",
                                subtitle: "\(VM.plannedServiceStops.count) planned, \(VM.scheduledServiceStopCount) scheduled.",
                                systemImage: "calendar.badge.clock"
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            view = "Offers"
                        } label: {
                            JobDashboardNavigationRow(
                                title: "Work Offers",
                                subtitle: "\(summary.openOfferCount) open, \(summary.acceptedOfferCount) accepted.",
                                systemImage: "paperplane"
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            view = "Materials"
                        } label: {
                            JobDashboardNavigationRow(
                                title: "Materials",
                                subtitle: "\(VM.shoppingItemList.count) planned item(s), \(VM.purchasedItems.count) purchased item(s).",
                                systemImage: "cart"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .basicCard()

                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Plan Snapshot", systemImage: "doc.text")

                        JobDashboardDetailRow(
                            title: "Planned Service Labor",
                            value: JobDashboardMoneyFormatter.money(summary.plannedServiceStopLaborCents)
                        )

                        JobDashboardDetailRow(
                            title: "Planned Task Labor",
                            value: JobDashboardMoneyFormatter.money(summary.plannedTaskLaborCents)
                        )

                        JobDashboardDetailRow(
                            title: "Planned Material Cost",
                            value: JobDashboardMoneyFormatter.money(summary.plannedMaterialCostCents)
                        )

                        JobDashboardDetailRow(
                            title: "Projected Profit",
                            value: JobDashboardMoneyFormatter.money(summary.plannedProfitCents),
                            valueIsWarning: summary.plannedProfitCents < 0
                        )
                    }
                    .basicCard()

                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button {
                    view = "Plans"
                } label: {
                    Label("Plans", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    view = "Actual"
                } label: {
                    Label("Actual", systemImage: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }

    var historyView: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    sectionHeader("History", systemImage: "clock.arrow.circlepath")
                    Spacer()
                    Text("\(VM.comments.count) comment\(VM.comments.count == 1 ? "" : "s")")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }

                Text("Job comments and activity notes for \(job.internalId).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color.listColor)

            commentsView
        }
    }

    var editInfo: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    editInfoHeaderCard
                    editInfoDetailsCard
                    editInfoStatusCard
                    editInfoPricingCard
                    editInfoDescriptionCard
                    
                    if job.otherCompany {
                        editInfoExternalCompanyCard
                    }
                    
                    Color.clear.frame(height: 96)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
            }
        }
        .safeAreaInset(edge: .bottom) {
            editInfoBottomBar
        }
    }
    
    private var editInfoHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Edit Job Info")
                        .font(.title3.weight(.semibold))
                    
                    Text("\(job.internalId) • \(job.customerName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if !job.type.isEmpty {
                        Text(job.type)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.thinMaterial, in: Capsule())
                    }
                }
                
                Spacer()
                
                Button {
                    resetEditInfoFields()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.body.weight(.semibold))
                        .padding(9)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
            
            Text("Update the job owner, statuses, customer-facing price, planned labor snapshot, and description.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .basicCard()
    }
    
    private var editInfoDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobEditSectionHeader(
                title: "Job Details",
                systemImage: "doc.text"
            )
            
            JobEditInfoReadOnlyRow(
                title: "Date Created",
                value: fullDate(date: job.dateCreated),
                systemImage: "calendar"
            )
            
            JobEditInfoReadOnlyRow(
                title: "Customer",
                value: "\(customer.firstName) \(customer.lastName)",
                systemImage: "person"
            )
            
            if let location = VM.serviceLocation {
                JobEditInfoReadOnlyRow(
                    title: "Service Address",
                    value: location.address.streetAddress,
                    systemImage: "mappin.and.ellipse"
                )
            }
            
            pickerButtonRow(
                title: "Admin / Owner",
                value: selectedAdminId(admin).isEmpty ? "Select Admin" : "\(admin.userName) \(admin.roleName)",
                systemImage: "person.crop.circle",
                isSelected: !selectedAdminId(admin).isEmpty
            ) {
                showAdminSelector.toggle()
            }
            .sheet(isPresented: $showAdminSelector) {
                CompanyUserPicker(
                    dataService: dataService,
                    companyUser: $admin
                )
            }
        }
        .basicCard()
    }
    
    private var editInfoStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobEditSectionHeader(
                title: "Workflow Status",
                systemImage: "flag"
            )

            pickerButtonRow(
                title: "Operation",
                value: operationStatus.rawValue,
                systemImage: operationStatusIcon(operationStatus),
                isSelected: true
            ) {
                showOperationStatusSelector.toggle()
            }
            .sheet(isPresented: $showOperationStatusSelector) {
                JobOperationStatusSelectorSheet(
                    selectedStatus: $operationStatus,
                    onSelect: { selectedStatus in
                        operationStatus = selectedStatus
                        applyBillingSuggestionForOperation(selectedStatus)
                        showOperationStatusSelector = false
                    }
                )
                .presentationDetents([.medium, .large])
            }

            pickerButtonRow(
                title: "Billing",
                value: billingStatus.rawValue,
                systemImage: billingStatusIcon(billingStatus),
                isSelected: true
            ) {
                showBillingStatusSelector.toggle()
            }
            .sheet(isPresented: $showBillingStatusSelector) {
                JobBillingStatusSelectorSheet(
                    selectedStatus: $billingStatus,
                    onSelect: { selectedStatus in
                        billingStatus = selectedStatus
                        applyOperationSuggestionForBilling(selectedStatus)
                        showBillingStatusSelector = false
                    }
                )
                .presentationDetents([.medium, .large])
            }

            Text("Tap a status to choose from the full lifecycle. Selecting one status can suggest the matching status in the other workflow.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .basicCard()
    }
    
    private var editInfoPricingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                JobEditSectionHeader(
                    title: "Pricing & Planned Cost",
                    systemImage: "dollarsign.circle"
                )
                
                Spacer()
                
                Button {
                    useSuggestedEstimateRate()
                } label: {
                    Text("Use Estimate")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Customer Price")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                MoneyTextField(cents: $rate)
            }
            .padding(12)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Planned Labor Cost")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                MoneyTextField(cents: laborCostCentsBinding)
                
                Button {
                    laborCost = String(VM.plannedTotalLaborCents)
                } label: {
                    Label("Use Planned Labor Total", systemImage: "arrow.down.circle")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                
                Text("This is the planned labor snapshot saved on the job. The Actual tab compares this against generated payroll.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            Divider().opacity(0.18)
            
            VStack(spacing: 10) {
                JobEditInfoMoneyRow(
                    title: "Planned Stop Labor",
                    cents: VM.plannedServiceStopLaborCents
                )

                JobEditInfoMoneyRow(
                    title: "Planned Task Labor",
                    cents: VM.plannedTaskLaborCents
                )

                JobEditInfoMoneyRow(
                    title: "Planned Total Labor",
                    cents: VM.plannedTotalLaborCents
                )

                JobEditInfoMoneyRow(
                    title: "Planned Materials",
                    cents: VM.plannedMaterialCostCents
                )

                JobEditInfoMoneyRow(
                    title: "Actual Labor",
                    cents: VM.actualLaborTotalCents
                )

                JobEditInfoMoneyRow(
                    title: "Actual Materials",
                    cents: VM.actualPurchasedMaterialCostCents
                )

                JobEditInfoMoneyRow(
                    title: "Projected Profit",
                    cents: projectedEditProfitCents,
                    valueIsWarning: projectedEditProfitCents < 0
                )
            }
        }
        .basicCard()
    }
    
    private var editInfoDescriptionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobEditSectionHeader(
                title: "Description",
                systemImage: "text.alignleft"
            )
            
            TextField(
                "Describe the work, customer concern, or estimate notes...",
                text: $description,
                axis: .vertical
            )
            .lineLimit(6, reservesSpace: true)
            .modifier(PlainTextFieldModifier())
            
            Text("Use this as the high-level job description. Task-level details should stay in the Tasks tab.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .basicCard()
    }
    
    @ViewBuilder
    private var editInfoExternalCompanyCard: some View {
        if let currentCompany = masterDataManager.currentCompany,
           currentCompany.id == job.receiverId {
            VStack(alignment: .leading, spacing: 12) {
                JobEditSectionHeader(
                    title: "External Company",
                    systemImage: "building.2"
                )
                
                if let otherCompany = VM.senderCompany {
                    CompanyCardView(company: otherCompany)
                }
                
                if let laborContract = VM.laborContract {
                    NavigationLink(
                        value: Route.laborContractDetailView(
                            dataService: dataService,
                            contract: laborContract
                        )
                    ) {
                        JobEditNavigationRow(
                            title: "Labor Contract Details",
                            subtitle: "View the original external work agreement.",
                            systemImage: "doc.text"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .basicCard()
        }
    }
    
    private var editInfoBottomBar: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await saveEditInfoChanges()
                }
            } label: {
                Label("Save Changes", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            
            Button {
                resetEditInfoFields()
                VM.isEdit = false
            } label: {
                Label("Cancel", systemImage: "xmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    private func selectedAdminId(_ companyUser: CompanyUser) -> String {
        companyUser.userId.isEmpty ? companyUser.id : companyUser.userId
    }

    private func applyJobAdmin(_ sourceJob: Job) {
        admin.id = sourceJob.adminId
        admin.userId = sourceJob.adminId
        admin.userName = sourceJob.adminName
    }
    
    private func saveEditInfoChanges() async {
        guard let company = masterDataManager.currentCompany else {
            VM.alertMessage = "Missing Company"
            VM.showAlert = true
            return
        }
        
        do {
            let adminId = selectedAdminId(admin)
            let hasChanges =
            adminId != job.adminId ||
            admin.userName != job.adminName ||
            jobTemplate.name != job.type ||
            operationStatus != job.operationStatus ||
            billingStatus != job.billingStatus ||
            job.rate != rate ||
            laborCost != String(job.laborCost) ||
            description != job.description
            
            guard hasChanges else {
                VM.alertMessage = "No Change Made"
                VM.showAlert = true
                return
            }
            
            try await VM.updateJobInfo(
                companyId: company.id,
                updatingJob: job,
                admin: admin,
                jobTemplate: jobTemplate,
                operationStatus: operationStatus,
                billingStatus: billingStatus,
                rate: rate,
                laborCost: laborCost,
                description: description
            )
            
            VM.isEdit = false
            
            try await VM.onLoad(
                companyId: company.id,
                serviceLocationId: job.serviceLocationId,
                job: job
            )
        } catch {
            print("[][Error Updating Job] Error: \(error)")
            VM.alertMessage = "Could not update job info."
            VM.showAlert = true
        }
    }
    
    private func resetEditInfoFields() {
        applyJobAdmin(job)
        
        jobTemplate.name = job.type
        
        operationStatus = job.operationStatus
        billingStatus = job.billingStatus
        rate = job.rate
        laborCost = String(job.laborCost)
        description = job.description
    }
    
    private func useSuggestedEstimateRate() {
        let plannedLabor = laborCostCentsBinding.wrappedValue > 0
        ? laborCostCentsBinding.wrappedValue
        : VM.plannedTotalLaborCents

        let plannedMaterialsPrice = VM.plannedMaterialPriceCents

        let suggested = Int((Double(plannedLabor) * 2.4).rounded()) + plannedMaterialsPrice

        rate = max(0, suggested)
    }
    
    var taskHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Task List")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text("Plan expected visits, tasks, and reusable task groups before scheduling work.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Text("\(VM.jobTaskList.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
            }
            
            HStack(spacing: 8) {
                Label("\(VM.jobTaskList.count) Tasks", systemImage: "checklist")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
                
                if !job.internalId.isEmpty {
                    Label(job.internalId, systemImage: "number")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    var taskListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Tasks", systemImage: "checklist")
                
                Spacer()
                
                Text("\(VM.jobTaskList.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }
            
            if VM.jobTaskList.isEmpty {
                emptyTaskState
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.jobTaskList) { task in
                        JobTaskCardView(
                            dataService: dataService,
                            jobId: job.id,
                            jobTask: task
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    var addTaskActionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Add Work", systemImage: "plus.circle")
            
            Button {
                VM.isAddTask.toggle()
            } label: {
                addTaskActionLabel(
                    title: "New Task",
                    subtitle: "Add a single custom task to this job.",
                    systemImage: "checkmark.circle"
                )
            }
            .buttonStyle(.plain)
            
            Button {
                VM.isAddTaskGroup.toggle()
            } label: {
                addTaskActionLabel(
                    title: "Task Group",
                    subtitle: "Add a reusable group of tasks to this job.",
                    systemImage: "square.stack.3d.up"
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    func addTaskActionLabel(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 30, height: 30)
                .background(.thinMaterial, in: Circle())
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    var taskBottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.35)
            
            HStack(spacing: 12) {
                Button {
                    VM.isEdit = true
                } label: {
                    Label("Edit", systemImage: "square.and.pencil")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                
                Button {
                    view = "Offers"
                } label: {
                    Label("Offers", systemImage: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }
    
    var emptyTaskState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist.unchecked")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("No tasks added yet.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            
            Text("Add a task or task group to build this job’s scope.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }
    var taskView: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    taskHeaderCard
                    plannedServiceStopsCard
                    taskListCard
                    addTaskActionsCard
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .safeAreaInset(edge: .bottom) {
            taskBottomActionBar
        }
        .sheet(isPresented: $VM.isAddTask, onDismiss: {
            if let company = masterDataManager.currentCompany {
                VM.onDismissAddTaskSheet(
                    companyId: company.id,
                    serviceLocationId: job.serviceLocationId,
                    jobId: job.id
                )
            }
        }) {
            AddNewTaskToJob(
                dataService: dataService,
                jobId: job.id,
                taskTypes: VM.taskTypes,
                customerId: job.customerId,
                serviceLocationId: job.serviceLocationId
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $VM.isAddTaskGroup, onDismiss: {
            if let company = masterDataManager.currentCompany {
                VM.addNewTasks(companyId: company.id, jobId: job.id)
                VM.onDismissAddTaskSheet(
                    companyId: company.id,
                    serviceLocationId: job.serviceLocationId,
                    jobId: job.id
                )
            }
        }) {
            TaskGroupPickerView(
                dataService: dataService,
                tasks: $VM.taskGroupItems
            )
        }
        .sheet(isPresented: $VM.isAddPlannedServiceStop, onDismiss: {
            if let company = masterDataManager.currentCompany {
                Task {
                    do {
                        try await VM.reloadPlannedServiceStops(
                            companyId: company.id,
                            jobId: job.id
                        )
                    } catch {
                        print("[][reloadPlannedServiceStops] Error \(error)")
                    }
                }
            }
        }) {
            if let company = masterDataManager.currentCompany {
                AddJobPlannedServiceStopView(
                    companyId: company.id,
                    jobId: job.id,
                    jobTasks: VM.jobTaskList,
                    existingPlannedStops: VM.plannedServiceStops,
                    dataService: dataService,
                    onSaved: {
                        Task {
                            do {
                                try await VM.reloadPlannedServiceStops(
                                    companyId: company.id,
                                    jobId: job.id
                                )
                            } catch {
                                print("[][planned stop saved reload] Error \(error)")
                            }
                        }
                    }
                )
                .presentationDetents([.medium, .large])
            } else {
                Text("Missing company.")
                    .presentationDetents([.medium])
            }
        }
        .alert("Delete Planned Stop?", isPresented: $VM.showDeletePlannedServiceStopConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        guard let company = masterDataManager.currentCompany,
                              let plannedStop = VM.plannedServiceStopToDelete else {
                            return
                        }

                        try await VM.deletePlannedServiceStop(
                            companyId: company.id,
                            plannedStop: plannedStop
                        )

                        VM.plannedServiceStopToDelete = nil
                    } catch {
                        print("[][delete planned stop] Error \(error)")
                    }
                }
            }

            Button("Cancel", role: .cancel) {
                VM.plannedServiceStopToDelete = nil
            }
        } message: {
            Text("This only removes the planned visit. It does not delete scheduled service stops or tasks.")
        }
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
    
    var editSchedule: some View {
        schedule
    }
    var schedule: some View {
        ZStack {
            if let currentCompany = masterDataManager.currentCompany {
                JobScheduleWorkCenterView(
                    companyId: currentCompany.id,
                    currentUserId: masterDataManager.user?.id ?? "",
                    currentUserName: currentUserDisplayName,
                    job: job,
                    jobTasks: VM.jobTaskList,
                    serviceStops: VM.serviceStops,
                    workOffers: VM.workOffers,
                    serviceLocation: VM.serviceLocation,
                    dataService: dataService,
                    onScheduleServiceStop: {
                        VM.scheduledServiceStopToEdit = nil
                        VM.isPresentServiceStop.toggle()
                    },
                    onEditServiceStop: { serviceStop in
                        VM.scheduledServiceStopToEdit = serviceStop
                        VM.isPresentServiceStop = true
                    },
                    onDeleteServiceStop: { serviceStop in
                        VM.scheduledServiceStopToDelete = serviceStop
                        VM.showDeleteScheduledServiceStopConfirmation = true
                    },
                    onGoToOffers: {
                        view = "Offers"
                    },
                    onReload: {
                        Task {
                            do {
                                try await VM.onLoad(
                                    companyId: currentCompany.id,
                                    serviceLocationId: job.serviceLocationId,
                                    job: job
                                )
                            } catch {
                                print("[][JobDetailView schedule reload] Error \(error)")
                            }
                        }
                    }
                )
            } else {
                ContentUnavailableView(
                    "Missing Company",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Select a company before scheduling work.")
                )
            }
        }
        .sheet(isPresented: $VM.isPresentServiceStop,
               onDismiss: {
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.onDismissOfScheduleServiceStop(
                            companyId: currentCompany.id,
                            serviceLocationId: job.serviceLocationId,
                            job: job
                        )
                        
                        await VM.reloadWorkOffers(
                            companyId: currentCompany.id,
                            jobId: job.id
                        )
                    } catch {
                        print(error)
                    }
                }

                VM.scheduledServiceStopToEdit = nil
            }
        },
               content: {
            if let currentCompany = masterDataManager.currentCompany {
                ScheduleServiceStopView(
                    dataService: dataService,
                    companyId: currentCompany.id,
                    job: job,
                    customerId: job.customerId,
                    customerName: job.customerName,
                    serviceLocationId: job.serviceLocationId,
                    description: job.description,
                    jobTaskList: VM.jobTaskList,
                    plannedServiceStops: VM.plannedServiceStops,
                    editingServiceStop: VM.scheduledServiceStopToEdit,
                    serviceStopTypeUseCase: .jobVisit
                )
                .presentationDetents([.medium, .large])
            } else {
                Text("Missing company.")
                    .presentationDetents([.medium])
            }
        })
        .alert("Delete Scheduled Stop?", isPresented: $VM.showDeleteScheduledServiceStopConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    guard let currentCompany = masterDataManager.currentCompany,
                          let serviceStop = VM.scheduledServiceStopToDelete else {
                        return
                    }

                    do {
                        try await VM.deleteScheduledServiceStopFromJob(
                            companyId: currentCompany.id,
                            jobId: job.id,
                            serviceStop: serviceStop
                        )

                        try await VM.onLoad(
                            companyId: currentCompany.id,
                            serviceLocationId: job.serviceLocationId,
                            job: job
                        )
                    } catch {
                        print("[][delete scheduled service stop] Error \(error)")
                        VM.alertMessage = "Could not delete scheduled service stop."
                        VM.showAlert = true
                    }

                    VM.scheduledServiceStopToDelete = nil
                }
            }

            Button("Cancel", role: .cancel) {
                VM.scheduledServiceStopToDelete = nil
            }
        } message: {
            Text("This deletes the scheduled stop and releases its selected job tasks back to Draft.")
        }
        
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    view = "Offers"
                } label: {
                    Label("Offers", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                
                Button {
                    view = "Materials"
                } label: {
                    Label("Materials", systemImage: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
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
                        if jobDeleteLocked {
                            VM.alertMessage = "Finished jobs cannot be deleted."
                            VM.showAlert = true
                        } else {
                            showDeleteConfirmation.toggle()
                        }
                    }, label: {
                        Text("Delete")
                            .modifier(DismissButtonModifier())
                    })
                    .disabled(jobDeleteLocked)
                }
            }
        }
        .ddBottomBar()
    }
    var manualEstimateAcceptInfo: some View {
            ZStack {
                Color.listColor.ignoresSafeArea()
                ScrollView(showsIndicators:false){
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Accept Estimate")
                                        .font(.title3.weight(.semibold))

                                    Text("\(job.internalId) • \(job.customerName)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 36, height: 36)
                                    .background(.thinMaterial, in: Circle())
                            }

                            Text("Record when the estimate was accepted and who approved it. This moves the job billing workflow forward.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .basicCard()

                        VStack(alignment: .leading, spacing: 14) {
                            Label("Acceptance Details", systemImage: "doc.text")
                                .font(.headline.weight(.semibold))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date Accepted")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                DatePicker(
                                    "Date Accepted",
                                    selection: $VM.estiamtedAcceptedDate,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Who Accepted / Notes")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                TextField(
                                    "Example: Customer approved by phone",
                                    text: $VM.estimateAcceptedNotes,
                                    axis: .vertical
                                )
                                .lineLimit(3, reservesSpace: true)
                                .modifier(PlainTextFieldModifier())

                                Text("Add the customer name, approval method, or any internal note you want saved with this acceptance.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .basicCard()

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Estimate Accepted")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        VM.isPresentingMarkEstiamteAsAccepted = false
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button {
                        Task {
                            do {
                                print("[JobDetailView][basicCard][markEstimateAsAccepted] 1")
                                guard let company = masterDataManager.currentCompany else {
                                    VM.alertMessage = "Missing Company"
                                    VM.showAlert = true
                                    return
                                }
                                print("[JobDetailView][basicCard][markEstimateAsAccepted] 2")

                                guard !VM.estimateAcceptedNotes
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .isEmpty else {
                                    VM.alertMessage = "Please provide who accepted or acceptance notes."
                                    VM.showAlert = true
                                    return
                                }
                                print("[JobDetailView][basicCard][markEstimateAsAccepted] 3")

                                try await VM.markEstimateAsAccepted(
                                    companyId: company.id,
                                    job: job,
                                    acceptedByUserId: masterDataManager.user?.id ?? "",
                                    acceptedByUserName: currentUserDisplayName
                                )

                                VM.alertMessage = "Successfully Accepted"
                                print(VM.alertMessage)
                                VM.showAlert = true
                                VM.isPresentingMarkEstiamteAsAccepted = false
                                print("[JobDetailView][basicCard][markEstimateAsAccepted] Success")
                            } catch {
                                print("")
                                print("Job - markEstimateAsAccepted - [JobDetailView]")
                                print(error)
                                print("")

                                VM.alertMessage = "Could not mark estimate as accepted."
                                VM.showAlert = true
                            }
                        }
                    } label: {
                        Label("Mark Accepted", systemImage: "checkmark.circle")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        VM.isPresentingMarkEstiamteAsAccepted = false
                    } label: {
                        Label("Cancel", systemImage: "xmark.circle")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.regularMaterial)
            }
        
    }
    
    var manualInvoicedInfo: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Mark Job Invoiced")
                                    .font(.title3.weight(.semibold))

                                Text("\(job.internalId) • \(job.customerName)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Image(systemName: "doc.badge.plus")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(.thinMaterial, in: Circle())
                        }

                        Text("Record the invoice reference and notes for this job. This marks the job billing status as invoiced.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .basicCard()

                    VStack(alignment: .leading, spacing: 14) {
                        Label("Invoice Details", systemImage: "doc.text")
                            .font(.headline.weight(.semibold))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Invoice Reference")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            TextField(
                                "Example: INV-1048, QuickBooks ref, or manual receipt number",
                                text: $VM.invoiceRef
                            )
                            .textInputAutocapitalization(.characters)
                            .modifier(PlainTextFieldModifier())

                            Text("Use the invoice number, QuickBooks reference, or any payment record you want tied to this job.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Invoice Notes")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            TextField(
                                "Optional notes...",
                                text: $VM.invoiceNotes,
                                axis: .vertical
                            )
                            .lineLimit(4, reservesSpace: true)
                            .modifier(PlainTextFieldModifier())

                            Text("Add payment method, customer communication, or internal billing notes.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .basicCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Billing Snapshot", systemImage: "dollarsign.circle")
                            .font(.headline.weight(.semibold))
                        if let status = VM.billingStatus {
                            JobManualInvoiceSummaryRow(
                                title: "Current Billing Status",
                                value: status.rawValue
                            )
                        }
                        JobManualInvoiceSummaryRow(
                            title: "Customer Price",
                            value: JobManualInvoiceMoneyFormatter.money(job.rate)
                        )

                        JobManualInvoiceSummaryRow(
                            title: "Planned Labor",
                            value: JobManualInvoiceMoneyFormatter.money(job.laborCost)
                        )

                        Text("This is a manual invoice record. Full customer billing and payment collection can be built on top of this later.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .basicCard()

                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Invoice Job")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    VM.isPresentingMarkJobAsInvoiced = false
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button {
                    Task {
                        do {
                            guard let company = masterDataManager.currentCompany else {
                                VM.alertMessage = "Missing Company"
                                VM.showAlert = true
                                return
                            }

                            guard VM.billingStatus != .invoiced &&
                                    VM.billingStatus != .paid &&
                                    VM.billingStatus != .comped else {
                                VM.alertMessage = "This job is already invoiced, paid, or comped."
                                VM.showAlert = true
                                return
                            }

                            guard !VM.invoiceRef
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty else {
                                VM.alertMessage = "Please provide an invoice reference."
                                VM.showAlert = true
                                return
                            }

                            try await VM.markJobAsInvoiced(
                                companyId: company.id,
                                job: job
                            )

                            VM.alertMessage = "Job marked as invoiced."
                            VM.showAlert = true
                            VM.isPresentingMarkJobAsInvoiced = false
                        } catch {
                            print("")
                            print("Job - markJobAsInvoiced - [JobDetailView]")
                            print(error)
                            print("")

                            VM.alertMessage = "Could not mark job as invoiced."
                            VM.showAlert = true
                        }
                    }
                } label: {
                    Label("Mark Invoiced", systemImage: "doc.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    VM.isPresentingMarkJobAsInvoiced = false
                } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        
    }
    var currentUserDisplayName: String {
        let first = masterDataManager.user?.firstName ?? ""
        let last = masterDataManager.user?.lastName ?? ""
        let fullName = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !fullName.isEmpty {
            return fullName
        }
        
        return masterDataManager.user?.email ?? "Admin"
    }
    
    var commentsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Comments")
                            .font(.title3.weight(.semibold))
                        Text("\(VM.comments.filter { !$0.resolved }.count) open")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            if let company = masterDataManager.currentCompany {
                                await VM.loadComments(
                                    companyId: company.id,
                                    jobId: job.id
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.body.weight(.semibold))
                            .frame(width: 36, height: 36)
                            .background(.thinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Refresh comments")
                }
                
                Picker("Comment Filter", selection: $VM.commentFilter) {
                    ForEach(JobCommentFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading, spacing: 10) {
                    TextEditor(text: $VM.newComment)
                        .frame(minHeight: 92)
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                        )
                    
                    Button {
                        Task {
                            if let company = masterDataManager.currentCompany {
                                await VM.addComment(
                                    companyId: company.id,
                                    jobId: job.id,
                                    userId: masterDataManager.user?.id ?? "",
                                    userName: currentUserDisplayName
                                )
                            }
                        }
                    } label: {
                        if VM.addingComment {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        } else {
                            Label("Add Comment", systemImage: "plus.message.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        VM.addingComment ||
                        VM.newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        masterDataManager.currentCompany == nil
                    )
                }
                
                if VM.commentsLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else if VM.filteredComments.isEmpty {
                    ContentUnavailableView(
                        "No Comments",
                        systemImage: "text.bubble",
                        description: Text("No comments in this filter.")
                    )
                    .padding(.vertical, 24)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(VM.filteredComments) { comment in
                            jobCommentRow(comment)
                        }
                    }
                }
            }
            .padding(14)
        }
        .background(Color.listColor.ignoresSafeArea())
    }
    
    @ViewBuilder
    func jobCommentRow(_ comment: JobComment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(comment.userName ?? comment.authorName ?? "Unknown")
                        .font(.subheadline.weight(.semibold))
                    Text(commentDateText(comment.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(comment.resolved ? "Resolved" : "Open")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(comment.resolved ? Color.green : Color.orange)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule()
                            .fill((comment.resolved ? Color.green : Color.orange).opacity(0.12))
                    )
            }
            
            Text(comment.comment)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                Task {
                    if let company = masterDataManager.currentCompany {
                        await VM.setCommentResolved(
                            companyId: company.id,
                            jobId: job.id,
                            commentId: comment.id,
                            resolved: !comment.resolved
                        )
                    }
                }
            } label: {
                Label(
                    comment.resolved ? "Reopen" : "Mark Resolved",
                    systemImage: comment.resolved ? "arrow.uturn.left.circle" : "checkmark.circle"
                )
                .font(.caption.weight(.semibold))
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
    
    func commentDateText(_ date: Date?) -> String {
        guard let date else { return "Pending" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
    
    var offersView: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                if let company = masterDataManager.currentCompany {
                    JobWorkOffersView(
                        companyId: company.id,
                        currentUserId: masterDataManager.user?.id ?? "",
                        currentUserName: currentUserDisplayName,
                        job: job,
                        jobTasks: VM.jobTaskList,
                        serviceLocation: VM.serviceLocation,
                        workOffers: VM.workOffers,
                        dataService: dataService,
                        onReload: {
                            Task {
                                do {
                                    try await VM.onLoad(
                                        companyId: company.id,
                                        serviceLocationId: job.serviceLocationId,
                                        job: job
                                    )
                                } catch {
                                    print("[][JobDetailView offers reload] Error \(error)")
                                }
                            }
                        }
                    )
                } else {
                    ContentUnavailableView(
                        "Missing Company",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Select a company before creating work offers.")
                    )
                    .padding()
                }
                
                Color.clear.frame(height: 90)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    view = "Tasks"
                } label: {
                    Label("Plan", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                
                Button {
                    view = "Schedule"
                } label: {
                    Label("Schedule", systemImage: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }
    var actualWorkView: some View {
        ZStack {
            if let currentCompany = masterDataManager.currentCompany {
                JobActualWorkView(
                    job: job,
                    jobTasks: VM.jobTaskList,
                    serviceStops: VM.serviceStops,
                    payLineItems: VM.actualPayLineItems,
                    dataService: dataService
                )
                .refreshable {
                    do {
                        try await VM.onLoad(
                            companyId: currentCompany.id,
                            serviceLocationId: job.serviceLocationId,
                            job: job
                        )
                    } catch {
                        print("[][actualWorkView refresh] Error \(error)")
                    }
                }
            } else {
                ContentUnavailableView(
                    "Missing Company",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Select a company before reviewing actual work.")
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    view = "Materials"
                } label: {
                    Label("Materials", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                
                Button {
                    view = "Billing"
                } label: {
                    Label("Billing", systemImage: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }
    
    var shoppingListView: some View {
        ZStack {
            JobMaterialsView(
                shoppingItems: VM.shoppingItemList,
                purchasedItems: VM.purchasedItems,
                plannedMaterialCostCents: VM.plannedMaterialCostCents,
                plannedMaterialPriceCents: VM.plannedMaterialPriceCents,
                actualPurchasedMaterialCostCents: VM.actualPurchasedMaterialCostCents,
                billablePurchasedMaterialPriceCents: VM.billablePurchasedMaterialPriceCents,
                onAddShoppingItem: {
                    VM.isAddShoppingList.toggle()
                },
                onAttachPurchasedItem: {
                    VM.isPresentPurchasedItemSelector.toggle()
                },
                onEditShoppingItem: { item in
                    VM.editShoppingItem = item
                },
                onDeleteShoppingItem: { item in
                    if let currentCompany = masterDataManager.currentCompany {
                        VM.deleteShoppingListItem(
                            companyId: currentCompany.id,
                            jobId: job.id,
                            item: item
                        )
                        
                        VM.onDismissAddShoppingListItem(
                            companyId: currentCompany.id,
                            serviceLocationId: job.serviceLocationId,
                            jobId: job.id
                        )
                    }
                }
            )
            
            VStack {
                Spacer()
                
                HStack {
                    Button {
                        view = "Schedule"
                    } label: {
                        Label("Schedule", systemImage: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        view = "Actual"
                    } label: {
                        Label("Actual", systemImage: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.regularMaterial)
            }
        }
        .sheet(isPresented: $VM.isAddShoppingList, onDismiss: {
            if let currentCompany = masterDataManager.currentCompany {
                VM.onDismissAddShoppingListItem(
                    companyId: currentCompany.id,
                    serviceLocationId: job.serviceLocationId,
                    jobId: job.id
                )
            }
        }) {
            AddNewShoppingListItemToJob(
                dataService: dataService,
                job: job
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $VM.isPresentPurchasedItemSelector) {
            JobPurchasedItemSelectorView(
                items: VM.availablePurchasedItems,
                categoryByPurchasedItemId: VM.availablePurchasedItemCategories,
                isLoading: VM.isLoadingAvailablePurchasedItems,
                onLoad: { startDate, endDate in
                    guard let currentCompany = masterDataManager.currentCompany else { return }
                    try await VM.loadUnassignedPurchasedItems(
                        companyId: currentCompany.id,
                        startDate: startDate,
                        endDate: endDate
                    )
                },
                onAttach: { items in
                    guard let currentCompany = masterDataManager.currentCompany else { return }
                    try await VM.attachPurchasedItemsToJob(
                        companyId: currentCompany.id,
                        job: job,
                        items: items
                    )
                    job.purchasedItemsIds = Array(Set((job.purchasedItemsIds ?? []) + items.map(\.id)))
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $VM.editShoppingItem, onDismiss: {
            if let currentCompany = masterDataManager.currentCompany {
                VM.onDismissAddShoppingListItem(
                    companyId: currentCompany.id,
                    serviceLocationId: job.serviceLocationId,
                    jobId: job.id
                )
            }
        }) { item in
            EditShoppingListItem(
                dataService: dataService,
                item: item
            )
        }
    }
    
    // MARK: billingView
    var billingView: some View {
        JobBillingView(
            job: job,
            plannedLaborCents: VM.plannedTotalLaborCents,
            actualPayrollCents: VM.actualLaborTotalCents,
            plannedMaterialCostCents: VM.plannedMaterialCostCents,
            actualMaterialCostCents: VM.actualPurchasedMaterialCostCents,
            plannedMaterialPriceCents: VM.plannedMaterialPriceCents,
            billablePurchasedMaterialPriceCents: VM.billablePurchasedMaterialPriceCents,
            operationStatus: VM.operationStatus,
            billingStatus: VM.billingStatus,
            invoiceDate: VM.invoiceDate,
            invoiceRef: VM.invoiceRef,
            invoiceType: VM.invoiceType,
            invoiceNotes: VM.invoiceNotes,
            onSendEstimate: {
                Task {
                    do {
                        if let company = masterDataManager.currentCompany {
                            try await VM.sendEstiamteToCustomer(
                                companyId: company.id,
                                job: job
                            )

                            VM.alertMessage = "Estimate Sent To Customer"
                            VM.showAlert = true
                        }
                    } catch {
                        print("[][billing send estimate] Error \(error)")
                        VM.alertMessage = "Could not send estimate."
                        VM.showAlert = true
                    }
                }
            },
            onMarkEstimateAccepted: {
                VM.isPresentingMarkEstiamteAsAccepted = true
            },
            onMarkInvoiced: {
                VM.isPresentingMarkJobAsInvoiced = true
            },
            onMarkNotInvoiced: {
                Task {
                    do {
                        if let company = masterDataManager.currentCompany {
                            try await VM.markJobAsNotInvoiced(
                                companyId: company.id,
                                job: job
                            )

                            try await VM.onLoad(
                                companyId: company.id,
                                serviceLocationId: job.serviceLocationId,
                                job: job
                            )
                        }
                    } catch {
                        print("[][billing mark not invoiced] Error \(error)")
                        VM.alertMessage = "Could not mark job as not invoiced."
                        VM.showAlert = true
                    }
                }
            },
            onGoToMaterials: {
                view = "Materials"
            },
            onGoToActual: {
                view = "Actual"
            }
        )
        .sheet(isPresented: $VM.isPresentingMarkEstiamteAsAccepted) {
            manualEstimateAcceptInfo
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $VM.isPresentingMarkJobAsInvoiced) {
            manualInvoicedInfo
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSaveJobAsTemplateSheet) {
            if let company = masterDataManager.currentCompany {
                SaveJobAsTemplateSheet(
                    companyId: company.id,
                    job: job,
                    plannedServiceStops: VM.plannedServiceStops,
                    jobTasks: VM.jobTaskList,
                    shoppingItems: VM.shoppingItemList,
                    dataService: dataService
                )
                .presentationDetents([.medium, .large])
            } else {
                Text("Missing company.")
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showDuplicateJobSheet) {
            if let company = masterDataManager.currentCompany {
                DuplicateJobSheet(
                    companyId: company.id,
                    sourceJob: job,
                    plannedServiceStops: VM.plannedServiceStops,
                    jobTasks: VM.jobTaskList,
                    shoppingItems: VM.shoppingItemList,
                    dataService: dataService
                )
                .presentationDetents([.large])
            } else {
                Text("Missing company.")
                    .presentationDetents([.medium])
            }
        }
        .safeAreaInset(edge: .bottom) {
            billingBottomBar
        }
    }
    func pickerButtonRow(
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
    func workflowStatusButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isSelected ? .accent : .secondary)
                    .frame(width: 30, height: 30)
                    .background(.thinMaterial, in: Circle())

                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Text("Current")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                }
            }
            .padding(12)
            .background(
                isSelected
                ? Color.accentColor.opacity(0.12)
                : Color.primary.opacity(0.045),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.06),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    func operationStatusIcon(_ status: JobOperationStatus) -> String {
        switch status {
        case .draft:
            return "doc"
        case .estimatePending:
            return "doc.text.magnifyingglass"
        case .unscheduled:
            return "calendar.badge.exclamationmark"
        case .scheduled:
            return "calendar.badge.checkmark"
        case .inProgress:
            return "clock.arrow.circlepath"
        case .finished:
            return "checkmark.seal"
        case .waitingForParts:
            return "shippingbox"
        }
    }

    func billingStatusIcon(_ status: JobBillingStatus) -> String {
        switch status {
        case .draft:
            return "doc"
        case .estimate:
            return "paperplane"
        case .accepted:
            return "checkmark.circle"
        case .inProgress:
            return "clock"
        case .invoiced:
            return "doc.badge.plus"
        case .paid:
            return "dollarsign.circle"
        case .comped:
            return "giftcard"
        case .expired:
            return "xmark.circle"
        case .rejected:
            return "xmark.octagon"
        }
    }
    private func applyBillingSuggestionForOperation(_ status: JobOperationStatus) {
        switch status {
        case .draft:
            billingStatus = .draft

        case .estimatePending:
            if billingStatus == .draft {
                billingStatus = .draft
            }

        case .unscheduled:
            if billingStatus == .draft {
                billingStatus = .estimate
            }

        case .scheduled:
            if billingStatus == .draft || billingStatus == .estimate {
                billingStatus = .accepted
            }

        case .inProgress:
            if billingStatus == .draft || billingStatus == .estimate || billingStatus == .accepted {
                billingStatus = .inProgress
            }

        case .waitingForParts:
            if billingStatus == .draft || billingStatus == .estimate {
                billingStatus = .accepted
            }

        case .finished:
            if billingStatus == .draft || billingStatus == .estimate || billingStatus == .accepted {
                billingStatus = .inProgress
            }
        }
    }

    private func applyOperationSuggestionForBilling(_ status: JobBillingStatus) {
        switch status {
        case .draft:
            if operationStatus == .finished {
                operationStatus = .estimatePending
            }

        case .estimate:
            if operationStatus == .estimatePending {
                operationStatus = .unscheduled
            }

        case .accepted:
            if operationStatus == .estimatePending || operationStatus == .unscheduled {
                operationStatus = .unscheduled
            }

        case .inProgress:
            if operationStatus == .estimatePending || operationStatus == .unscheduled {
                operationStatus = .scheduled
            }

        case .invoiced:
            if operationStatus != .finished {
                operationStatus = .finished
            }

        case .paid:
            operationStatus = .finished

        case .comped:
            operationStatus = .finished

        case .expired:
            if operationStatus != .finished {
                operationStatus = .estimatePending
            }
        case .rejected:
            if operationStatus != .finished {
                operationStatus = .estimatePending
            }
        }
    }
    private var laborCostCentsBinding: Binding<Int> {
        Binding(
            get: {
                Int(laborCost) ?? 0
            },
            set: { newValue in
                laborCost = String(newValue)
            }
        )
    }
    private var projectedEditProfitCents: Int {
        rate - (laborCostCentsBinding.wrappedValue + VM.plannedMaterialCostCents)
    }
    
}

private extension View {
    func ddCard() -> some View {
        self
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
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
private struct JobEditSectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }
}
private struct JobOperationStatusSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedStatus: JobOperationStatus
    let onSelect: (JobOperationStatus) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(JobOperationStatus.allCases, id: \.self) { status in
                        Button {
                            onSelect(status)
                            dismiss()
                        } label: {
                            JobStatusSelectorRow(
                                title: status.rawValue,
                                subtitle: operationStatusSubtitle(status),
                                systemImage: operationStatusIcon(status),
                                isSelected: selectedStatus == status
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Operation Status")
                } footer: {
                    Text("Operation status describes where the job is in the work lifecycle.")
                }
            }
            .navigationTitle("Operation Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func operationStatusIcon(_ status: JobOperationStatus) -> String {
        switch status {
        case .draft:
            return "doc"
        case .estimatePending:
            return "doc.text.magnifyingglass"
        case .unscheduled:
            return "calendar.badge.exclamationmark"
        case .scheduled:
            return "calendar.badge.checkmark"
        case .inProgress:
            return "clock.arrow.circlepath"
        case .finished:
            return "checkmark.seal"
        case .waitingForParts:
            return "shippingbox"
        }
    }

    private func operationStatusSubtitle(_ status: JobOperationStatus) -> String {
        switch status {
        case .draft:
            return "The job is still being drafted."
        case .estimatePending:
            return "The job is still being scoped or estimated."
        case .unscheduled:
            return "The estimate or job exists, but work has not been scheduled."
        case .scheduled:
            return "Work has been scheduled on one or more service stops."
        case .inProgress:
            return "Work has started or is actively being handled."
        case .finished:
            return "The work is complete and ready for billing review."
        case .waitingForParts:
            return "Work is paused until materials or parts are available."
        }
    }
}

private struct JobBillingStatusSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedStatus: JobBillingStatus
    let onSelect: (JobBillingStatus) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(JobBillingStatus.allCases, id: \.self) { status in
                        Button {
                            onSelect(status)
                            dismiss()
                        } label: {
                            JobStatusSelectorRow(
                                title: status.rawValue,
                                subtitle: billingStatusSubtitle(status),
                                systemImage: billingStatusIcon(status),
                                isSelected: selectedStatus == status
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Billing Status")
                } footer: {
                    Text("Billing status describes where the customer-facing money workflow stands.")
                }
            }
            .navigationTitle("Billing Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func billingStatusIcon(_ status: JobBillingStatus) -> String {
        switch status {
        case .draft:
            return "doc"
        case .estimate:
            return "paperplane"
        case .accepted:
            return "checkmark.circle"
        case .inProgress:
            return "clock"
        case .invoiced:
            return "doc.badge.plus"
        case .paid:
            return "dollarsign.circle"
        case .comped:
            return "giftcard"
        case .expired:
            return "xmark.circle"
        case .rejected:
            return "xmark.octagon"
        }
    }

    private func billingStatusSubtitle(_ status: JobBillingStatus) -> String {
        switch status {
        case .draft:
            return "Billing has not been prepared yet."
        case .estimate:
            return "An estimate has been created or sent."
        case .accepted:
            return "The customer has accepted the estimate."
        case .inProgress:
            return "Work is underway before final invoice."
        case .invoiced:
            return "The customer has been invoiced."
        case .paid:
            return "The customer has paid."
        case .comped:
            return "The company absorbed the cost; no customer invoice is expected."
        case .expired:
            return "The estimate or billing window has expired."
        case .rejected:
            return "The customer rejected this work, but it can stay visible for follow-up."
        }
    }
}

private struct JobStatusSelectorRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(isSelected ? .accent : .secondary)
                .frame(width: 32, height: 32)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}
private struct JobEditInfoReadOnlyRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 32)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value.isEmpty ? "-" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct JobEditInfoMoneyRow: View {
    let title: String
    let cents: Int
    var valueIsWarning: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(JobEditInfoMoneyFormatter.money(cents))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueIsWarning ? .orange : .primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct JobEditNavigationRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 32)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private enum JobEditInfoMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

private extension View {
    
    func basicCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
    }
}
private struct JobManualInvoiceSummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value.isEmpty ? "-" : value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }
}

private enum JobManualInvoiceMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

// MARK: Planned Service Stops
extension JobDetailView {
    var plannedServiceStopsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Planned Service Stops", systemImage: "calendar.badge.clock")

                Spacer()

                Text("\(VM.plannedServiceStops.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if VM.plannedServiceStops.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text("No planned service stops yet.")
                        .font(.subheadline.weight(.semibold))

                    Text("Add the visits you expect this job to need before scheduling real service stops.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.plannedServiceStops.sorted(by: { $0.sortOrder < $1.sortOrder })) { plannedStop in
                        plannedServiceStopRow(plannedStop)
                    }
                }
            }

            Button {
                VM.isAddPlannedServiceStop = true
            } label: {
                addTaskActionLabel(
                    title: "Add Planned Stop",
                    subtitle: "Plan an expected job visit before scheduling it.",
                    systemImage: "calendar.badge.plus"
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    func plannedServiceStopRow(_ plannedStop: JobPlannedServiceStop) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: plannedStop.serviceStopTypeImage.isEmpty ? "calendar" : plannedStop.serviceStopTypeImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(plannedStop.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("\(plannedStop.serviceStopTypeName) • \(plannedStop.estimatedMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let plannedLaborCostCents = plannedStop.plannedLaborCostCents,
                   plannedLaborCostCents > 0 {
                    Text("Planned labor: \(JobEditInfoMoneyFormatter.money(plannedLaborCostCents))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if !plannedStop.description.isEmpty {
                    Text(plannedStop.description)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }

                if !plannedStop.taskIds.isEmpty {
                    Label("\(plannedStop.taskIds.count) linked task(s)", systemImage: "checklist")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                VM.plannedServiceStopToDelete = plannedStop
                VM.showDeletePlannedServiceStopConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    private var billingBottomBar: some View {
        HStack(spacing: 12) {
            Button {
                view = "Actual"
            } label: {
                Label("Actual", systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                showBillingActionsSheet = true
            } label: {
                Label("Actions", systemImage: "ellipsis.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                view = "Plans"
            } label: {
                Label("Plans", systemImage: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .sheet(isPresented: $showBillingActionsSheet) {
            billingActionsSheet
                .presentationDetents([.medium, .large])
        }
    }
    private var billingActionsSheet: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Job Actions")
                                        .font(.title3.weight(.semibold))

                                    Text("\(job.internalId) • \(job.customerName)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "ellipsis.circle")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 36, height: 36)
                                    .background(.thinMaterial, in: Circle())
                            }

                            Text("Use these actions to manage billing, templates, duplication, and job cleanup.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .basicCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Billing", systemImage: "doc.text")
                                .font(.headline.weight(.semibold))

                            jobBillingActionRow(
                                title: "Send Estimate",
                                subtitle: "Send or resend the customer estimate.",
                                systemImage: "paperplane"
                            ) {
                                showBillingActionsSheet = false

                                Task {
                                    do {
                                        if let company = masterDataManager.currentCompany {
                                            try await VM.sendEstiamteToCustomer(
                                                companyId: company.id,
                                                job: job
                                            )

                                            VM.alertMessage = "Estimate Sent To Customer"
                                            VM.showAlert = true
                                        }
                                    } catch {
                                        print("[][billing actions send estimate] Error \(error)")
                                        VM.alertMessage = "Could not send estimate."
                                        VM.showAlert = true
                                    }
                                }
                            }

                            jobBillingActionRow(
                                title: "Mark Estimate Accepted",
                                subtitle: "Record manual acceptance details.",
                                systemImage: "checkmark.circle"
                            ) {
                                showBillingActionsSheet = false
                                VM.isPresentingMarkEstiamteAsAccepted = true
                            }

                            if VM.billingStatus == .invoiced {
                                jobBillingActionRow(
                                    title: "Mark Not Invoiced",
                                    subtitle: "Undo manual invoiced status.",
                                    systemImage: "arrow.uturn.backward.circle"
                                ) {
                                    showBillingActionsSheet = false

                                    Task {
                                        do {
                                            if let company = masterDataManager.currentCompany {
                                                try await VM.markJobAsNotInvoiced(
                                                    companyId: company.id,
                                                    job: job
                                                )
                                            }
                                        } catch {
                                            print("[][billing actions mark not invoiced] Error \(error)")
                                            VM.alertMessage = "Could not mark job as not invoiced."
                                            VM.showAlert = true
                                        }
                                    }
                                }
                            } else {
                                jobBillingActionRow(
                                    title: "Mark Invoiced",
                                    subtitle: "Record manual invoice reference and notes.",
                                    systemImage: "doc.badge.plus"
                                ) {
                                    showBillingActionsSheet = false
                                    VM.isPresentingMarkJobAsInvoiced = true
                                }
                            }
                        }
                        .basicCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Reuse", systemImage: "square.stack.3d.up")
                                .font(.headline.weight(.semibold))

                            jobBillingActionRow(
                                title: "Save As Template",
                                subtitle: "Save this job plan for future jobs.",
                                systemImage: "doc.badge.plus"
                            ) {
                                showBillingActionsSheet = false
                                showSaveJobAsTemplateSheet = true
                            }

                            jobBillingActionRow(
                                title: "Duplicate Job",
                                subtitle: "Create a new draft copy from this job.",
                                systemImage: "doc.on.doc"
                            ) {
                                showBillingActionsSheet = false
                                showDuplicateJobSheet = true
                            }
                        }
                        .basicCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Manage", systemImage: "gearshape")
                                .font(.headline.weight(.semibold))

                            jobBillingActionRow(
                                title: "Edit Job Info",
                                subtitle: "Change admin, status, price, labor snapshot, or description.",
                                systemImage: "square.and.pencil"
                            ) {
                                showBillingActionsSheet = false
                                view = "Plans"
                                VM.isEdit = true
                            }

                            jobBillingActionRow(
                                title: VM.operationStatus == .finished ? "Mark Unfinished" : "Mark Finished",
                                subtitle: VM.operationStatus == .finished ? "Move this job back out of finished status." : "Mark this job's work as finished.",
                                systemImage: VM.operationStatus == .finished ? "xmark.circle" : "checkmark.seal"
                            ) {
                                showBillingActionsSheet = false

                                Task {
                                    do {
                                        if let company = masterDataManager.currentCompany {
                                            if VM.operationStatus == .finished {
                                                try await VM.markJobAsUnFinished(
                                                    companyId: company.id,
                                                    job: job
                                                )
                                            } else {
                                                try await VM.markJobAsFinished(
                                                    companyId: company.id,
                                                    job: job,
                                                    completedByUserId: masterDataManager.user?.id ?? "",
                                                    completedByUserName: currentUserDisplayName
                                                )
                                            }
                                        }
                                    } catch {
                                        print("[][billing actions toggle finished] Error \(error)")
                                        VM.alertMessage = "Could not update job status."
                                        VM.showAlert = true
                                    }
                                }
                            }

                            jobBillingDeleteActionRow(disabled: jobDeleteLocked) {
                                pendingDeleteConfirmation = true
                                showBillingActionsSheet = false
                            }
                        }
                        .basicCard()

                        Color.clear.frame(height: 28)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showBillingActionsSheet = false
                    }
                }
            }
        }
    }
    private func jobBillingActionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func jobBillingDeleteActionRow(
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Delete Job")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)

                    Text(disabled ? "Finished jobs cannot be deleted." : "Delete this job and related planned work.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.55 : 1)
    }
}
