//
//  PerformaceHistoryList.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/3/24.
//

import SwiftUI

struct PerformaceHistoryList: View {
    @StateObject var performaceReviewVM : PerformaceHistoryViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var receivedCompanyUser:CompanyUser
    @State private var selectedPerformanceHistory: PerformaceHistory?

    init(dataService:any ProductionDataServiceProtocol,companyUser:CompanyUser) {
        _receivedCompanyUser = State(wrappedValue: companyUser)
        _performaceReviewVM = StateObject(wrappedValue:PerformaceHistoryViewModel(dataService: dataService))
    }
    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        historyList
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }

                if performaceReviewVM.isLoading {
                    ProgressView("Loading performance history...")
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .navigationTitle("Performance History")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await performaceReviewVM.getPerformaceReivewByUserId(companyId: company.id, companyUserId: receivedCompanyUser.id)
                } else {
                    print("Company User Error")
                }
            } catch {
                print("Error Getting DetailView")
                print(error)
            }
        }
        .sheet(item: $selectedPerformanceHistory) { performanceHistory in
            PerformanceHistoryDetailSheet(performanceHistory: performanceHistory)
                .presentationDetents([.medium, .large])
        }
    }
}

//#Preview {
//    PerformaceHistoryList()
//}

extension PerformaceHistoryList {
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(receivedCompanyUser.userName, systemImage: "star.bubble")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Recent saved performance notes, summaries, reports, references, and attachments.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var historyList: some View {
        if performaceReviewVM.performaceHistoryList.isEmpty && !performaceReviewVM.isLoading {
            ContentUnavailableView(
                "No Performance History",
                systemImage: "star.bubble",
                description: Text("Praise, complaints, coaching notes, and summaries will appear here after they are saved.")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            VStack(spacing: 10) {
                ForEach(performaceReviewVM.performaceHistoryList) { performace in
                    Button {
                        selectedPerformanceHistory = performace
                    } label: {
                        PerformanceHistoryCardView(performanceHistory: performace)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

struct PerformanceHistoryDetailSheet: View {
    let performanceHistory: PerformaceHistory
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        PerformanceHistoryCardView(performanceHistory: performanceHistory)
                            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        fullNote
                        references
                        reports
                        filesAndPhotos
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Performance Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var fullNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Full Note", systemImage: "text.alignleft")
                .font(.headline.weight(.semibold))

            Text(performanceHistory.description.isEmpty ? "No notes recorded." : performanceHistory.description)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var references: some View {
        let allReferences = performanceHistory.references.serviceStops + performanceHistory.references.jobs
        if !allReferences.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("References", systemImage: "list.bullet.rectangle")
                    .font(.headline.weight(.semibold))

                ForEach(allReferences) { reference in
                    HStack(spacing: 10) {
                        Image(systemName: reference.type == "job" ? "briefcase" : "mappin.and.ellipse")
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(.thinMaterial, in: Circle())

                        Text(reference.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Spacer()
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    @ViewBuilder
    private var reports: some View {
        if !performanceHistory.attachedReports.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("Attached Reports", systemImage: "paperclip")
                    .font(.headline.weight(.semibold))

                ForEach(performanceHistory.attachedReports) { report in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if let url = URL(string: report.url), !report.url.isEmpty {
                                Link(report.title, destination: url)
                                    .font(.subheadline.weight(.semibold))
                            } else {
                                Text(report.title)
                                    .font(.subheadline.weight(.semibold))
                            }

                            Spacer()

                            Label(report.isTechnicianVisible ? "Technician" : "Internal", systemImage: report.isTechnicianVisible ? "eye" : "eye.slash")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        if !report.notes.isEmpty {
                            Text(report.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    @ViewBuilder
    private var filesAndPhotos: some View {
        let photos = performanceHistory.photoUrls
        if !performanceHistory.attachments.isEmpty || !photos.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("Files & Photos", systemImage: "photo.on.rectangle")
                    .font(.headline.weight(.semibold))

                ForEach(performanceHistory.attachments) { attachment in
                    attachmentRow(title: attachment.title, urlString: attachment.url)
                }

                ForEach(photos) { photo in
                    attachmentRow(title: photo.description, urlString: photo.imageURL)
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func attachmentRow(title: String, urlString: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "paperclip")
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            if let url = URL(string: urlString), !urlString.isEmpty {
                Link(title.isEmpty ? "Attachment" : title, destination: url)
                    .font(.subheadline.weight(.semibold))
            } else {
                Text(title.isEmpty ? "Attachment" : title)
                    .font(.subheadline.weight(.semibold))
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
