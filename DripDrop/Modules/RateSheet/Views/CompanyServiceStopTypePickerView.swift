//
//  CompanyServiceStopTypePickerView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/20/26.
//


import SwiftUI

@MainActor
final class CompanyServiceStopTypePickerViewModel: ObservableObject {

    @Published var serviceStopTypes: [CompanyServiceStopType] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let companyId: String
    private let dataService: any ProductionDataServiceProtocol
    private var hasLoaded = false

    init(
        companyId: String,
        dataService: any ProductionDataServiceProtocol
    ) {
        self.companyId = companyId
        self.dataService = dataService
    }

    var activeServiceStopTypes: [CompanyServiceStopType] {
        serviceStopTypes
            .filter { $0.isActive }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.name < $1.name
                }

                return $0.sortOrder < $1.sortOrder
            }
    }

    func activeServiceStopTypes(
        useCase: ServiceStopTypeUseCase
    ) -> [CompanyServiceStopType] {
        ServiceStopTypeResolver.matchingTypes(
            from: serviceStopTypes,
            useCase: useCase
        )
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            serviceStopTypes = try await dataService.fetchCompanyServiceStopTypes(
                companyId: companyId
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func suggestedType(
        useCase: ServiceStopTypeUseCase
    ) -> CompanyServiceStopType? {
        ServiceStopTypeResolver.suggestedType(
            from: serviceStopTypes,
            useCase: useCase
        )
    }

    func type(id: String) -> CompanyServiceStopType? {
        activeServiceStopTypes.first { $0.id == id }
    }
}

struct CompanyServiceStopTypePickerView: View {

    @StateObject private var viewModel: CompanyServiceStopTypePickerViewModel

    @Binding private var selectedType: CompanyServiceStopType?
    @State private var showTypePicker: Bool = false

    let useCase: ServiceStopTypeUseCase
    let title: String
    let subtitle: String
    let preferredTypeId: String?

    init(
        companyId: String,
        dataService: any ProductionDataServiceProtocol,
        selectedType: Binding<CompanyServiceStopType?>,
        useCase: ServiceStopTypeUseCase,
        title: String = "Pay Type",
        subtitle: String = "Choose the base pay type for this stop.",
        preferredTypeId: String? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: CompanyServiceStopTypePickerViewModel(
                companyId: companyId,
                dataService: dataService
            )
        )

        _selectedType = selectedType
        self.useCase = useCase
        self.title = title
        self.subtitle = subtitle
        self.preferredTypeId = preferredTypeId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text("Could not load pay types: \(errorMessage)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if viewModel.activeServiceStopTypes(useCase: useCase).isEmpty && !viewModel.isLoading {
                fallbackCard
            } else {
                Button {
                    showTypePicker = true
                } label: {
                    selectedTypeRow
                }
                .buttonStyle(.plain)
            }
        }
        .task {
            await viewModel.loadIfNeeded()
            applyPreferredOrSuggestedTypeIfNeeded(forcePreferred: true)
        }
        .onChange(of: preferredTypeId) { _ in
            applyPreferredOrSuggestedTypeIfNeeded(forcePreferred: true)
        }
        .onChange(of: useCase) { _, _ in
            applyPreferredOrSuggestedTypeIfNeeded(forcePreferred: false)
        }
        .sheet(isPresented: $showTypePicker) {
            typePickerSheet
        }
    }

    private func applyPreferredOrSuggestedTypeIfNeeded(forcePreferred: Bool) {
        if forcePreferred, let preferredTypeId {
            let preferredType = viewModel.type(id: preferredTypeId)
            if let preferredType,
               ServiceStopTypeResolver.matches(preferredType, useCase: useCase) {
                selectedType = preferredType
                return
            } else {
                selectedType = nil
            }
        }

        if let selectedType,
           !ServiceStopTypeResolver.matches(selectedType, useCase: useCase) {
            self.selectedType = nil
        }

        if selectedType == nil {
            selectedType = viewModel.suggestedType(useCase: useCase)
        }
    }

    private var fallbackCard: some View {
        let fields = ServiceStopTypeResolver.serviceStopTypeFields(
            selectedType: nil,
            useCase: useCase
        )

        return HStack(spacing: 10) {
            Image(systemName: fields.typeImage)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(fields.type)
                    .font(.subheadline.weight(.semibold))

                Text("Fallback pay type. Add company pay types later for more control.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var selectedTypeRow: some View {
        HStack(spacing: 10) {
            if let selectedType {
                selectedTypeIcon(selectedType)

                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedType.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(typeSubtitle(selectedType))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "mappin.and.ellipse")
                    .frame(width: 28)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Choose pay type")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Tap to select")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var typePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(viewModel.activeServiceStopTypes(useCase: useCase)) { type in
                    Button {
                        selectedType = type
                        showTypePicker = false
                    } label: {
                        HStack(spacing: 12) {
                            selectedTypeIcon(type)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(type.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text(typeSubtitle(type))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedType?.id == type.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.poolGreen)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showTypePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func selectedTypeIcon(_ type: CompanyServiceStopType) -> some View {
        Image(systemName: type.imageName ?? "mappin.and.ellipse")
            .frame(width: 28)
            .foregroundStyle(.secondary)
    }

    private func typeSubtitle(_ type: CompanyServiceStopType) -> String {
        type.resolvedCategory(fallback: useCase.category).title
    }

    private func selectedTypePreview(_ type: CompanyServiceStopType) -> some View {
        HStack(spacing: 10) {
            Image(systemName: type.imageName ?? "mappin.and.ellipse")
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(type.name)
                    .font(.subheadline.weight(.semibold))

                Text(typeSubtitle(type))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
