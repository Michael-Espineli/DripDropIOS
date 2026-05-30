//
//  CompanyPaySettingsView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/26.
//

import Foundation
import SwiftUI

// MARK: - Repository

protocol CompanyPaySettingsRepository {
    func fetchSettings(companyId: String) async throws -> CompanyPaySettings?
    func saveSettings(_ settings: CompanyPaySettings) async throws
}

// Temporary repository for previews / local testing.
// Replace this with your Firebase / API implementation.
actor InMemoryCompanyPaySettingsRepository: CompanyPaySettingsRepository {
    private var storage: [String: CompanyPaySettings] = [:]

    func fetchSettings(companyId: String) async throws -> CompanyPaySettings? {
        storage[companyId]
    }

    func saveSettings(_ settings: CompanyPaySettings) async throws {
        storage[settings.companyId] = settings
    }
}

// MARK: - Defaults

extension CompanyPaySettings {
    static func defaultSettings(companyId: String) -> CompanyPaySettings {
        CompanyPaySettings(
            companyId: companyId,
            payMode: .productionOnly,
            routePaySource: .serviceStopAndCompletedTasks,
            taskPaySource: .technicianRateThenTaskContractedRate,
            allowMultipleWorkTypesPerStop: true,
            defaultStackBehavior: .stackable,
            allowTechnicianRateOverrides: true,
            allowManualPayAdjustments: true,
            payCommercialAsSeparateWorkType: true,
            paySpaAsSeparateWorkType: true,
            payPerBodyOfWater: true,
            lockPayAfterApproval: true,
            recalculateUnapprovedPayWhenRatesChange: false
        )
    }
}

// MARK: - Display Helpers

extension CompanyPayMode {
    var title: String {
        switch self {
        case .productionOnly: return "Production Pay"
        case .hourlyOnly: return "Hourly Pay"
        case .hybrid: return "Hybrid Pay"
        }
    }

    var helpText: String {
        switch self {
        case .productionOnly:
            return "Technicians are paid based on completed stops, tasks, and work types."
        case .hourlyOnly:
            return "Technicians are paid based on time worked."
        case .hybrid:
            return "Some work is paid by production rate, and some work is paid hourly."
        }
    }
}

extension RoutePaySource {
    var title: String {
        switch self {
        case .serviceStop:
            return "Completed stop only"
        case .completedTasks:
            return "Completed tasks only"
        case .serviceStopAndCompletedTasks:
            return "Stop plus completed tasks"
        case .hourlyServiceStopDuration:
            return "Hourly from stop duration"
        case .hourlyTaskActualTime:
            return "Hourly from task time"
        case .none:
            return "No automatic route pay"
        }
    }

    var helpText: String {
        switch self {
        case .serviceStop:
            return "A completed route stop creates one pay item."
        case .completedTasks:
            return "The stop itself does not create pay. Only completed tasks do."
        case .serviceStopAndCompletedTasks:
            return "The completed stop creates pay, and completed payable tasks can add more pay."
        case .hourlyServiceStopDuration:
            return "Pay is based on the service stop duration."
        case .hourlyTaskActualTime:
            return "Pay is based on the actual time entered on completed tasks."
        case .none:
            return "No automatic route pay will be generated."
        }
    }
}

extension TaskPaySource {
    var title: String {
        switch self {
        case .technicianRate:
            return "Technician rate"
        case .taskContractedRate:
            return "Task contracted rate"
        case .technicianRateThenTaskContractedRate:
            return "Technician rate, then task fallback"
        case .taskContractedRateThenTechnicianRate:
            return "Task rate, then technician fallback"
        case .hourlyActualTime:
            return "Hourly actual time"
        case .hourlyEstimatedTime:
            return "Hourly estimated time"
        case .none:
            return "No automatic task pay"
        }
    }

    var helpText: String {
        switch self {
        case .technicianRate:
            return "Use the technician's active rate for the task's mapped work type."
        case .taskContractedRate:
            return "Use the task's contractedRate field."
        case .technicianRateThenTaskContractedRate:
            return "Prefer the technician's rate. If missing, use the task contracted rate."
        case .taskContractedRateThenTechnicianRate:
            return "Prefer the task contracted rate. If missing, use the technician's rate."
        case .hourlyActualTime:
            return "Use the task's actualTime and the technician's hourly rate."
        case .hourlyEstimatedTime:
            return "Use the task's estimatedTime and the technician's hourly rate."
        case .none:
            return "Completed tasks will not automatically create pay."
        }
    }
}

extension RateStackBehavior {
    static var selectableCases: [RateStackBehavior] {
        [.stackable, .exclusive, .replacesBase, .modifier]
    }

    var title: String {
        switch self {
        case .stackable:
            return "Stackable"
        case .exclusive:
            return "Exclusive"
        case .replacesBase:
            return "Replaces base"
        case .modifier:
            return "Modifier"
        }
    }

    var helpText: String {
        switch self {
        case .stackable:
            return "Multiple matching work types can all pay on the same stop."
        case .exclusive:
            return "Only one matching rate should win."
        case .replacesBase:
            return "This work type replaces the normal base route pay."
        case .modifier:
            return "This work type modifies another rate."
        }
    }
}

// MARK: - ViewModel

@MainActor
final class CompanyPaySettingsViewModel: ObservableObject {
    @Published var settings: CompanyPaySettings
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    private let companyId: String
    private let repository: CompanyPaySettingsRepository
    private var hasLoaded = false

    init(
        companyId: String,
        repository: CompanyPaySettingsRepository
    ) {
        self.companyId = companyId
        self.repository = repository
        self.settings = .defaultSettings(companyId: companyId)
    }

    func load() async {
        guard !hasLoaded else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            if let existingSettings = try await repository.fetchSettings(companyId: companyId) {
                settings = existingSettings
            } else {
                settings = .defaultSettings(companyId: companyId)
            }
        } catch {
            alertMessage = "Could not load pay settings. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func save() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await repository.saveSettings(settings)
            alertMessage = "Pay settings saved."
            showAlert = true
        } catch {
            alertMessage = "Could not save pay settings. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func applyProductionDefaults() {
        settings.payMode = .productionOnly
        settings.routePaySource = .serviceStopAndCompletedTasks
        settings.taskPaySource = .technicianRateThenTaskContractedRate
        settings.allowMultipleWorkTypesPerStop = true
        settings.defaultStackBehavior = .stackable
        settings.allowTechnicianRateOverrides = true
        settings.allowManualPayAdjustments = true
        settings.payCommercialAsSeparateWorkType = true
        settings.paySpaAsSeparateWorkType = true
        settings.payPerBodyOfWater = true
        settings.lockPayAfterApproval = true
        settings.recalculateUnapprovedPayWhenRatesChange = false
    }

    func applyHourlyDefaults() {
        settings.payMode = .hourlyOnly
        settings.routePaySource = .hourlyServiceStopDuration
        settings.taskPaySource = .hourlyActualTime
        settings.allowMultipleWorkTypesPerStop = false
        settings.defaultStackBehavior = .stackable
        settings.allowTechnicianRateOverrides = true
        settings.allowManualPayAdjustments = true
        settings.payCommercialAsSeparateWorkType = false
        settings.paySpaAsSeparateWorkType = false
        settings.payPerBodyOfWater = false
        settings.lockPayAfterApproval = true
        settings.recalculateUnapprovedPayWhenRatesChange = false
    }

    func applyHybridDefaults() {
        settings.payMode = .hybrid
        settings.routePaySource = .serviceStopAndCompletedTasks
        settings.taskPaySource = .hourlyActualTime
        settings.allowMultipleWorkTypesPerStop = true
        settings.defaultStackBehavior = .stackable
        settings.allowTechnicianRateOverrides = true
        settings.allowManualPayAdjustments = true
        settings.payCommercialAsSeparateWorkType = true
        settings.paySpaAsSeparateWorkType = true
        settings.payPerBodyOfWater = true
        settings.lockPayAfterApproval = true
        settings.recalculateUnapprovedPayWhenRatesChange = false
    }
}

// MARK: - View

struct CompanyPaySettingsView: View {
    @StateObject private var viewModel: CompanyPaySettingsViewModel

    init(
        companyId: String,
        repository: CompanyPaySettingsRepository
    ) {
        _viewModel = StateObject(
            wrappedValue: CompanyPaySettingsViewModel(
                companyId: companyId,
                repository: repository
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                presetSection
                payModeSection
                routePaySection
                taskPaySection
                industryRulesSection
                controlSection
            }
            .navigationTitle("Pay Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.isSaving ? "Saving..." : "Save") {
                        Task {
                            await viewModel.save()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .task {
                await viewModel.load()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading settings...")
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Pay Settings", isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }

    private var presetSection: some View {
        Section {
            Button("Use Production Pay Defaults") {
                viewModel.applyProductionDefaults()
            }

            Button("Use Hourly Pay Defaults") {
                viewModel.applyHourlyDefaults()
            }

            Button("Use Hybrid Pay Defaults") {
                viewModel.applyHybridDefaults()
            }
        } header: {
            Text("Quick Setup")
        } footer: {
            Text("These presets update the rules below. You can still customize every setting.")
        }
    }

    private var payModeSection: some View {
        Section {
            Picker("Pay Mode", selection: $viewModel.settings.payMode) {
                ForEach(CompanyPayMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }

            Text(viewModel.settings.payMode.helpText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Company Pay Mode")
        }
    }

    private var routePaySection: some View {
        Section {
            Picker("Route / Stop Pay", selection: $viewModel.settings.routePaySource) {
                ForEach(RoutePaySource.allCases, id: \.self) { source in
                    Text(source.title).tag(source)
                }
            }

            Text(viewModel.settings.routePaySource.helpText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Toggle(
                "Allow multiple work types on one stop",
                isOn: $viewModel.settings.allowMultipleWorkTypesPerStop
            )

            Picker("Default stacking", selection: $viewModel.settings.defaultStackBehavior) {
                ForEach(RateStackBehavior.selectableCases, id: \.self) { behavior in
                    Text(behavior.title).tag(behavior)
                }
            }

            Text(viewModel.settings.defaultStackBehavior.helpText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Service Stop Pay")
        } footer: {
            Text("This controls pay created from the completed service stop itself, such as a weekly route stop, service call, startup visit, or commercial visit.")
        }
    }

    private var taskPaySection: some View {
        Section {
            Picker("Task Pay", selection: $viewModel.settings.taskPaySource) {
                ForEach(TaskPaySource.allCases, id: \.self) { source in
                    Text(source.title).tag(source)
                }
            }

            Text(viewModel.settings.taskPaySource.helpText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Completed Task Pay")
        } footer: {
            Text("This controls pay created from completed ServiceStopTask records, such as filter cleanings, salt cell cleanings, repairs, installations, or extras.")
        }
    }

    private var industryRulesSection: some View {
        Section {
            Toggle(
                "Pay commercial as separate work",
                isOn: $viewModel.settings.payCommercialAsSeparateWorkType
            )

            Toggle(
                "Pay spa as separate work",
                isOn: $viewModel.settings.paySpaAsSeparateWorkType
            )

            Toggle(
                "Support per-body-of-water pay",
                isOn: $viewModel.settings.payPerBodyOfWater
            )
        } header: {
            Text("Pool Industry Rules")
        } footer: {
            Text("These make the pay engine flexible for pool companies that handle pool/spa combos, commercial routes, and multiple bodies of water.")
        }
    }

    private var controlSection: some View {
        Section {
            Toggle(
                "Allow technician-specific rate overrides",
                isOn: $viewModel.settings.allowTechnicianRateOverrides
            )

            Toggle(
                "Allow manual pay adjustments",
                isOn: $viewModel.settings.allowManualPayAdjustments
            )

            Toggle(
                "Lock pay after approval",
                isOn: $viewModel.settings.lockPayAfterApproval
            )

            Toggle(
                "Recalculate unapproved pay when rates change",
                isOn: $viewModel.settings.recalculateUnapprovedPayWhenRatesChange
            )
        } header: {
            Text("Payroll Controls")
        } footer: {
            Text("I recommend locking approved pay. Rate changes should affect future work, not old approved payroll.")
        }
    }
}

// MARK: - Preview

#Preview {
    CompanyPaySettingsView(
        companyId: "demo_company",
        repository: InMemoryCompanyPaySettingsRepository()
    )
}
