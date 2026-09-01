//
//  DataBaseItemPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/26/25.
//
@MainActor
final class DataBaseItemPickerViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published var dataBaseItems: [DataBaseItem] = []
    @Published var filteredDataBaseItems: [DataBaseItem] = []
    @Published var searchTerm: String = ""
    
    func onLoad(companyId:String) async throws {
        self.filteredDataBaseItems = try await dataService.getAllDataBaseItems(companyId: companyId)
        self.dataBaseItems = filteredDataBaseItems
    }
    func searchFunction() {
        if searchTerm != "" {
            var filteredItems:[DataBaseItem] = []
            for item in dataBaseItems {
                if item.name.lowercased().contains(searchTerm.lowercased()) || item.sku.lowercased().contains(searchTerm.lowercased()) || item.description.lowercased().contains(searchTerm.lowercased()) || item.color.lowercased().contains(searchTerm.lowercased()) || item.category.rawValue.lowercased().contains(searchTerm.lowercased()) {
                    filteredItems.append(item)
                }
            }
            self.filteredDataBaseItems = filteredItems
        } else {
            self.filteredDataBaseItems = dataBaseItems
        }
    }
}
import SwiftUI

struct DataBaseItemPicker: View {
    init(
        dataService:any ProductionDataServiceProtocol,
        DBItem:Binding<DataBaseItem>,
        category:DataBaseItemCategory
    ){
        _VM = StateObject(wrappedValue: DataBaseItemPickerViewModel(dataService: dataService))
        self._DBItem = DBItem
        _category = State(wrappedValue: category)
    }
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var VM : DataBaseItemPickerViewModel
    @State var category : DataBaseItemCategory
    @Binding var DBItem : DataBaseItem
    
    @State var showAddNew : Bool = false

        var body: some View {
        VStack{
            dataBaseList
            searchBar
        }
        .padding()
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.onLoad(companyId: company.id)
                }
            } catch {
                print("Error")
                print(error)
            }
        }
        .onChange(of: VM.searchTerm, perform: { term in
            VM.searchFunction()
        })
    }
}
extension DataBaseItemPicker {
    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(
                "Search vendor items",
                text: $VM.searchTerm
            )
            .textFieldStyle(.plain)

            if !VM.searchTerm.isEmpty {
                Button {
                    VM.searchTerm = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .modifier(SearchTextFieldModifier())
        .padding(.horizontal, 8)
    }
    var dataBaseList: some View {
        ScrollView{
            ForEach(VM.filteredDataBaseItems){ datum in
                Button(action: {
                    DBItem = datum
                    dismiss()
                }, label: {
                    HStack{
                        Spacer()
                        Text("\(datum.name)")
                        Spacer()
                    }
                })
                .modifier(ListButtonModifier())
            }
            Button(action: {
                showAddNew.toggle()
            }, label: {
                HStack{
                    Spacer()
                    Text("Add New Item")
                    Spacer()
                }
                .modifier(BlueButtonModifier())
            })
            .sheet(isPresented: $showAddNew, onDismiss: {
                
            }, content: {
                AddNewDatabaseItem(dataService: dataService)
            })
        }
    }
}

@MainActor
final class ProductCatalogPickerViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published var products: [GenericItem] = []
    @Published var filteredProducts: [GenericItem] = []
    @Published var searchTerm: String = ""

    func onLoad(companyId: String, onlyPartPurchaseAvailable: Bool) async throws {
        let loadedProducts = try await dataService.getAllGenericDataBaseItems(companyId: companyId)
            .filter { product in
                guard onlyPartPurchaseAvailable else { return product.active != false }
                return product.isAvailableForPartPurchase
            }
            .sorted {
                $0.productDisplayName.localizedCaseInsensitiveCompare($1.productDisplayName) == .orderedAscending
            }

        products = loadedProducts
        filteredProducts = loadedProducts
    }

    func searchFunction() {
        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !term.isEmpty else {
            filteredProducts = products
            return
        }

        filteredProducts = products.filter { product in
            product.productSearchText.contains(term)
        }
    }
}

struct ProductCatalogPicker: View {
    init(
        dataService: any ProductionDataServiceProtocol,
        product: Binding<GenericItem>,
        onlyPartPurchaseAvailable: Bool = false
    ) {
        _VM = StateObject(wrappedValue: ProductCatalogPickerViewModel(dataService: dataService))
        self._product = product
        _onlyPartPurchaseAvailable = State(wrappedValue: onlyPartPurchaseAvailable)
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject var VM: ProductCatalogPickerViewModel
    @State var onlyPartPurchaseAvailable: Bool
    @Binding var product: GenericItem
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                productSearchBar

                if let loadError {
                    Text(loadError)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.poolRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                productList
            }
            .padding()
            .background(Color.listColor.ignoresSafeArea())
            .navigationTitle("Product Catalog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadProducts()
            }
            .onChange(of: VM.searchTerm) { _ in
                VM.searchFunction()
            }
        }
    }

    private var productSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search products", text: $VM.searchTerm)
                .textFieldStyle(.plain)

            if !VM.searchTerm.isEmpty {
                Button {
                    VM.searchTerm = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .modifier(SearchTextFieldModifier())
    }

    private var productList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if VM.filteredProducts.isEmpty {
                    Text(VM.products.isEmpty ? "No products found." : "No products match this search.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                }

                ForEach(VM.filteredProducts) { item in
                    Button {
                        product = item
                        dismiss()
                    } label: {
                        productRow(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func productRow(_ item: GenericItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 34, height: 34)
                .background(Color.poolBlue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(item.productDisplayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(productSubtitle(item))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
        }
    }

    private func productSubtitle(_ item: GenericItem) -> String {
        var parts: [String] = []

        if item.productSellPriceCents > 0 {
            parts.append(DataBaseItemMoneyFormatter.moneyFromCents(Double(item.productSellPriceCents)))
        }

        if !item.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(item.category)
        }

        if !item.UOM.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(item.UOM)
        }

        return parts.isEmpty ? item.productDescription : parts.joined(separator: " • ")
    }

    private func loadProducts() async {
        guard let company = masterDataManager.currentCompany else {
            loadError = "Missing company."
            return
        }

        do {
            try await VM.onLoad(
                companyId: company.id,
                onlyPartPurchaseAvailable: onlyPartPurchaseAvailable
            )
        } catch {
            loadError = "Could not load products."
            print("[ProductCatalogPicker][loadProducts] \(error)")
        }
    }
}
