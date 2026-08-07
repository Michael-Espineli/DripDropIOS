//
//  JobListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/11/24.
//
//



import SwiftUI
import Contacts

struct JobListView: View{    
    
    init(dataService:any ProductionDataServiceProtocol){
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject private var jobVM : JobViewModel
    @StateObject var companyUserVM = CompanyUserViewModel()

    @State var selectedDocumentUrl:URL? = nil
    @State private var jobs:[Job] = []
    //    @State private var sortOrder = [KeyPathComparator(\Customer.lastName, order: .forward)]
    
    @State private var isPresented: Bool = false
    @State private var editing: Bool = false
    @State private var isLoading: Bool = false

    @State private var nav: Bool = false
    @State var showActive:Bool = true
    
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    @State var showCustomerPicker:Bool = false
    
    @State var showSearch:Bool = false
    @State var showAddNew:Bool = false
    @State private var pickerType:NewCustomerPickerType? = nil
    @State private var selectedPickerType:NewCustomerPickerType? = nil
    @State var showConfirmationSheet:Bool = false
    
    @State var selectedContact:CNContact? = nil
    @State var showFilters:Bool = false
    @State var showCustomerUploadScreen:Bool = false
    @State var recievdJobId:String? = nil
    
    @State var startDate:Date = Date()
    @State var endDate:Date = Date()
    
    @State var selectedStatus:[JobOperationStatus] = [.scheduled, .unscheduled, .estimatePending, .inProgress]
    @State var techIds:[String] = []
    @State private var showCreateJobOptions: Bool = false
    @State private var showCreateBlankJob: Bool = false
    @State private var showCreateFromTemplate: Bool = false
    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
            icons
        }
        .navigationTitle("Job List")
        .task {
            if let company = masterDataManager.currentCompany {
                
                do {
                    techIds = []
                    try await companyUserVM.getAllCompanyUsersByStatus(companyId: company.id, status: "Active")
                    for companyUser in companyUserVM.companyUsers {
                        techIds.append(companyUser.userId)
                    }
                    startDate = Calendar.current.date(byAdding: .day, value: -300, to: Date())!
                    jobVM.addListenerForAllJobsOperations(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                    
                } catch {
                    print("Error - [JobListView]")
                    print(error)
                }
                
            }
        }
        .onDisappear(perform: {
            jobVM.removeListenerForJob()
        })
//        .onChange(of: jobVM.workOrders, perform: { list in
//            print("Change in WorkOrders")
//            jobs = list
//        })
        .onChange(of: masterDataManager.selectedID, perform: { id in
            if let selectedId = id {
                Task{
                    do {
                        if let company = masterDataManager.currentCompany {
                            try await jobVM.getSingleWorkOrder(companyId: company.id, WorkOrderId: selectedId)
                            masterDataManager.selectedJob = jobVM.workOrder
                            print("Successfully Get Customer")
                        }
                    } catch {
                        print("Failed to Get Customer")
                    }
                }
            }
        })
        .alert(isPresented:$showAlert) {
            Alert(
                title: Text("\(alertMessage)"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting...")
                },
                secondaryButton: .cancel()
            )
        }
        
        .onChange(of: selectedDocumentUrl, perform: { doc in
            showCustomerUploadScreen = true
        })
        .onChange(of: jobVM.searchTerm){ term in
            print("Searching")
            jobVM.filterWorkOrderList()
        }
    }
    
}

extension JobListView {
    @ViewBuilder
    var list: some View {
        if UIDevice.isIPhone {
            mobileList
        } else {
            legacyList
        }
    }

    private var mobileList: some View {
        VStack(spacing: 0) {
            mobileJobHeader

            if showSearch {
                mobileSearchField
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }

            if displayedJobs.isEmpty {
                ScrollView(showsIndicators: false) {
                    mobileEmptyState
                        .padding(.horizontal, 14)
                        .padding(.top, 14)

                    Color.clear.frame(height: 120)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(displayedJobs) { job in
                            NavigationLink(value: Route.job(job: job, dataService: dataService)) {
                                JobCardView(job: job)
                            }
                            .buttonStyle(.plain)
                        }

                        Color.clear.frame(height: 120)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                }
            }
        }
    }

    private var legacyList: some View {
        VStack{
            if jobVM.workOrders.count == 0 {
                if let role = masterDataManager.role {
                    if role.canCreateAnyJob {
                        Button(action: {
                            showCreateJobOptions = true
                        }, label: {
                            Text("Add First Job")
                                .modifier(AddButtonModifier())
                            
                        })
                        .sheet(isPresented: $showCreateJobOptions) {
                            createJobOptionsSheet
                                .presentationDetents([.medium])
                        }
                        .sheet(isPresented: $showCreateBlankJob,onDismiss: {
                            Task{
                                if let company = masterDataManager.currentCompany {
                                    
                                    do {
                                        techIds = []
                                        
                                        try await companyUserVM.getAllCompanyUsersByStatus(companyId: company.id, status: "Active")
                                        for companyUser in companyUserVM.companyUsers {
                                            techIds.append(companyUser.userId)
                                        }
                                        
                                        startDate = Calendar.current.date(byAdding: .day, value: -300, to: Date())!
                                        jobVM.addListenerForAllJobsOperations(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                                        
                                    } catch {
                                        print("Error Getting Users By status")
                                    }
                                    
                                }
                            }
                        }) {
                            AddNewJobView(
                                dataService: dataService,
                                customerId: nil,
                                canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true
                            )
                        }
                        .sheet(isPresented: $showCreateFromTemplate, onDismiss: {
                            reloadJobs()
                        }) {
                            if let company = masterDataManager.currentCompany {
                                JobTemplatePickerCreateJobSheet(
                                    companyId: company.id,
                                    dataService: dataService,
                                    canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true
                                )
                                .presentationDetents([.large])
                            } else {
                                Text("Missing company.")
                                    .presentationDetents([.medium])
                            }
                        }
                    }}
            } else {
                ScrollView{
                    if jobVM.searchTerm == "" {
                        ForEach(jobVM.workOrders){ job in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.job(job: job,dataService:dataService), label: {
                                    JobCardView(job: job)
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedJob = job
                                }, label: {
                                    JobCardView(job: job)
                                })
                            }
                        }
                    } else {
                        ForEach(jobVM.filteredWorkOrders){ job in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.job(job: job,dataService:dataService), label: {
                                    JobCardView(job: job)
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedJob = job
                                }, label: {
                                    JobCardView(job: job)
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    private var displayedJobs: [Job] {
        let jobs = jobVM.searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? jobVM.workOrders
            : jobVM.filteredWorkOrders

        guard UIDevice.isIPhone else { return jobs }

        return jobs.filter { $0.billingStatus != .expired }
    }

    private var mobileJobHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "briefcase.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 48, height: 48)
                    .background(Color.poolBlue.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Jobs")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(jobListSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                jobSummaryMetric(
                    title: "Showing",
                    value: "\(displayedJobs.count)",
                    tint: .poolBlue
                )

                jobSummaryMetric(
                    title: "Open",
                    value: "\(displayedJobs.filter { $0.operationStatus != .finished }.count)",
                    tint: .orange
                )

                jobSummaryMetric(
                    title: "Statuses",
                    value: "\(selectedStatus.count)",
                    tint: .poolGreen
                )
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var mobileSearchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Search jobs", text: $jobVM.searchTerm)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !jobVM.searchTerm.isEmpty {
                Button {
                    jobVM.searchTerm = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var mobileEmptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: "briefcase.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(jobVM.searchTerm.isEmpty ? "No jobs found." : "No matches found.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(jobVM.searchTerm.isEmpty ? "Create a job to start building this list." : "Try another job ID, customer, status, or description.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if jobVM.searchTerm.isEmpty, masterDataManager.role?.canCreateAnyJob == true {
                Button {
                    showCreateJobOptions = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create Job")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.poolGreen, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showCreateJobOptions) {
                    createJobOptionsSheet
                        .presentationDetents([.medium])
                }
                .sheet(isPresented: $showCreateBlankJob, onDismiss: {
                    reloadJobs()
                }) {
                    AddNewJobView(
                        dataService: dataService,
                        customerId: nil,
                        canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true
                    )
                }
                .sheet(isPresented: $showCreateFromTemplate, onDismiss: {
                    reloadJobs()
                }) {
                    if let company = masterDataManager.currentCompany {
                        JobTemplatePickerCreateJobSheet(
                            companyId: company.id,
                            dataService: dataService,
                            canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true
                        )
                        .presentationDetents([.large])
                    } else {
                        Text("Missing company.")
                            .presentationDetents([.medium])
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func jobSummaryMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var jobListSubtitle: String {
        if jobVM.searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Work orders filtered by \(selectedStatus.count) status\(selectedStatus.count == 1 ? "" : "es")."
        }

        return "Search results for \"\(jobVM.searchTerm)\"."
    }
    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {			
                        showFilters.toggle()
                    }, label: {
                        if UIDevice.isIPhone {
                            mobileDockIcon(systemName: "slider.horizontal.3", tint: .poolBlue)
                        } else {
                            Image(systemName: "slider.horizontal.3")
                                .modifier(FilterIconModifer())
                        }
                    })
                    .padding(UIDevice.isIPhone ? 0 : 10)
                    .sheet(isPresented: $showFilters,onDismiss: {
                        Task{
                            if let company = masterDataManager.currentCompany {
                                do {
                                    jobVM.removeListenerForJob()
                                    jobVM.addListenerForAllJobsOperations(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                                    
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }, content: {
                        jobFilterSheet
                    })
                    if let role = masterDataManager.role {
                        if role.canCreateAnyJob {
                            Button(action: {
                                showCreateJobOptions = true
                            }, label: {
                                if UIDevice.isIPhone {
                                    mobileDockIcon(systemName: "plus", tint: .poolGreen)
                                } else {
                                    Image(systemName: "plus")
                                        .modifier(PlusIconModifer())
                                }
                            })
                            .padding(UIDevice.isIPhone ? 0 : 10)
                            .sheet(isPresented: $showCreateJobOptions) {
                                createJobOptionsSheet
                                    .presentationDetents([.medium])
                            }
                            .sheet(isPresented: $showCreateBlankJob, onDismiss: {
                                reloadJobs()
                            }) {
                                AddNewJobView(
                                    dataService: dataService,
                                    customerId: nil,
                                    canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true
                                )
                            }
                            .sheet(isPresented: $showCreateFromTemplate, onDismiss: {
                                reloadJobs()
                            }) {
                                if let company = masterDataManager.currentCompany {
                                    JobTemplatePickerCreateJobSheet(
                                        companyId: company.id,
                                        dataService: dataService,
                                        canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true
                                    )
                                    .presentationDetents([.large])
                                } else {
                                    Text("Missing company.")
                                        .presentationDetents([.medium])
                                }
                            }
                        }
                    }
                    Button(action: {
                        showSearch.toggle()
                    }, label: {
                        if UIDevice.isIPhone {
                            mobileDockIcon(systemName: "magnifyingglass", tint: .orange)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .modifier(SearchIconModifer())
                        }
                    })
                    .padding(UIDevice.isIPhone ? 0 : 10)
                }
                .padding(UIDevice.isIPhone ? 7 : 0)
                .background(
                    UIDevice.isIPhone
                    ? AnyShapeStyle(.regularMaterial)
                    : AnyShapeStyle(Color.clear),
                    in: RoundedRectangle(cornerRadius: UIDevice.isIPhone ? 8 : 0, style: .continuous)
                )
                .padding(.trailing, UIDevice.isIPhone ? 14 : 0)
            }
            if showSearch {
                if !UIDevice.isIPhone {
                    HStack{
                        TextField(
                            "Search",
                            text: $jobVM.searchTerm
                        )
                        Button(action: {
                            jobVM.searchTerm = ""
                        }, label: {
                            Image(systemName: "xmark")
                        })
                    }
                    .modifier(SearchTextFieldModifier())
                    .padding(8)
                }
            }
            
        }
    }

    private func mobileDockIcon(systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 40, height: 40)
            .background(tint.opacity(0.13), in: Circle())
    }

    private var jobFilterSheet: some View {
        DripDropFilterSheet(
            title: "Job Filters",
            isPresented: $showFilters,
            isResetDisabled: jobActiveFilterCount == 0,
            onReset: resetJobFilters
        ) {
            DripDropFilterSummaryCard(
                title: "\(displayedJobs.count) jobs showing",
                subtitle: "\(selectedStatus.count) status\(selectedStatus.count == 1 ? "" : "es") and \(techIds.count) tech\(techIds.count == 1 ? "" : "s") selected.",
                systemImage: "briefcase.fill",
                tint: .poolBlue
            )

            DripDropFilterSection(
                title: "Date Range",
                systemImage: "calendar",
                tint: .poolBlue
            ) {
                DripDropFilterRow(
                    title: "Start",
                    subtitle: shortDate(date: startDate),
                    systemImage: "calendar.badge.minus",
                    tint: .poolBlue
                ) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                }

                DripDropFilterRow(
                    title: "End",
                    subtitle: shortDate(date: endDate),
                    systemImage: "calendar.badge.plus",
                    tint: .poolBlue
                ) {
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }

            DripDropFilterSection(
                title: "Work",
                systemImage: "line.3.horizontal.decrease.circle",
                tint: .orange
            ) {
                DripDropFilterRow(
                    title: "Status",
                    subtitle: jobStatusMenuTitle,
                    systemImage: "checklist",
                    tint: .orange
                ) {
                    Menu {
                        Button {
                            selectedStatus = JobOperationStatus.allCases
                        } label: {
                            Label("All statuses", systemImage: allJobStatusesSelected ? "checkmark" : "circle")
                        }

                        ForEach(JobOperationStatus.allCases, id: \.self) { status in
                            Button {
                                toggleJobStatus(status)
                            } label: {
                                Label(status.rawValue, systemImage: selectedStatus.contains(status) ? "checkmark" : "circle")
                            }
                        }

                        Button(role: .destructive) {
                            selectedStatus = []
                        } label: {
                            Label("Clear statuses", systemImage: selectedStatus.isEmpty ? "checkmark" : "xmark")
                        }
                    } label: {
                        DripDropFilterMenuLabel(title: jobStatusMenuTitle, tint: .orange)
                    }
                }

                DripDropFilterRow(
                    title: "Techs",
                    subtitle: techMenuTitle,
                    systemImage: "person.2",
                    tint: .poolGreen
                ) {
                    Menu {
                        Button {
                            techIds = companyUserVM.companyUsers.map(\.userId)
                        } label: {
                            Label("All techs", systemImage: allJobTechsSelected ? "checkmark" : "circle")
                        }

                        ForEach(companyUserVM.companyUsers) { tech in
                            Button {
                                toggleTech(tech.userId)
                            } label: {
                                Label(tech.userName, systemImage: techIds.contains(tech.userId) ? "checkmark" : "circle")
                            }
                        }

                        Button(role: .destructive) {
                            techIds = []
                        } label: {
                            Label("Clear techs", systemImage: techIds.isEmpty ? "checkmark" : "xmark")
                        }
                    } label: {
                        DripDropFilterMenuLabel(title: techMenuTitle, tint: .poolGreen)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var defaultJobStatuses: [JobOperationStatus] {
        [.scheduled, .unscheduled, .estimatePending, .inProgress]
    }

    private var defaultJobStartDate: Date {
        Calendar.current.date(byAdding: .day, value: -300, to: Date()) ?? Date()
    }

    private var jobActiveFilterCount: Int {
        var count = 0

        if !Calendar.current.isDate(startDate, inSameDayAs: defaultJobStartDate) { count += 1 }
        if !Calendar.current.isDate(endDate, inSameDayAs: Date()) { count += 1 }
        if !usesDefaultJobStatuses { count += 1 }
        if !allJobTechsSelected { count += 1 }

        return count
    }

    private var usesDefaultJobStatuses: Bool {
        selectedStatus.count == defaultJobStatuses.count &&
        defaultJobStatuses.allSatisfy { selectedStatus.contains($0) }
    }

    private var allJobStatusesSelected: Bool {
        selectedStatus.count == JobOperationStatus.allCases.count &&
        JobOperationStatus.allCases.allSatisfy { selectedStatus.contains($0) }
    }

    private var allJobTechsSelected: Bool {
        let allTechIds = companyUserVM.companyUsers.map(\.userId)

        guard !allTechIds.isEmpty else {
            return techIds.isEmpty
        }

        return techIds.count == allTechIds.count && allTechIds.allSatisfy { techIds.contains($0) }
    }

    private var jobStatusMenuTitle: String {
        if selectedStatus.isEmpty { return "None selected" }
        if allJobStatusesSelected { return "All statuses" }
        if selectedStatus.count == 1 { return selectedStatus.first?.rawValue ?? "1 status" }
        return "\(selectedStatus.count) selected"
    }

    private var techMenuTitle: String {
        if techIds.isEmpty { return "None selected" }
        if allJobTechsSelected { return "All techs" }
        if techIds.count == 1 {
            guard let firstTechId = techIds.first else { return "1 tech" }

            let techName = companyUserVM.companyUsers.first(where: { $0.userId == firstTechId })?.userName
            return techName ?? "1 tech"
        }
        return "\(techIds.count) selected"
    }

    private func toggleJobStatus(_ status: JobOperationStatus) {
        if selectedStatus.contains(status) {
            selectedStatus.removeAll(where: { $0 == status })
        } else {
            selectedStatus.append(status)
        }
    }

    private func toggleTech(_ userId: String) {
        if techIds.contains(userId) {
            techIds.removeAll(where: { $0 == userId })
        } else {
            techIds.append(userId)
        }
    }

    private func resetJobFilters() {
        startDate = defaultJobStartDate
        endDate = Date()
        selectedStatus = defaultJobStatuses
        techIds = companyUserVM.companyUsers.map(\.userId)
    }
    // MARK: createJobOptionsSheet
    var createJobOptionsSheet: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Create Job")
                                    .font(.title3.weight(.semibold))

                                Text(masterDataManager.role?.canCreateBlankJob == true ? "Start blank or use a reusable template." : "Use a reusable job template.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "plus.circle")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(.thinMaterial, in: Circle())
                        }
                    }
                    .jobCreateOptionCard()

                    if masterDataManager.role?.canCreateBlankJob == true {
                        Button {
                            showCreateJobOptions = false

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showCreateBlankJob = true
                            }
                        } label: {
                            jobCreateOptionRow(
                                title: "Blank Job",
                                subtitle: "Build a job manually from scratch.",
                                systemImage: "doc.badge.plus"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if masterDataManager.role?.canCreateJobFromTemplate == true {
                        Button {
                            showCreateJobOptions = false

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showCreateFromTemplate = true
                            }
                        } label: {
                            jobCreateOptionRow(
                                title: "From Template",
                                subtitle: "Create a job using planned stops, tasks, materials, and pricing.",
                                systemImage: "square.stack.3d.up"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(14)
            }
            .navigationTitle("New Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCreateJobOptions = false
                    }
                }
            }
        }
    }
        // MARK: jobCreateOptionRow

    func jobCreateOptionRow(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
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
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    private func reloadJobs() {
        Task {
            guard let company = masterDataManager.currentCompany else { return }

            do {
                techIds = []

                try await companyUserVM.getAllCompanyUsersByStatus(
                    companyId: company.id,
                    status: "Active"
                )

                for companyUser in companyUserVM.companyUsers {
                    techIds.append(companyUser.userId)
                }

                startDate = Calendar.current.date(byAdding: .day, value: -300, to: Date()) ?? Date()

                jobVM.removeListenerForJob()
                jobVM.addListenerForAllJobsOperations(
                    companyId: company.id,
                    status: selectedStatus,
                    requesterIds: techIds,
                    startDate: startDate,
                    endDate: endDate
                )
            } catch {
                print("[][JobListView reloadJobs] Error \(error)")
            }
        }
    }
}

//MARK: Extension View
private extension View {
    func jobCreateOptionCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
    }
}
