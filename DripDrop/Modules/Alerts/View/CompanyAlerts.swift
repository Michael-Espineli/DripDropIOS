//
//  CompanyAlerts.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/8/24.
//

import SwiftUI

private enum CompanyAlertFilter:String, CaseIterable, Identifiable {
    case active
    case unread
    case scheduled
    case all

    var id:String { rawValue }

    var title:String {
        switch self {
        case .active:
            return "Active"
        case .unread:
            return "Unread"
        case .scheduled:
            return "Scheduled"
        case .all:
            return "All"
        }
    }
}

struct CompanyAlerts: View {
    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: CompanyAlertViewModel(dataService: dataService))
    }
    
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var VM : CompanyAlertViewModel
    @State private var filter:CompanyAlertFilter = .active
    @State private var updatingAlertIds:Set<String> = []
    @State private var actionMessage:String? = nil


    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                list
            }
            .refreshable {
                await loadAlerts()
            }
            .padding(12)
        }
        .navigationTitle("Notifications (\(unreadCount) unread)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await dismissVisibleAlerts()
                    }
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .disabled(filteredAlerts.isEmpty || !updatingAlertIds.isEmpty)
            }
        }
        .task {
            await loadAlerts()
        }
        .alert("Notification Center", isPresented: Binding(
            get: { actionMessage != nil },
            set: { isPresented in
                if !isPresented {
                    actionMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                actionMessage = nil
            }
        } message: {
            Text(actionMessage ?? "")
        }
    }
}

#Preview {
    CompanyAlerts(dataService: MockDataService())
}
extension CompanyAlerts {
    var list: some View {
        VStack(alignment: .leading, spacing: 14){
            filterPicker
            notifications
        }
    }

    var filterPicker: some View {
        Picker("Notifications", selection: $filter) {
            ForEach(CompanyAlertFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    var notifications: some View {
        LazyVStack(alignment: .leading, spacing: 12){
            if filteredAlerts.isEmpty {
                Text("No notifications")
                    .frame(maxWidth: .infinity)
                    .modifier(DismissButtonModifier())
            } else {
                ForEach(filteredAlerts){ alert in
                    notificationRow(alert)
                }
            }
        }
    }

    var filteredAlerts:[DripDropAlert] {
        VM.alertList
            .filter { alert in
                switch filter {
                case .active:
                    return alert.needsAttention
                case .unread:
                    return alert.isUnread
                case .scheduled:
                    return alert.isScheduled
                case .all:
                    return !alert.isArchived
                }
            }
            .sorted { $0.date > $1.date }
    }

    var unreadCount:Int {
        VM.alertList.filter { $0.isUnread }.count
    }

    func notificationRow(_ alert:DripDropAlert) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            DripDropAlertCardSmall(dataService: dataService, alert: alert, isEmbedded: true)

            Divider()

            HStack(spacing: 8) {
                if alert.isUnread {
                    alertActionButton(title: "Read", systemImage: "checkmark.circle", tint: .poolGreen, alert: alert) {
                        await markAlertAsRead(alert)
                    }
                }

                alertActionButton(title: "Dismiss", systemImage: "xmark.circle", tint: .secondary, alert: alert) {
                    await dismissAlert(alert)
                }
            }
        }
        .modifier(ListButtonModifier())
    }

    func alertActionButton(
        title:String,
        systemImage:String,
        tint:Color,
        alert:DripDropAlert,
        action:@escaping () async -> Void
    ) -> some View {
        Button {
            Task {
                await action()
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.bordered)
        .tint(tint)
        .disabled(updatingAlertIds.contains(alert.mergeKey))
    }

    func loadAlerts() async {
        guard let selectedCompany = masterDataManager.currentCompany else {
            return
        }

        do {
            try await VM.getAlertsByCompany(
                companyId: selectedCompany.id,
                userId: masterDataManager.user?.id
            )
        } catch{
            print("Error")
            print(error)
            actionMessage = "Could not load notifications."
        }
    }

    func markAlertAsRead(_ alert:DripDropAlert) async {
        guard let selectedCompany = masterDataManager.currentCompany else {
            return
        }

        await performAlertAction(alert) {
            try await VM.markAlertAsRead(
                companyId: selectedCompany.id,
                userId: masterDataManager.user?.id,
                alert: alert
            )
        }
    }

    func dismissAlert(_ alert:DripDropAlert) async {
        guard let selectedCompany = masterDataManager.currentCompany else {
            return
        }

        await performAlertAction(alert) {
            try await VM.dismissAlert(
                companyId: selectedCompany.id,
                userId: masterDataManager.user?.id,
                alert: alert
            )
        }
    }

    func dismissVisibleAlerts() async {
        guard let selectedCompany = masterDataManager.currentCompany else {
            return
        }

        let alerts = filteredAlerts
        let keys = Set(alerts.map(\.mergeKey))
        updatingAlertIds.formUnion(keys)

        do {
            try await VM.dismissAlerts(
                companyId: selectedCompany.id,
                userId: masterDataManager.user?.id,
                alerts: alerts
            )
        } catch {
            print(error)
            actionMessage = "Could not clear notifications."
        }

        updatingAlertIds.subtract(keys)
    }

    func performAlertAction(_ alert:DripDropAlert, action:() async throws -> Void) async {
        updatingAlertIds.insert(alert.mergeKey)

        do {
            try await action()
        } catch {
            print(error)
            actionMessage = "Could not update notification."
        }

        updatingAlertIds.remove(alert.mergeKey)
    }
}
