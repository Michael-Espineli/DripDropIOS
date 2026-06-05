//
//  CompanyPaySettingsView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/26.
//

import SwiftUI

@MainActor
final class CompanyPaySettingsViewModel: ObservableObject {

    @Published var settings: CompanyPaySettings
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    private let dataService: any ProductionDataServiceProtocol
    private var hasLoaded = false

    init(
        dataService: any ProductionDataServiceProtocol
    ) {
        self.dataService = dataService
        self.settings = .defaultSettings()
    }

    func load(companyId:String) async {
        guard !hasLoaded else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            if var existingSettings = try await dataService.fetchCompanyPaySettings(companyId: companyId) {
                if existingSettings.companyId.isBlank {
                    existingSettings.companyId = companyId
                }
                settings = existingSettings
            } else {
                settings = .defaultSettings(companyId: companyId)
            }
        } catch {
            alertMessage = "Could not load pay settings. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func save(companyId:String) async {
        isSaving = true
        defer { isSaving = false }

        do {
            var settingsToSave = settings
            settingsToSave.companyId = companyId
            try await dataService.saveCompanyPaySettings(companyId: companyId, settingsToSave)
            settings = settingsToSave
            alertMessage = "Pay settings saved."
            showAlert = true
        } catch {
            alertMessage = "Could not save pay settings. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func applyProductionDefaults(companyId:String) {
        settings = .dripDropProductionDefault(companyId: companyId)
    }

    func applyHourlyDefaults(companyId:String) {
        settings = .hourlyDefault(companyId: companyId)
    }

    func applyHybridDefaults(companyId:String) {
        settings = .hybridDefault(companyId: companyId)
    }
}

struct CompanyPaySettingsView: View {

    @StateObject private var viewModel: CompanyPaySettingsViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    init(
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: CompanyPaySettingsViewModel(
                dataService: dataService
            )
        )
    }

    var body: some View {
        Form {
            presetSection
            payModeSection
            stopPaySection
            taskPaySection
            hourlyPaySection
            poolIndustrySection
            payrollControlSection
        }
        .navigationTitle("Pay Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(viewModel.isSaving ? "Saving..." : "Save") {
                    Task {
                        if let currentCompany = masterDataManager.currentCompany {
                            
                            await viewModel.save(companyId: currentCompany.id)
                            
                        }
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                await viewModel.load(companyId: currentCompany.id)
            }
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

    private var presetSection: some View {
        Section {
            if let currentCompany = masterDataManager.currentCompany {
                
                Button("Use Production Pay Defaults") {
                    viewModel.applyProductionDefaults(companyId: currentCompany.id)
                }
                
                Button("Use Hourly Pay Defaults") {
                    viewModel.applyHourlyDefaults(companyId: currentCompany.id)
                }
                
                Button("Use Hybrid Pay Defaults") {
                    viewModel.applyHybridDefaults(companyId: currentCompany.id)
                }
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

    private var stopPaySection: some View {
        Section {
            Picker("Stop Pay", selection: $viewModel.settings.routePaySource) {
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
            Text("This controls pay created from completed service stops, such as route stops, job visits, service calls, startups, or commercial visits.")
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
            Text("This controls pay from completed ServiceStopTask records, such as filter cleanings, salt cell cleanings, repairs, installations, and extras.")
        }
    }

    private var hourlyPaySection: some View {
        Section {
            Picker("Hourly Source", selection: $viewModel.settings.hourlyPaySource) {
                ForEach(HourlyPaySource.allCases, id: \.self) { source in
                    Text(source.title).tag(source)
                }
            }

            Text(viewModel.settings.hourlyPaySource.helpText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Hourly Pay")
        } footer: {
            Text("For hourly-only companies, ActiveRoute duration is usually the cleanest source. Service stops should not usually generate separate hourly pay in that mode.")
        }
    }

    private var poolIndustrySection: some View {
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

            Picker("Commercial Multi-BOW Style", selection: $viewModel.settings.commercialMultiBodyPayStyle) {
                ForEach(CommercialMultiBodyPayStyle.allCases, id: \.self) { style in
                    Text(style.title).tag(style)
                }
            }

            Text(viewModel.settings.commercialMultiBodyPayStyle.helpText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Pool Industry Rules")
        } footer: {
            Text("These rules support pool/spa combos, commercial stops, and multiple bodies of water.")
        }
    }

    private var payrollControlSection: some View {
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
            Text("I recommend locking approved pay. Rate changes should affect future work, not already-approved payroll.")
        }
    }
}
