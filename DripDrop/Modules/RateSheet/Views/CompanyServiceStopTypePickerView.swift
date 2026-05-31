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

    let useCase: ServiceStopTypeUseCase
    let title: String
    let subtitle: String

    init(
        companyId: String,
        dataService: any ProductionDataServiceProtocol,
        selectedType: Binding<CompanyServiceStopType?>,
        useCase: ServiceStopTypeUseCase,
        title: String = "Service Stop Type",
        subtitle: String = "Choose what kind of stop this is. Payroll will use this to create the correct pay lines."
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
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                Text("Could not load service stop types: \(errorMessage)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if viewModel.activeServiceStopTypes.isEmpty && !viewModel.isLoading {
                fallbackCard
            } else {
                Picker("Type", selection: selectedTypeIdBinding) {
                    ForEach(viewModel.activeServiceStopTypes) { type in
                        Label(
                            type.name,
                            systemImage: type.imageName ?? "mappin.and.ellipse"
                        )
                        .tag(type.id)
                    }
                }
                .pickerStyle(.menu)

                if let selectedType {
                    selectedTypePreview(selectedType)
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()

            if selectedType == nil {
                selectedType = viewModel.suggestedType(useCase: useCase)
            }
        }
    }

    private var selectedTypeIdBinding: Binding<String> {
        Binding(
            get: {
                selectedType?.id ?? viewModel.activeServiceStopTypes.first?.id ?? ""
            },
            set: { newId in
                selectedType = viewModel.type(id: newId)
            }
        )
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

                Text("Fallback type. Add Company Service Stop Types later for more control.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func selectedTypePreview(_ type: CompanyServiceStopType) -> some View {
        HStack(spacing: 10) {
            Image(systemName: type.imageName ?? "mappin.and.ellipse")
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(type.name)
                    .font(.subheadline.weight(.semibold))

                if type.defaultWorkTypeIds.isEmpty {
                    Text("No default work types assigned.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("\(type.defaultWorkTypeIds.count) default payroll work type(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
