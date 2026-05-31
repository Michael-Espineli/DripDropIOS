    //
    //  CompanyUserPicker.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 7/6/24.
    //

    import SwiftUI

    struct CompanyUserPicker: View {
        
        init(dataService: any ProductionDataServiceProtocol, companyUser: Binding<CompanyUser>) {
            _VM = StateObject(wrappedValue: TechListViewModel(dataService: dataService))
            self._companyUser = companyUser
        }
        
        @Environment(\.dismiss) private var dismiss
        @EnvironmentObject var masterDataManager: MasterDataManager
        
        @StateObject var VM: TechListViewModel
        
        @Binding var companyUser: CompanyUser
        
        var body: some View {
            ZStack {
                Color.listColor.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        userList
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .task {
                do {
                    if let company = masterDataManager.currentCompany {
                        try await VM.getActiveCompanyUsers(companyId: company.id)
                    }
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
    }

    extension CompanyUserPicker {
        
        var headerCard: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Select Technician")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        Text("Choose the team member responsible for this work.")
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
                
                HStack(spacing: 8) {
                    Label("\(VM.companyUsers.count) Available", systemImage: "person.2")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                    
                    if !companyUser.id.isEmpty {
                        Label(companyUser.userName, systemImage: "checkmark.circle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.poolGreen)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.poolGreen.opacity(0.12), in: Capsule())
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        
        var userList: some View {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Team Members", systemImage: "person.crop.circle")
                
                if VM.companyUsers.isEmpty {
                    emptyState(
                        title: "No active users found.",
                        message: "Active company users will appear here.",
                        systemImage: "person.crop.circle.badge.questionmark"
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(VM.companyUsers) { datum in
                            userRow(datum)
                        }
                    }
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        
        func userRow(_ datum: CompanyUser) -> some View {
            let isSelected = datum == companyUser
            
            return Button {
                companyUser = datum
                
                #if os(iOS)
                UISelectionFeedbackGenerator().selectionChanged()
                #endif
                
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.poolGreen.opacity(0.14) : Color.primary.opacity(0.06))
                            .frame(width: 38, height: 38)
                        
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "person.crop.circle")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(isSelected ? Color.poolGreen : .secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(datum.userName.isEmpty ? "Unnamed User" : datum.userName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            if !datum.roleName.isEmpty {
                                Text(datum.roleName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            if !datum.workerType.rawValue.isEmpty {
                                Text(datum.workerType.rawValue)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(.thinMaterial, in: Capsule())
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.poolGreen : .secondary)
                }
                .padding(12)
                .background(
                    isSelected ? Color.poolGreen.opacity(0.08) : Color.primary.opacity(0.035),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? Color.poolGreen.opacity(0.22) : Color.primary.opacity(0.06), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        
        func sectionHeader(_ title: String, systemImage: String) -> some View {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        
        func emptyState(title: String, message: String, systemImage: String) -> some View {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
