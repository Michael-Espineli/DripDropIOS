//
//  AddNewPerformanceHistory.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/3/24.
//

import SwiftUI

struct AddNewPerformanceHistory: View {
    @StateObject var performaceReviewVM : PerformaceHistoryViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @Environment(\.dismiss) private var dismiss

    init(dataService:any ProductionDataServiceProtocol,companyUser:CompanyUser) {
        _receivedCompanyUser = State(wrappedValue: companyUser)
        _performaceReviewVM = StateObject(wrappedValue:PerformaceHistoryViewModel(dataService: dataService))
    }
    @State var receivedCompanyUser:CompanyUser

    @State var description:String = ""
    @State var performaceHistoryType:PerformaceHistoryType = .kudo
    @State var selectedDate: Date = Date()
    @State var reportTitle: String = ""
    @State var reportUrl: String = ""
    @State var reportNotes: String = ""
    @State var reportTechnicianVisible: Bool = false
    @State var photoUrls:[DripDropStoredImage] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        info
                        reportInfo
                        photoInfo
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 92)
                }

                VStack {
                    Spacer()
                    submitButton
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
            .navigationTitle("Add Performance Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Performance Note", isPresented: $performaceReviewVM.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(performaceReviewVM.alertMessage)
            }
        }
    }
}

//#Preview {
//    AddNewPerformanceHistory()
//}
extension AddNewPerformanceHistory {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(receivedCompanyUser.userName, systemImage: "star.bubble")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Capture praise, complaints, coaching notes, reports, and supporting photos.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var info: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Performance Note", systemImage: "square.and.pencil")

            VStack(alignment: .leading, spacing: 8) {
                Text("Note Type")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("Type", selection: $performaceHistoryType) {
                    ForEach(PerformaceHistoryType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .font(.subheadline.weight(.semibold))
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextEditor(text: $description)
                    .frame(minHeight: 130)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var reportInfo: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Attach Report", systemImage: "paperclip")

            labeledTextField("Report Title", text: $reportTitle, prompt: "Reading performance report")
            labeledTextField("Report Link", text: $reportUrl, prompt: "https://...")
            labeledEditor("Report Notes", text: $reportNotes)

            Toggle(isOn: $reportTechnicianVisible) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Share attached report with technician")
                        .font(.subheadline.weight(.semibold))
                    Text("The note stays internal; shared reports can be visible to the technician.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var photoInfo: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Files & Photos", systemImage: "photo.on.rectangle")
            PhotoStoredContent(selectedStoredImages: $photoUrls)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var submitButton: some View {
        Button(action: {
            Task{
                do {
                    if let selectedCompany = masterDataManager.currentCompany {
                        let reports = attachedReports
                        try await performaceReviewVM.createNewPerformanceReview(
                            companyId: selectedCompany.id,
                            companyUser: receivedCompanyUser,
                            performaceHistory: PerformaceHistory(
                                id: UUID().uuidString,
                                userId: receivedCompanyUser.id,
                                userName: receivedCompanyUser.userName,
                                date: selectedDate,
                                description: description,
                                photoUrls: photoUrls,
                                performaceHistoryType: performaceHistoryType,
                                attachedReports: reports,
                                visibleToTechnician: false,
                                companyInternal: true,
                                companyId: selectedCompany.id,
                                companyUserId: receivedCompanyUser.id,
                                technicianUserId: receivedCompanyUser.userId,
                                createdByName: "Management",
                                createdAt: Date(),
                                updatedAt: Date()
                            )
                        )
                        dismiss()
                    }
                } catch {
                    performaceReviewVM.alertMessage = "Failed to save performance note."
                    performaceReviewVM.showAlert = true
                }
            }
        },
               label: {
            HStack {
                if performaceReviewVM.isSaving {
                    ProgressView()
                }
                Image(systemName: "plus")
                Text(performaceReviewVM.isSaving ? "Saving..." : "Add Note")
                Spacer()
                Image(systemName: "checkmark")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(canSubmit ? Color.poolBlue : Color.gray.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        })
        .buttonStyle(.plain)
        .disabled(!canSubmit || performaceReviewVM.isSaving)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var canSubmit: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !reportTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !reportUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !reportNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !photoUrls.isEmpty
    }

    var attachedReports: [PerformanceHistoryAttachedReport] {
        let title = reportTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = reportUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = reportNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty || !url.isEmpty || !notes.isEmpty else { return [] }

        return [
            PerformanceHistoryAttachedReport(
                id: "report_\(UUID().uuidString)",
                title: title.isEmpty ? "Attached report" : title,
                url: url,
                notes: notes,
                isTechnicianVisible: reportTechnicianVisible,
                attachments: []
            )
        ]
    }

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    func labeledTextField(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(prompt, text: text)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    func labeledEditor(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextEditor(text: text)
                .frame(minHeight: 84)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
