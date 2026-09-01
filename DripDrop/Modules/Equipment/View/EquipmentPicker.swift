//
//  EquipmentPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/31/25.
//

import SwiftUI

struct EquipmentPickerByServiceLocationId: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    
    @StateObject var VM: EquipmentViewModel
    
    @Binding var equipment: Equipment
    @State var serviceLocationId: String
    @State var search: String = ""
    @State private var isLoading: Bool = true
    @State private var loadError: String?

    init(dataService: any ProductionDataServiceProtocol, serviceLocationId: String, equipment: Binding<Equipment>) {
        _VM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
        self._equipment = equipment
        _serviceLocationId = State(wrappedValue: serviceLocationId)
    }
    
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                pickerHeader
                
                if isLoading {
                    loadingView
                } else if let loadError {
                    emptyState(
                        title: "Unable to Load Equipment",
                        message: loadError,
                        systemImage: "exclamationmark.triangle"
                    )
                } else if VM.listOfEquipment.isEmpty {
                    emptyState(
                        title: "No Equipment Found",
                        message: "There is no equipment saved for this location yet.",
                        systemImage: "wrench.and.screwdriver"
                    )
                } else if filteredEquipment.isEmpty {
                    emptyState(
                        title: "No Matches",
                        message: "Try another name, type, make, model, or status.",
                        systemImage: "magnifyingglass"
                    )
                } else {
                    equipmentList
                }
            }
        }
        .task {
            await loadEquipment()
        }
    }
}

extension EquipmentPickerByServiceLocationId {
    var pickerHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Select Equipment")
                        .font(.title3.weight(.semibold))
                    
                    Text("Choose the piece tied to this repair request.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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
            
            searchBar
            
            HStack(spacing: 8) {
                Label("\(filteredEquipment.count)", systemImage: "wrench.and.screwdriver")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
                
                if equipment.id != "" {
                    Label("Selected", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.poolGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.poolGreen.opacity(0.12), in: Capsule())
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial)
    }
    
    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            TextField("Search equipment", text: $search)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    var equipmentList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(filteredEquipment) { datum in
                    equipmentRow(datum)
                }
            }
            .padding(14)
            .padding(.bottom, 24)
        }
    }
    
    func equipmentRow(_ datum: Equipment) -> some View {
        let isSelected = equipment == datum
        
        return Button {
            equipment = datum
            dismiss()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: equipmentIcon(for: datum.type))
                    .font(.headline)
                    .foregroundStyle(isSelected ? Color.white : Color.poolGreen)
                    .frame(width: 42, height: 42)
                    .background(
                        isSelected ? Color.poolGreen : Color.poolGreen.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(datum.name.isEmpty ? datum.typeDisplayName : datum.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        
                        Spacer(minLength: 8)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(Color.poolGreen)
                        }
                    }
                    
                    Text(equipmentSubtitle(for: datum))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        statusBadge(for: datum.status)
                        
                        if datum.needsService {
                            Label("Maintenance", systemImage: "calendar.badge.clock")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }
                }
            }
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.poolGreen : Color.clear, lineWidth: 1.5)
            }
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
    
    var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            
            Text("Loading equipment...")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func emptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 52, height: 52)
                .background(.thinMaterial, in: Circle())
            
            Text(title)
                .font(.headline.weight(.semibold))
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func statusBadge(for status: EquipmentStatus) -> some View {
        let colors = statusColors(for: status)
        
        return Label(status.displayName, systemImage: statusIcon(for: status))
            .font(.caption.weight(.semibold))
            .foregroundStyle(colors.foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(colors.background, in: Capsule())
    }
}

private extension EquipmentPickerByServiceLocationId {
    var filteredEquipment: [Equipment] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !term.isEmpty else {
            return VM.listOfEquipment
        }
        
        return VM.listOfEquipment.filter { datum in
            [
                datum.name,
                datum.typeDisplayName,
                datum.make,
                datum.model,
                datum.status.displayName
            ]
                .joined(separator: " ")
                .localizedCaseInsensitiveContains(term)
        }
    }
    
    func loadEquipment() async {
        do {
            isLoading = true
            loadError = nil
            
            if let company = masterDataManager.currentCompany {
                try await VM.getAllEquipmentFromServiceLocationId(
                    companyId: company.id,
                    serviceLocationId: serviceLocationId
                )
                
                if VM.listOfEquipment.count == 1 {
                    equipment = VM.listOfEquipment[0]
                    dismiss()
                }
            }
        } catch {
            loadError = "Please try again in a moment."
            print(error)
        }
        
        isLoading = false
    }
    
    func equipmentSubtitle(for datum: Equipment) -> String {
        let makeModel = [datum.make, datum.model]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        if makeModel.isEmpty {
            return datum.typeDisplayName
        }
        
        return "\(datum.typeDisplayName) • \(makeModel)"
    }
    
    func equipmentIcon(for type: EquipmentCategory) -> String {
        switch type {
        case .pump:
            return "arrow.triangle.2.circlepath"
        case .filter:
            return "line.3.horizontal.decrease.circle"
        case .heater:
            return "flame"
        case .saltCell:
            return "drop.triangle"
        case .light:
            return "lightbulb"
        case .cleaner:
            return "sparkles"
        case .controlSystem:
            return "switch.2"
        case .autoChlorinator:
            return "drop.circle"
        case .other:
            return "wrench.and.screwdriver"
        }
    }
    
    func statusIcon(for status: EquipmentStatus) -> String {
        switch status {
        case .operational:
            return "checkmark.circle"
        case .nonoperational:
            return "xmark.circle"
        case .needsRepair:
            return "cross.case"
        case .needsMaintenance:
            return "wrench.and.screwdriver"
        case .replaced:
            return "arrow.triangle.2.circlepath"
        }
    }
    
    func statusColors(for status: EquipmentStatus) -> (foreground: Color, background: Color) {
        switch status {
        case .operational:
            return (Color.poolGreen, Color.poolGreen.opacity(0.12))
        case .nonoperational:
            return (Color.red, Color.red.opacity(0.12))
        case .needsRepair:
            return (Color.orange, Color.orange.opacity(0.12))
        case .needsMaintenance:
            return (Color.yellow, Color.yellow.opacity(0.16))
        case .replaced:
            return (Color.gray, Color.gray.opacity(0.16))
        }
    }
}
