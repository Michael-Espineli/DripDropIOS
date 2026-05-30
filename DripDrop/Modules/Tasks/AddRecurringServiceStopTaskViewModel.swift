//
//  AddRecurringServiceStopTask.swift
//  DripDrop
//
//  Created by Michael Espineli
//

import SwiftUI

@MainActor
final class AddRecurringServiceStopTaskViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published var itemName: String = ""
    @Published var itemType: JobTaskType = .basic
    @Published var itemDescription: String = ""
    @Published var itemRate: String = "0"
    @Published var itemEstimatedTime: String = "0"

    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    var canSubmit: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(itemEstimatedTime) != nil &&
        Double(itemRate) != nil
    }

    func validateRate() {
        if itemRate.isEmpty { return }

        if Double(itemRate) == nil {
            itemRate = String(itemRate.dropLast())
        }
    }

    func validateEstimatedTime() {
        if itemEstimatedTime.isEmpty { return }

        if Int(itemEstimatedTime) == nil {
            itemEstimatedTime = String(itemEstimatedTime.dropLast())
        }
    }

    func buildTaskItem() -> JobTaskGroupItem? {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = itemDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Task name is required."
            showError = true
            return nil
        }

        guard let estimatedTime = Int(itemEstimatedTime) else {
            errorMessage = "Estimated time must be a whole number."
            showError = true
            return nil
        }

        guard let rate = Double(itemRate) else {
            errorMessage = "Rate must be a valid number."
            showError = true
            return nil
        }

        let contractedRate = Int((rate * 100).rounded())

        return JobTaskGroupItem(
            id: UUID().uuidString,
            name: trimmedName,
            type: itemType,
            description: trimmedDescription,
            contractedRate: contractedRate,
            estimatedTime: estimatedTime
        )
    }

    func clear() {
        itemName = ""
        itemType = .basic
        itemDescription = ""
        itemRate = "0"
        itemEstimatedTime = "0"
        showError = false
        errorMessage = ""
    }
}

struct AddRecurringServiceStopTask: View {
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var masterDataManager: MasterDataManager
    @Environment(\.dismiss) private var dismiss

    @StateObject var VM: AddRecurringServiceStopTaskViewModel
    @Binding var tasks: [JobTaskGroupItem]

    init(
        dataService: any ProductionDataServiceProtocol,
        tasks: Binding<[JobTaskGroupItem]>
    ) {
        _VM = StateObject(wrappedValue: AddRecurringServiceStopTaskViewModel(dataService: dataService))
        self._tasks = tasks
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 16) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        form

                        if VM.showError {
                            errorCard
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 20)
                }

                bottomButtons
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }
            .padding(.top, 12)
        }
        .onChange(of: VM.itemRate) { _ in
            VM.validateRate()
        }
        .onChange(of: VM.itemEstimatedTime) { _ in
            VM.validateEstimatedTime()
        }
    }
}

// MARK: - Views

extension AddRecurringServiceStopTask {

    var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Task")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Create a one-off task for this recurring service stop.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 14)
    }

    var form: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Task Details", systemImage: "checkmark.circle")

            VStack(alignment: .leading, spacing: 8) {
                Label("Task Name", systemImage: "text.cursor")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Task name", text: $VM.itemName)
                    .font(.subheadline)
                    .textInputAutocapitalization(.words)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Type", systemImage: "tag")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("Type", selection: $VM.itemType) {
                    ForEach(JobTaskType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Description", text: $VM.itemDescription, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Rate", systemImage: "dollarsign.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        Text("$")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField("0", text: $VM.itemRate)
                            .font(.subheadline)
                            .keyboardType(.decimalPad)
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Est. Time", systemImage: "timer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        TextField("0", text: $VM.itemEstimatedTime)
                            .font(.subheadline)
                            .keyboardType(.numberPad)

                        Text("min")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var errorCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.body)
                .foregroundStyle(.red)

            Text(VM.errorMessage.isEmpty ? "Please check the task details." : VM.errorMessage)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(14)
        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var bottomButtons: some View {
        HStack(spacing: 12) {
            Button {
                VM.clear()
            } label: {
                Label("Clear", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                addTaskAndDismiss()
            } label: {
                Label("Add Task", systemImage: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!VM.canSubmit)
            .opacity(VM.canSubmit ? 1 : 0.45)
        }
    }

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    func addTaskAndDismiss() {
        guard let item = VM.buildTaskItem() else { return }

        tasks.append(item)

        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        dismiss()
    }
}

//#Preview {
//    AddRecurringServiceStopTask(
//        dataService: MockDataService(),
//        tasks: .constant([])
//    )
//}