//
//  EquipmentDetailStartUpView.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/29/24.
//

import SwiftUI

struct EquipmentDetailStartUpView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let dataService: any ProductionDataServiceProtocol
    @Binding var equipmentList:[Equipment]
    @Binding var selectedEquipmentId:String
    @Binding var photos:[String:[DripDropImage]]

    @State var name:String = ""

    @State var make:String = ""
    @State var model:String = ""
    @State var dateInstalled:Date = Date()
    @State var status:EquipmentStatus = .operational
    @State var notes:String = ""
    
    @State var needsService:Bool = false
    @State var lastServiced:Date = Date()
    @State var lastServicedOptional:Date? = Date()

    @State var serviceFrequency:String? = ""
    @State var serviceFrequencyEvery:String? = ""
    @State var images:[UIImage] = []
    @State var selectedPhotos:[DripDropImage] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach($equipmentList) { $equipment in
                if equipment.id == selectedEquipmentId {
                    equipmentDetailCard($equipment)
                }
                
            }
        }
        .onAppear(perform: {
            print("")

            print("On Appear selectedEquipmentId")
            selectedPhotos = []
            if let preselectedPhotos = photos[selectedEquipmentId] {
                selectedPhotos = preselectedPhotos
                print(preselectedPhotos)
            } else {
                selectedPhotos = []
            }
        })
        .onChange(of: selectedEquipmentId, perform: { id in
            print("")
            selectedPhotos = []
            print("Change of selected Equipment Id")
            if let preselectedPhotos = photos[id] {
                selectedPhotos = preselectedPhotos
                print("selectedPhotos")

                print(selectedPhotos)

            } else {
                selectedPhotos = []
                print("selectedPhotos")
                print(selectedPhotos)

            }
        })
        .onChange(of: selectedPhotos, perform: { images in
            print("")
            print("Change Of Selected Photos")
            print(images)
            photos[selectedEquipmentId] = images
        })
    }
}

//#Preview {
//    EquipmentDetailStartUpView()
//}

private extension EquipmentDetailStartUpView {
    func equipmentDetailCard(_ equipment: Binding<Equipment>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            equipmentHeader(equipment)

            VStack(spacing: 10) {
                startupTextField(title: "Name", text: equipment.name)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Catalog Match", systemImage: "list.bullet.rectangle")
                        .font(.subheadline.weight(.semibold))

                    EquipmentCatalogSelectionControl(
                        dataService: dataService,
                        category: equipment.type,
                        typeId: equipment.typeId,
                        make: equipment.make,
                        makeId: equipment.makeId,
                        model: equipment.model,
                        modelId: equipment.modelId,
                        universalEquipmentId: equipment.universalEquipmentId,
                        manualPdfLink: equipment.manualPdfLink,
                        name: equipment.name
                    )
                }
                .padding(10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                LazyVGrid(
                    columns: fieldColumns,
                    spacing: 10
                ) {
                    startupTextField(
                        title: "Make",
                        text: Binding(
                            get: { equipment.wrappedValue.make },
                            set: {
                                equipment.wrappedValue.make = $0
                                equipment.wrappedValue.makeId = ""
                                equipment.wrappedValue.modelId = ""
                                equipment.wrappedValue.universalEquipmentId = ""
                                equipment.wrappedValue.manualPdfLink = ""
                            }
                        )
                    )

                    startupTextField(
                        title: "Model",
                        text: Binding(
                            get: { equipment.wrappedValue.model },
                            set: {
                                equipment.wrappedValue.model = $0
                                equipment.wrappedValue.modelId = ""
                                equipment.wrappedValue.universalEquipmentId = ""
                                equipment.wrappedValue.manualPdfLink = ""
                            }
                        )
                    )
                }

                LazyVGrid(
                    columns: fieldColumns,
                    spacing: 10
                ) {
                    dateInstalledField(equipment)
                    statusField(equipment)
                }

                startupTextField(
                    title: "Notes",
                    text: equipment.notes,
                    lineLimit: 3...6
                )
            }

            serviceScheduleSection(equipment)

            VStack(alignment: .leading, spacing: 10) {
                Label("Equipment Photos", systemImage: "camera.fill")
                    .font(.headline.weight(.semibold))

                PhotoContentView(selectedImages: $selectedPhotos)
            }
        }
        .padding(10)
        .background(Color.listColor.opacity(0.70), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    func equipmentHeader(_ equipment: Binding<Equipment>) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: equipmentIcon(for: equipment.wrappedValue.type))
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 36, height: 36)
                .background(Color.poolBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(equipment.wrappedValue.name.isEmpty ? "Equipment" : equipment.wrappedValue.name)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)

                Text(equipment.wrappedValue.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button(role: .destructive) {
                deleteEquipment(equipment.wrappedValue)
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Color.red.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete equipment")
        }
    }

    func startupTextField(
        title: String,
        text: Binding<String>,
        lineLimit: ClosedRange<Int>? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let lineLimit {
                TextField(title, text: text, axis: .vertical)
                    .lineLimit(lineLimit)
                    .padding(10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .foregroundColor(Color.basicFontText)
            } else {
                TextField(title, text: text)
                    .padding(10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .foregroundColor(Color.basicFontText)
            }
        }
    }

    func dateInstalledField(_ equipment: Binding<Equipment>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Date Installed")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            DatePicker("", selection: equipment.dateInstalled, displayedComponents: .date)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    func statusField(_ equipment: Binding<Equipment>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Status")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Menu {
                ForEach(EquipmentStatus.allCases, id: \.self) { status in
                    Button {
                        equipment.wrappedValue.status = status
                    } label: {
                        Text(status.displayName)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    equipmentStatusBadge(equipment.wrappedValue.status)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    func serviceScheduleSection(_ equipment: Binding<Equipment>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: equipment.needsService) {
                Label("Needs Regular Service", systemImage: "calendar.badge.clock")
                    .font(.headline.weight(.semibold))
            }

            if equipment.wrappedValue.needsService {
                LazyVGrid(
                    columns: fieldColumns,
                    spacing: 10
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Last Serviced")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        DatePicker(
                            "",
                            selection: optionalDateBinding(equipment.lastServiceDate),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Frequency")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            Picker("Every", selection: optionalIntBinding(equipment.serviceFrequency, defaultValue: 1)) {
                                ForEach(1...100, id: \.self) {
                                    Text(String($0)).tag($0)
                                }
                            }
                            .pickerStyle(.menu)

                            Picker("Frequency", selection: optionalFrequencyBinding(equipment.serviceFrequencyEvery)) {
                                ForEach(EquipmentFrequency.allCases) { frequency in
                                    Text(frequency.rawValue).tag(frequency)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func deleteEquipment(_ equipment: Equipment) {
        equipmentList.removeAll { $0.id == equipment.id }
        selectedEquipmentId = ""
    }

    var fieldColumns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible(), spacing: 10)]
        }

        return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    func equipmentStatusBadge(_ status: EquipmentStatus) -> some View {
        Text(status.displayName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(statusTint(for: status))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusTint(for: status).opacity(0.12), in: Capsule())
    }

    func statusTint(for status: EquipmentStatus) -> Color {
        switch status {
        case .operational:
            return Color.poolGreen
        case .needsRepair:
            return Color.orange
        case .nonoperational:
            return Color.poolRed
        case .needsMaintenance:
            return Color.yellow
        case .replaced:
            return Color.secondary
        }
    }

    func equipmentIcon(for category: EquipmentCategory) -> String {
        switch category {
        case .pump:
            return "gearshape.2.fill"
        case .filter:
            return "line.3.horizontal.decrease.circle.fill"
        case .heater:
            return "flame.fill"
        case .saltCell:
            return "sparkles"
        case .cleaner:
            return "wand.and.stars"
        case .light:
            return "lightbulb.fill"
        case .controlSystem:
            return "switch.2"
        case .autoChlorinator:
            return "drop.degreesign.fill"
        }
    }

    func optionalDateBinding(_ value: Binding<Date?>) -> Binding<Date> {
        Binding(
            get: { value.wrappedValue ?? Date() },
            set: { value.wrappedValue = $0 }
        )
    }

    func optionalIntBinding(_ value: Binding<Int?>, defaultValue: Int) -> Binding<Int> {
        Binding(
            get: { value.wrappedValue ?? defaultValue },
            set: { value.wrappedValue = $0 }
        )
    }

    func optionalFrequencyBinding(_ value: Binding<EquipmentFrequency?>) -> Binding<EquipmentFrequency> {
        Binding(
            get: { value.wrappedValue ?? .monthly },
            set: { value.wrappedValue = $0 }
        )
    }
}
