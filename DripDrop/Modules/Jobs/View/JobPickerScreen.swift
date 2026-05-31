//
//  JobPickerScreen.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/28/24.
////
//  JobPickerScreen.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/28/24.
//

import SwiftUI

struct JobPickerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject var jobVM: JobViewModel
    @Binding var job: Job

    init(
        dataService: any ProductionDataServiceProtocol,
        job: Binding<Job>
    ) {
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        self._job = job
    }

    @State private var jobs: [Job] = []
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                searchBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        jobListCard

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }

            if isLoading {
                loadingOverlay
            }
        }
        .navigationTitle("Select Job")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .alert("Jobs", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .task {
            await loadJobs()
        }
        .onChange(of: jobVM.searchTerm) { term in
            filterJobs(term)
        }
    }
}

// MARK: - Sections

extension JobPickerScreen {

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                        .frame(width: 58, height: 58)

                    Image(systemName: "briefcase")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Choose a Job")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Select an active or unbilled job to attach this item.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                headerPill(
                    title: "\(jobs.count)",
                    systemImage: "briefcase"
                )

                if job.id != "" {
                    headerPill(
                        title: job.internalId.isEmpty ? "Selected" : job.internalId,
                        systemImage: "checkmark.circle"
                    )
                }

                Spacer()
            }
        }
        .pickerCard(material: true)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Search by job id, customer, or description...", text: $jobVM.searchTerm)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !jobVM.searchTerm.isEmpty {
                Button {
                    jobVM.searchTerm = ""
                    filterJobs("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.regularMaterial)
    }

    private var jobListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Jobs",
                subtitle: "Showing unbilled jobs available for selection.",
                systemImage: "list.bullet.rectangle",
                count: jobs.count
            )

            if jobs.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(jobs) { datum in
                        jobRow(datum)
                    }
                }
            }
        }
        .pickerCard()
    }

    private func jobRow(_ datum: Job) -> some View {
        Button {
            job = datum
            dismiss()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(datum == job ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06))
                        .frame(width: 38, height: 38)

                    Image(systemName: datum == job ? "checkmark.circle.fill" : "briefcase")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(datum == job ? Color.accentColor : .secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(datum.internalId.isEmpty ? "Job" : datum.internalId)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(datum.operationStatus.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                    }

                    Text(datum.customerName.isEmpty ? "No customer name" : datum.customerName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if !datum.description.isEmpty {
                        Text(datum.description)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(fullDate(date: datum.dateCreated))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if datum == job {
                        Text("Selected")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .padding(12)
            .background(
                datum == job
                ? Color.accentColor.opacity(0.10)
                : Color.primary.opacity(0.035),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        datum == job
                        ? Color.accentColor.opacity(0.28)
                        : Color.primary.opacity(0.06),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Loading / Filtering

extension JobPickerScreen {

    private func loadJobs() async {
        guard let company = masterDataManager.currentCompany else {
            alertMessage = "Missing company."
            showAlert = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await jobVM.getAllUnbilledJobs(companyId: company.id)
            jobs = jobVM.workOrders
        } catch {
            print("[JobPickerScreen][loadJobs] Error")
            print(error)

            alertMessage = "Could not load jobs."
            showAlert = true
        }
    }

    private func filterJobs(_ term: String) {
        let cleanTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTerm.isEmpty else {
            jobs = jobVM.workOrders
            return
        }

        let lower = cleanTerm.lowercased()

        jobs = jobVM.workOrders.filter { job in
            job.internalId.lowercased().contains(lower) ||
            job.customerName.lowercased().contains(lower) ||
            job.description.lowercased().contains(lower) ||
            job.operationStatus.rawValue.lowercased().contains(lower) ||
            job.billingStatus.rawValue.lowercased().contains(lower)
        }
    }
}

// MARK: - UI Helpers

extension JobPickerScreen {

    private func sectionHeader(
        title: String,
        subtitle: String,
        systemImage: String,
        count: Int
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

            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.thinMaterial, in: Capsule())
        }
    }

    private func headerPill(
        title: String,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "briefcase")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No jobs found.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Try clearing search or checking whether there are active unbilled jobs.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()

                Text("Loading jobs...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

private extension View {
    func pickerCard(material: Bool = false) -> some View {
        self
            .padding(16)
            .background(
                material ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
    }
}
