    //
    //  JobTaskCardView.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 11/23/24.
    //

    import SwiftUI
    import Foundation
    import FirebaseFirestore
    import MapKit

    @MainActor
    final class JobTaskCardViewModel: ObservableObject {
        let dataService: any ProductionDataServiceProtocol

        init(dataService: any ProductionDataServiceProtocol) {
            self.dataService = dataService
        }

        @Published private(set) var serviceStop: ServiceStop? = nil
        @Published private(set) var laborContract: LaborContract? = nil
        @Published private(set) var isLoading: Bool = false

        @Published private(set) var bow: BodyOfWater? = nil
        @Published private(set) var equipment: Equipment? = nil
        @Published private(set) var shoppingListItem: ShoppingListItem? = nil
        @Published private(set) var dataBaseItem: DataBaseItem? = nil

        func onLoad(companyId: String, jobTask: JobTask) async throws {
            print("")
            print("-------------- on Load JobTaskCardView - [JobTaskCardViewModel]---------------------")

            switch jobTask.workerType {
            case .contractor:
                print("contractor")
                print("jobTask.laborContractId \(jobTask.laborContractId)")
                self.laborContract = try await dataService.getLaborContract(laborContractId: jobTask.laborContractId)

            case .employee:
                print("Employee")
                print("jobTask.serviceStopId.id \(jobTask.serviceStopId.id)")
                self.serviceStop = try await dataService.getServiceStopById(
                    serviceStopId: jobTask.serviceStopId.id,
                    companyId: companyId
                )

            case .notAssigned:
                print("notAssigned")
            }

            print(jobTask.type)

            switch jobTask.type {
            case .basic, .clean, .inspection:
                print("")

            case .cleanFilter:
                self.equipment = try await dataService.getSinglePieceOfEquipment(
                    companyId: companyId,
                    equipmentId: jobTask.equipmentId
                )

            case .emptyWater:
                self.bow = try await dataService.getSpecificBodyOfWater(
                    companyId: companyId,
                    bodyOfWaterId: jobTask.bodyOfWaterId
                )

            case .fillWater:
                self.bow = try await dataService.getSpecificBodyOfWater(
                    companyId: companyId,
                    bodyOfWaterId: jobTask.bodyOfWaterId
                )

            case .install:
                self.dataBaseItem = try await dataService.getDataBaseItem(
                    companyId: companyId,
                    dataBaseItemId: jobTask.dataBaseItemId
                )

            case .remove:
                self.equipment = try await dataService.getSinglePieceOfEquipment(
                    companyId: companyId,
                    equipmentId: jobTask.equipmentId
                )

            case .replace:
                self.equipment = try await dataService.getSinglePieceOfEquipment(
                    companyId: companyId,
                    equipmentId: jobTask.equipmentId
                )

                self.dataBaseItem = try await dataService.getDataBaseItem(
                    companyId: companyId,
                    dataBaseItemId: jobTask.dataBaseItemId
                )

            case .maintenance:
                self.equipment = try await dataService.getSinglePieceOfEquipment(
                    companyId: companyId,
                    equipmentId: jobTask.equipmentId
                )

            case .repair:
                self.equipment = try await dataService.getSinglePieceOfEquipment(
                    companyId: companyId,
                    equipmentId: jobTask.equipmentId
                )
            }
        }
    }

    struct JobTaskCardView: View {
        @EnvironmentObject var dataService: ProductionDataService
        @EnvironmentObject var masterDataManager: MasterDataManager

        @StateObject var VM: JobTaskCardViewModel
        @State var jobId: String
        @State var jobTask: JobTask

        init(
            dataService: any ProductionDataServiceProtocol,
            jobId: String,
            jobTask: JobTask
        ) {
            _VM = StateObject(wrappedValue: JobTaskCardViewModel(dataService: dataService))
            _jobId = State(wrappedValue: jobId)
            _jobTask = State(wrappedValue: jobTask)
        }

        var body: some View {
            cardContent
                .opacity(isLocked ? 0.68 : 1)
                .disabled(isLocked)
                .task {
                    if let currentCompany = masterDataManager.currentCompany {
                        do {
                            try await VM.onLoad(
                                companyId: currentCompany.id,
                                jobTask: jobTask
                            )
                        } catch {
                            print(error)
                        }
                    }
                }
        }
    }

    // MARK: - Main UI

    extension JobTaskCardView {

        var cardContent: some View {
            VStack(alignment: .leading, spacing: 12) {
                topRow

                assignmentRow

                metricsRow

                if !extraInfoText.isEmpty || VM.isLoading {
                    Divider()
                        .opacity(0.35)

                    extraInfoRow
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isLocked ? Color.yellow.opacity(0.10) : Color.primary.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isLocked ? Color.yellow.opacity(0.22) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }

        var topRow: some View {
            HStack(alignment: .top, spacing: 12) {
                taskStatusIcon

                VStack(alignment: .leading, spacing: 5) {
                    Text(jobTask.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        statusBadge
                        typeBadge
                    }
                }

                Spacer(minLength: 0)
            }
        }

        var taskStatusIcon: some View {
            Image(systemName: statusIconName)
                .font(.body.weight(.semibold))
                .foregroundStyle(statusIconColor)
                .frame(width: 32, height: 32)
                .background(statusIconColor.opacity(0.12), in: Circle())
        }

        var statusBadge: some View {
            Text(jobTask.status.rawValue)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(statusIconColor)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(statusIconColor.opacity(0.12), in: Capsule())
        }

        var typeBadge: some View {
            Text(jobTask.type.rawValue)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.thinMaterial, in: Capsule())
        }

        var assignmentRow: some View {
            HStack(spacing: 10) {
                Image(systemName: assignmentIconName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(.thinMaterial, in: Circle())

                assignmentContent

                Spacer(minLength: 0)
            }
        }

        @ViewBuilder
        var assignmentContent: some View {
            switch jobTask.workerType {
            case .contractor:
                VStack(alignment: .leading, spacing: 2) {
                    Text("Contractor")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if jobTask.laborContractId.isEmpty {
                        Text("No labor contract assigned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(jobTask.laborContractId)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }

            case .employee:
                if let serviceStop = VM.serviceStop {
                    NavigationLink(value: Route.serviceStop(serviceStop: serviceStop, dataService: dataService)) {
                        HStack(spacing: 6) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Employee")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                Text("Service Stop Details")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Employee")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text("Service Stop Details")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

            case .notAssigned:
                VStack(alignment: .leading, spacing: 2) {
                    Text("Worker")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text("Not Assigned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }

        var metricsRow: some View {
            HStack(spacing: 10) {
                metricPill(
                    title: "Rate",
                    value: "\(Double(jobTask.contractedRate) / 100)",
                    systemImage: "dollarsign.circle"
                )

                metricPill(
                    title: "Time",
                    value: displayNumberAsMinAndHour(seconds: jobTask.estimatedTime),
                    systemImage: "timer"
                )
            }
        }

        func metricPill(
            title: String,
            value: String,
            systemImage: String
        ) -> some View {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }

        var extraInfoRow: some View {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: extraInfoIconName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                if VM.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()

                        Text("Loading details...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(extraInfoText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Computed Helpers

    extension JobTaskCardView {

        var isLocked: Bool {
            switch jobTask.status {
            case .accepted, .offered, .scheduled, .finished, .inProgress:
                return true
            case .unassigned, .rejected, .draft:
                return false
            }
        }

        var statusIconName: String {
            switch jobTask.status {
            case .finished:
                return "checkmark.circle.fill"
            case .scheduled, .accepted:
                return "calendar.badge.checkmark"
            case .inProgress:
                return "play.circle.fill"
            case .offered:
                return "paperplane.circle.fill"
            case .rejected:
                return "xmark.circle.fill"
            case .draft:
                return "doc.circle"
            case .unassigned:
                return "circle"
            }
        }

        var statusIconColor: Color {
            switch jobTask.status {
            case .finished:
                return Color.poolGreen
            case .scheduled, .accepted, .inProgress:
                return Color.blue
            case .offered:
                return Color.orange
            case .rejected:
                return Color.red
            case .draft, .unassigned:
                return Color.secondary
            }
        }

        var assignmentIconName: String {
            switch jobTask.workerType {
            case .contractor:
                return "person.2"
            case .employee:
                return "person.crop.circle"
            case .notAssigned:
                return "person.crop.circle.badge.questionmark"
            }
        }

        var extraInfoIconName: String {
            switch jobTask.type {
            case .basic, .clean, .inspection:
                return "info.circle"
            case .cleanFilter, .remove, .replace, .maintenance, .repair:
                return "gearshape"
            case .emptyWater, .fillWater:
                return "drop"
            case .install:
                return "shippingbox"
            }
        }

        var extraInfoText: String {
            switch jobTask.type {
            case .basic, .clean, .inspection:
                return ""

            case .cleanFilter:
                if let equipment = VM.equipment {
                    return "\(equipment.name) - \(equipment.make): \(equipment.model)"
                }
                return ""

            case .emptyWater:
                if let bow = VM.bow {
                    return bow.name
                }
                return ""

            case .fillWater:
                if let bow = VM.bow {
                    return bow.name
                }
                return ""

            case .install:
                if let dataBaseItem = VM.dataBaseItem {
                    return dataBaseItem.name
                }
                return ""

            case .remove:
                if let equipment = VM.equipment {
                    return "\(equipment.name) - \(equipment.make): \(equipment.model)"
                }
                return ""

            case .replace:
                var values: [String] = []

                if let equipment = VM.equipment {
                    values.append("\(equipment.name) - \(equipment.make): \(equipment.model)")
                }

                if let dataBaseItem = VM.dataBaseItem {
                    values.append(dataBaseItem.name)
                }

                return values.joined(separator: " → ")

            case .maintenance:
                if let equipment = VM.equipment {
                    return "\(equipment.name) - \(equipment.make): \(equipment.model)"
                }
                return ""

            case .repair:
                if let equipment = VM.equipment {
                    return "\(equipment.name) - \(equipment.make): \(equipment.model)"
                }
                return ""
            }
        }
    }
