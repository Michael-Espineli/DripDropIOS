//
//  JobTemplatePickerCreateJobSheet.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/24/26.
//



import SwiftUI

struct JobTemplatePickerCreateJobSheet: View {
    @Environment(\.dismiss) private var dismiss

    let companyId: String
    let dataService: any ProductionDataServiceProtocol
    let technicianCanAddOnly: Bool
    let isTechnicianCreateFlow: Bool
    let canScheduleServiceStopsForOthers: Bool

    @State private var templates: [JobTemplate] = []
    @State private var selectedTemplate: JobTemplate?

    @State private var isLoading: Bool = false
    @State private var showCreateJobSheet: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    init(
        companyId: String,
        dataService: any ProductionDataServiceProtocol,
        technicianCanAddOnly: Bool = false,
        isTechnicianCreateFlow: Bool = false,
        canScheduleServiceStopsForOthers: Bool = true
    ) {
        self.companyId = companyId
        self.dataService = dataService
        self.technicianCanAddOnly = technicianCanAddOnly
        self.isTechnicianCreateFlow = isTechnicianCreateFlow
        self.canScheduleServiceStopsForOthers = canScheduleServiceStopsForOthers
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard

                        if isLoading {
                            loadingCard
                        } else if templates.isEmpty {
                            emptyCard
                        } else {
                            templatesCard
                        }

                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await load()
            }
            .alert("Templates", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(item: $selectedTemplate, onDismiss: {
                dismiss()
            }) { template in
                AddNewJobView(
                    dataService: dataService,
                    customerId: nil,
                    startingTemplate: template,
                    isTechnicianCreateFlow: isTechnicianCreateFlow,
                    canScheduleServiceStopsForOthers: canScheduleServiceStopsForOthers
                )
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Create From Template")
                        .font(.title3.weight(.semibold))

                    Text("Pick a reusable job plan to create a new draft job.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "square.stack.3d.up")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial, in: Circle())
            }
        }
        .jobTemplatePickerCard()
    }

    private var loadingCard: some View {
        VStack(spacing: 10) {
            ProgressView()

            Text("Loading templates...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .jobTemplatePickerCard()
    }

    private var emptyCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.badge.plus")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No templates found.")
                .font(.headline.weight(.semibold))

            Text(technicianCanAddOnly ? "No templates are currently enabled for technician job creation." : "Create templates from Job Detail or from Settings > Job Templates.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .jobTemplatePickerCard()
    }

    private var templatesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Templates", systemImage: "doc.text")
                .font(.headline.weight(.semibold))

            VStack(spacing: 8) {
                ForEach(templates) { template in
                    Button {
                        selectedTemplate = template
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: template.jobTypeImage ?? "doc.text")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(.thinMaterial, in: Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                if !template.description.isEmpty {
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }

                                HStack(spacing: 6) {
                                    if !template.jobType.isEmpty {
                                        Text(template.jobType)
                                    }

                                    if template.defaultRateCents > 0 {
                                        Text("•")
                                        Text(JobTemplatePickerMoneyFormatter.money(template.defaultRateCents))
                                    }
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
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
            }
        }
        .jobTemplatePickerCard()
    }

    private func load() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedTemplates = try await dataService.fetchJobTemplates(companyId: companyId)
            if technicianCanAddOnly {
                templates = fetchedTemplates.filter { $0.technicianCanAdd }
            } else {
                templates = fetchedTemplates
            }
        } catch {
            alertMessage = "Could not load job templates. \(error.localizedDescription)"
            showAlert = true
        }
    }
}

private enum JobTemplatePickerMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

private extension View {
    func jobTemplatePickerCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
