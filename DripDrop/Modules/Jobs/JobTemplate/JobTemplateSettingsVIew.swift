//
//  JobTemplateSettingsView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI

struct JobTemplateSettingsView: View {

    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(
            wrappedValue: JobTemplateSettingsViewModel(dataService: dataService)
        )
    }
    @EnvironmentObject var dataService: ProductionDataService

    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject private var VM: JobTemplateSettingsViewModel

    @State private var showCreateNewJobTemplate: Bool = false

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard

                    if VM.isLoading {
                        loadingCard
                    } else if VM.jobTemplates.isEmpty {
                        emptyStateCard
                    } else {
                        templatesListCard
                    }

                    Color.clear.frame(height: 70)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Job Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateNewJobTemplate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await load()
        }
        .refreshable {
            await load()
        }
        .alert("Job Templates", isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(VM.alertMessage)
        }
        .sheet(isPresented: $showCreateNewJobTemplate, onDismiss: {
            Task {
                await load()
            }
        }) {
            if let company = masterDataManager.currentCompany {
                CreateBlankJobTemplateSheet(
                    companyId: company.id,
                    dataService: VM.dataService
                )
                .presentationDetents([.medium, .large])
            } else {
                Text("Missing company.")
                    .presentationDetents([.medium])
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Job Templates")
                        .font(.title3.weight(.semibold))

                    Text("Reusable job plans with planned stops, tasks, materials, pricing, and labor snapshots.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "square.stack.3d.up")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial, in: Circle())
            }

            HStack(spacing: 10) {
                JobTemplateSettingsChip(
                    title: "Active",
                    value: "\(VM.activeTemplateCount)",
                    systemImage: "checkmark.circle"
                )

                JobTemplateSettingsChip(
                    title: "Locked",
                    value: "\(VM.lockedTemplateCount)",
                    systemImage: "lock"
                )

                JobTemplateSettingsChip(
                    title: "Total",
                    value: "\(VM.jobTemplates.count)",
                    systemImage: "doc.text"
                )
            }
        }
        .jobTemplateSettingsCard()
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
        .jobTemplateSettingsCard()
    }

    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No job templates yet.")
                .font(.headline.weight(.semibold))

            Text("Create templates from existing jobs or start a blank reusable job plan here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showCreateNewJobTemplate = true
            } label: {
                Label("Create Template", systemImage: "plus.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(18)
        .jobTemplateSettingsCard()
    }

    private var templatesListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Templates", systemImage: "doc.text")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(VM.jobTemplates.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            VStack(spacing: 10) {
                ForEach(VM.jobTemplates) { template in
                    if UIDevice.isIPhone {
                        NavigationLink(value: Route.jobTemplate(jobTemplate: template, dataService: dataService), label: {
                            JobTemplateSettingsCardView(template: template)

                        })
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            masterDataManager.selectedJobTemplate = template
                        } label: {
                            JobTemplateSettingsCardView(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .jobTemplateSettingsCard()
    }

    private func load() async {
        guard let company = masterDataManager.currentCompany else {
            return
        }

        await VM.load(companyId: company.id)
    }
}
private struct JobTemplateSettingsChip: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
private extension View {
    func jobTemplateSettingsCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
