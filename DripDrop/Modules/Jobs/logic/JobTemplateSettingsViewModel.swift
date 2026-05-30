//
//  JobTemplateSettingsViewModel.swift
//  DripDrop
//

import Foundation

@MainActor
final class JobTemplateSettingsViewModel: ObservableObject {

    let dataService: any ProductionDataServiceProtocol

    @Published var jobTemplates: [JobTemplate] = []

    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    var activeTemplateCount: Int {
        jobTemplates.filter { $0.isActive }.count
    }

    var lockedTemplateCount: Int {
        jobTemplates.filter { $0.locked }.count
    }

    func load(companyId: String) async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            jobTemplates = try await dataService.fetchJobTemplates(
                companyId: companyId
            )
        } catch {
            alertMessage = "Could not load job templates. \(error.localizedDescription)"
            showAlert = true
        }
    }
}