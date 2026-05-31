//
//  AddNewScheduleServiceStopToNewJobView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/31/25.
//

import MapKit
import SwiftUI

struct AddNewScheduleServiceStopToNewJobView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: ScheduleServiceStopViewModel

    @State var jobId: String
    @State var customerId: String
    @State var customerName: String

    @State var serviceLocationId: String
    @State var description: String
    @State var jobTaskList: [JobTask]

    @Binding var serviceStops: [ServiceStop]
    @Binding var serviceStopTasks: [ServiceStop: [ServiceStopTask]]

    @State private var showTechnicianSelector: Bool = false

    init(
        dataService: any ProductionDataServiceProtocol,
        jobId: String,
        customerId: String,
        customerName: String,
        serviceLocationId: String,
        description: String,
        jobTaskList: [JobTask],
        serviceStops: Binding<[ServiceStop]>,
        serviceStopTasks: Binding<[ServiceStop: [ServiceStopTask]]>
    ) {
        _VM = StateObject(wrappedValue: ScheduleServiceStopViewModel(dataService: dataService))
        _jobId = State(wrappedValue: jobId)
        _customerId = State(wrappedValue: customerId)
        _customerName = State(wrappedValue: customerName)
        _serviceLocationId = State(wrappedValue: serviceLocationId)
        _description = State(wrappedValue: description)
        _jobTaskList = State(wrappedValue: jobTaskList)
        self._serviceStops = serviceStops
        self._serviceStopTasks = serviceStopTasks
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    scheduleDetailsCard
                    routeSnapshotCard
                    taskSelectionCard
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
            .scrollDismissesKeyboard(.interactively)

            if VM.isLoading {
                loadingOverlay
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .sheet(isPresented: $showTechnicianSelector) {
            CompanyUserPicker(
                dataService: dataService,
                companyUser: $VM.selectedUser
            )
        }
        .sheet(isPresented: $VM.showRouteSnapShot) {
            routeSnapshotSheet
                .presentationDetents([.fraction(0.4), .medium])
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    VM.description = description

                    try await VM.onLoad(
                        companyId: currentCompany.id,
                        serviceLocationId: serviceLocationId,
                        description: description,
                        jobTaskList: jobTaskList
                    )
                } catch {
                    print(error)
                }
            }
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: VM.serviceDate) { _ in
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.onChangeOfDayOrTech(companyId: currentCompany.id)
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .onChange(of: VM.selectedUser) { _ in
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.onChangeOfDayOrTech(companyId: currentCompany.id)
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .onChange(of: VM.selectedJobTaskList) { tasks in
            VM.estimateTime(tasks: tasks)
        }
    }
}

// MARK: - Main UI

extension AddNewScheduleServiceStopToNewJobView {

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Schedule Service Stop")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Choose a technician, service date, and the tasks to schedule.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Label(customerName.isEmpty ? "Customer" : customerName, systemImage: "person.crop.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Label("\(VM.selectedJobTaskList.count) Selected", systemImage: "checklist")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var scheduleDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Details", systemImage: "calendar.badge.plus")

            pickerButtonRow(
                title: "Technician",
                value: VM.selectedUser.id == "" ? "Select Technician" : "\(VM.selectedUser.userName) \(VM.selectedUser.roleName)",
                systemImage: "person.crop.circle",
                isSelected: VM.selectedUser.id != ""
            ) {
                showTechnicianSelector.toggle()
            }

            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                DatePicker(
                    "Service Date",
                    selection: $VM.serviceDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .font(.subheadline.weight(.semibold))
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            descriptionInputCard

            detailDisplayRow(
                title: "Estimated Time",
                value: displayMinAsMinAndHour(min: VM.estimatedTime),
                systemImage: "timer"
            )
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var routeSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Route Snapshot", systemImage: "map")

                Spacer()

                Button {
                    VM.showRouteSnapShot.toggle()
                } label: {
                    Label("View", systemImage: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                routeMetricRow(
                    title: "Stops",
                    value: "\(String(VM.finishedStops))/\(String(VM.totalStops))",
                    systemImage: "checklist"
                )

                routeMetricRow(
                    title: "Status",
                    value: "\(VM.routeStatus)",
                    systemImage: "circle.dashed"
                )

                routeMetricRow(
                    title: "Estimated Time",
                    value: "\(displayMinAsMinAndHour(min: VM.estimatedTimeMin)) hrs",
                    systemImage: "clock"
                )

                routeMetricRow(
                    title: "Estimated Mileage",
                    value: "\(String(VM.estimatedTimeMiles)) mi",
                    systemImage: "car"
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var taskSelectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Select Tasks", systemImage: "checklist")

                Spacer()

                Text("\(VM.selectedJobTaskList.count)/\(VM.jobTaskList.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if VM.jobTaskList.isEmpty {
                emptyState(
                    title: "No tasks available.",
                    message: "There are no unscheduled tasks to add to this service stop.",
                    systemImage: "checklist.unchecked"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.jobTaskList) { task in
                        taskSelectionRow(task)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Bottom Bar

extension AddNewScheduleServiceStopToNewJobView {

    var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.35)

            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    scheduleServiceStop()
                } label: {
                    Label("Schedule", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(VM.isLoading)
                .opacity(VM.isLoading ? 0.55 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }

    func scheduleServiceStop() {
        Task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    let values = try await VM.scheduleNewServiceStopNewJob(
                        companyId: currentCompany.id,
                        jobId: jobId,
                        customerId: customerId,
                        customerName: customerName,
                        serviceLocationId: serviceLocationId
                    )

                    serviceStops.append(values.0)
                    serviceStopTasks[values.0] = values.1

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif

                    dismiss()
                } catch {
                    print(error)

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    #endif
                }
            }
        }
    }
}

// MARK: - Rows

extension AddNewScheduleServiceStopToNewJobView {

    func taskSelectionRow(_ task: JobTask) -> some View {
        switch task.status {
        case .accepted, .offered, .scheduled, .finished, .inProgress:
            return AnyView(
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text("\(task.type) • \(task.status.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .opacity(0.55)
            )

        case .unassigned, .rejected, .draft:
            let isSelected = VM.selectedJobTaskList.contains(where: { $0.id == task.id })

            return AnyView(
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        if isSelected {
                            VM.selectedJobTaskList.removeAll(where: { $0.id == task.id })
                        } else {
                            VM.selectedJobTaskList.append(task)
                        }
                    }

                    #if os(iOS)
                    UISelectionFeedbackGenerator().selectionChanged()
                    #endif
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? Color.poolGreen : .secondary)
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text("\(task.type) • \(task.status.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(
                        isSelected ? Color.poolGreen.opacity(0.12) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            )
        }
    }

    func routeMetricRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func detailDisplayRow(title: String, value: String, systemImage: String) -> some View {
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

                Text(value.isEmpty ? "-" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
}

// MARK: - Helpers

extension AddNewScheduleServiceStopToNewJobView {

    var descriptionInputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Description", systemImage: "text.alignleft")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    VM.description = ""
                } label: {
                    Text("Clear")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            TextField("Description", text: $VM.description, axis: .vertical)
                .font(.subheadline)
                .lineLimit(4, reservesSpace: true)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    var routeSnapshotSheet: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Route Snapshot")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("For selected technician and service date.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        VM.showRouteSnapShot = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 34, height: 34)
                            .background(.thinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(spacing: 8) {
                    routeMetricRow(
                        title: "Stops",
                        value: "\(String(VM.finishedStops))/\(String(VM.totalStops))",
                        systemImage: "checklist"
                    )

                    routeMetricRow(
                        title: "If Clocked In",
                        value: "5 Hours",
                        systemImage: "clock.badge.checkmark"
                    )

                    routeMetricRow(
                        title: "Status",
                        value: "\(VM.routeStatus)",
                        systemImage: "circle.dashed"
                    )

                    routeMetricRow(
                        title: "Estimated Time",
                        value: "\(displayMinAsMinAndHour(min: VM.estimatedTimeMin)) hrs",
                        systemImage: "clock"
                    )

                    routeMetricRow(
                        title: "Estimated Mileage",
                        value: "\(String(VM.estimatedTimeMiles)) mi",
                        systemImage: "car"
                    )
                }
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                Spacer()
            }
            .padding(14)
        }
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.12)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()

                Text("Loading...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    func emptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
