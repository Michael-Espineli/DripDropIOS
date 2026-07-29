//
//  AddNewDatabaseItem.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/21/23.
//

import SwiftUI

struct AddNewDatabaseItem: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    init(dataService: any ProductionDataServiceProtocol){
        _viewModel = StateObject(wrappedValue: ReceiptDatabaseViewModel(dataService: dataService))
    }
    @StateObject private var viewModel : ReceiptDatabaseViewModel
    @StateObject private var storeViewModel = StoreViewModel()

    @State var store:Vender = Vender(id: "",address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0))

    @State var name:String = ""
    @State var rate:String = ""
    @State var sellPrice:String = ""
    @State var storeId:String = ""
    @State var storeName:String = ""
    @State var category:DataBaseItemCategory = .misc
    @State var subCategory:DataBaseItemSubCategory = .misc
    @State var description:String = ""
    @State var dateUpdated:Date = Date()
    @State var billable:Bool = true
    @State var sku:String = ""
    @State var size:String = ""
    @State var UOM:UnitOfMeasurment = .unit
    @State var color:String = ""

    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    basicsCard
                    pricingCard
                    classificationCard
                    storeCard
                    detailsCard
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Add Database Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isSubmitting ? "Saving..." : "Save") {
                    submit()
                }
                .disabled(!canSubmit)
            }
        }
        .alert("Database Item", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: rate) { newValue in
            rate = sanitizedDecimalInput(newValue)
        }
        .onChange(of: sellPrice) { newValue in
            sellPrice = sanitizedDecimalInput(newValue)
        }
        .onChange(of: billable) { isBillable in
            if !isBillable {
                sellPrice = ""
            }
        }
        .task{
            await loadStores()
        }
    }
}

extension AddNewDatabaseItem {
    private var headerCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "shippingbox.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 54, height: 54)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Database Item")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var basicsCard: some View {
        formCard(title: "Basics", systemImage: "tag") {
            databaseTextField(title: "Name", placeholder: "Item name", text: $name, systemImage: "textformat")
            databaseTextField(title: "SKU", placeholder: "Part number", text: $sku, systemImage: "barcode")
        }
    }

    private var pricingCard: some View {
        formCard(title: "Pricing", systemImage: "dollarsign.circle") {
            moneyField(title: "Cost", placeholder: "0.00", text: $rate, systemImage: "cart")

            Toggle(isOn: $billable) {
                Label(billable ? "Billable" : "Not Billable", systemImage: billable ? "checkmark.seal.fill" : "nosign")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(.green)
            .padding(12)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if billable {
                moneyField(title: "Price", placeholder: "0.00", text: $sellPrice, systemImage: "tag.circle")
            }
        }
    }

    private var classificationCard: some View {
        formCard(title: "Classification", systemImage: "square.grid.2x2") {
            pickerField(title: "Category", systemImage: "folder") {
                Picker("Category", selection: $category) {
                    ForEach(DataBaseItemCategory.allCases.filter { $0 != .na }, id:\.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
            }

            pickerField(title: "Subcategory", systemImage: "tray") {
                Picker("Subcategory", selection: $subCategory) {
                    ForEach(DataBaseItemSubCategory.allCases.filter { $0 != .na }, id:\.self) { subCategory in
                        Text(subCategory.rawValue).tag(subCategory)
                    }
                }
            }

            pickerField(title: "Unit", systemImage: "ruler") {
                Picker("Unit", selection: $UOM) {
                    ForEach(UnitOfMeasurment.allCases.filter { $0 != .na }, id:\.self) { UOM in
                        Text(UOM.rawValue).tag(UOM)
                    }
                }
            }

            databaseTextField(title: "Size", placeholder: "Size", text: $size, systemImage: "arrow.left.and.right")
            databaseTextField(title: "Color", placeholder: "Color", text: $color, systemImage: "paintpalette")
        }
    }

    private var storeCard: some View {
        formCard(title: "Store", systemImage: "storefront") {
            pickerField(title: "Vendor", systemImage: "building.2") {
                Picker("Store", selection: $store) {
                    Text("No store selected").tag(Vender(id: "",address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0)))
                    ForEach(storeViewModel.stores) { store in
                        Text(store.name ?? "Unnamed Store").tag(store)
                    }
                }
            }
        }
    }

    private var detailsCard: some View {
        formCard(title: "Details", systemImage: "text.alignleft") {
            VStack(alignment: .leading, spacing: 7) {
                Label("Description", systemImage: "note.text")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

extension AddNewDatabaseItem {
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    private func formCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            content()
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private func databaseTextField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: text)
                .padding(12)
                .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func moneyField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text("$")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(placeholder, text: text)
                    .keyboardType(.decimalPad)
            }
            .padding(12)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func pickerField<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            content()
                .font(.subheadline.weight(.semibold))
                .pickerStyle(.menu)
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func loadStores() async {
        guard let company = masterDataManager.currentCompany else { return }

        do {
            try await storeViewModel.getAllStores(companyId:company.id)
            if let firstStore = storeViewModel.stores.first {
                store = firstStore
            }
        } catch {
            print(error)
        }
    }

    private func submit() {
        guard canSubmit else { return }

        Task{
            isSubmitting = true
            defer { isSubmitting = false }

            guard let company = masterDataManager.currentCompany else {
                alertMessage = "Select a company before adding an item."
                showAlert = true
                return
            }

            do {
                let pushSellPrice: Double? = billable && !sellPrice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? DataBaseItemMoneyFormatter.centsFromDollarInput(sellPrice)
                    : nil

                try await viewModel.addDataBaseItem(companyId: company.id,dataBaseItem:DataBaseItem(id: UUID().uuidString,
                                                                                                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                                                                                    rate: DataBaseItemMoneyFormatter.centsFromDollarInput(rate),
                                                                                                    storeName: store.name ?? "Unknown",
                                                                                                    venderId: store.id,
                                                                                                    category: category,
                                                                                                    subCategory: subCategory,
                                                                                                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                                                                                                    dateUpdated: dateUpdated,
                                                                                                    sku: sku.trimmingCharacters(in: .whitespacesAndNewlines),
                                                                                                    billable: billable,
                                                                                                    color: color.trimmingCharacters(in: .whitespacesAndNewlines),
                                                                                                    size: size.trimmingCharacters(in: .whitespacesAndNewlines),
                                                                                                    UOM: UOM,
                                                                                                    sellPrice: pushSellPrice))

                resetForm()
                dismiss()
            } catch {
                alertMessage = "Unable to add this database item."
                showAlert = true
                print(error)
            }
        }
    }

    private func resetForm() {
        name = ""
        rate = ""
        sellPrice = ""
        storeId = ""
        storeName = ""
        category = .misc
        subCategory = .misc
        UOM = .unit
        description = ""
        dateUpdated = Date()
        billable = true
        sku = ""
        size = ""
        color = ""

        if let firstStore = storeViewModel.stores.first {
            store = firstStore
        }
    }

    private func sanitizedDecimalInput(_ value: String) -> String {
        var hasDecimal = false
        var output = ""

        for character in value {
            if character.isNumber {
                output.append(character)
            } else if character == "." && !hasDecimal {
                output.append(character)
                hasDecimal = true
            }
        }

        return output
    }
}
