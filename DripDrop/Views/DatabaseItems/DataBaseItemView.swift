//
//  DataBaseItemView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/20/23.
//


import SwiftUI
import Combine

struct DataBaseItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject private var viewModel : ReceiptDatabaseViewModel
    @State var dataBaseItem: DataBaseItem
    
    init(dataService: any ProductionDataServiceProtocol,dataBaseItem:DataBaseItem){
        _viewModel = StateObject(wrappedValue: ReceiptDatabaseViewModel(dataService: dataService))
        _dataBaseItem = State(wrappedValue: dataBaseItem)
    }
    
    @State var name = ""
    @State var rate = ""
    @State var storeName = ""
    @State var storeId = ""
    @State var category = ""
    @State var description = ""
    @State var dateUpdated = Date()
    
    @State var sku = ""
    @State var billable:Bool = false
    @State var color = ""
    @State var size = ""
    
    @State var showEdit:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView(showsIndicators: false){
                VStack(spacing: 14){
                    headerCard
                    pricingCard
                    detailsCard
                    descriptionCard

                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Vendor Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button {
                    showEdit.toggle()
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEdit, content: {
            EditDataBaseItemView(dataService: dataService, dataBaseItem: dataBaseItem)
        })
    }
}

extension DataBaseItemView {
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(priceTint)
                    .frame(width: 56, height: 56)
                    .background(priceTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(dataBaseItem.name.isEmpty ? "Unnamed Item" : dataBaseItem.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("\(dataBaseItem.category.rawValue) • \(dataBaseItem.subCategory.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if !dataBaseItem.sku.isEmpty {
                        Label("SKU \(dataBaseItem.sku)", systemImage: "barcode")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
        }
        .databaseDetailCard(material: true)
    }

    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Pricing",
                subtitle: "Customer price comes from sellPrice. Cost comes from rate.",
                systemImage: "dollarsign.circle"
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 10
            ) {
                pricingTile(
                    title: "Price",
                    value: DataBaseItemMoneyFormatter.customerPriceText(for: dataBaseItem),
                    tint: priceTint
                )

                pricingTile(
                    title: "Cost",
                    value: DataBaseItemMoneyFormatter.costText(for: dataBaseItem),
                    tint: .secondary
                )
            }
        }
        .databaseDetailCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Details",
                subtitle: "Inventory and billing context.",
                systemImage: "info.circle"
            )

            VStack(spacing: 8) {
                detailRow(title: "Store", value: dataBaseItem.storeName.isEmpty ? "Unknown" : dataBaseItem.storeName, systemImage: "storefront")
                detailRow(title: "Unit", value: dataBaseItem.UOM.rawValue, systemImage: "ruler")
                detailRow(title: "Size", value: dataBaseItem.size.isEmpty ? "Not set" : dataBaseItem.size, systemImage: "shippingbox")
                detailRow(title: "Color", value: dataBaseItem.color.isEmpty ? "Not set" : dataBaseItem.color, systemImage: "paintpalette")
                detailRow(title: "Billable", value: dataBaseItem.billable ? "Yes" : "No", systemImage: dataBaseItem.billable ? "checkmark.seal" : "xmark.seal")
                detailRow(title: "Updated", value: fullDate(date: dataBaseItem.dateUpdated), systemImage: "calendar")

                if let tracking = dataBaseItem.tracking,
                   !tracking.isEmpty {
                    detailRow(title: "Tracking", value: tracking, systemImage: "link")
                }
            }
        }
        .databaseDetailCard()
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Description",
                subtitle: "Notes technicians may need when selecting the item.",
                systemImage: "note.text"
            )

            Text(dataBaseItem.description.isEmpty ? "No description added." : dataBaseItem.description)
                .font(.subheadline)
                .foregroundStyle(dataBaseItem.description.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .databaseDetailCard()
    }

    private func sectionHeader(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    private func pricingTile(
        title: String,
        value: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func detailRow(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var priceTint: Color {
        DataBaseItemMoneyFormatter.hasCustomerPrice(dataBaseItem) ? .green : .orange
    }

    private var iconName: String {
        switch dataBaseItem.category {
        case .chems:
            return "drop"
        case .equipment:
            return "wrench.and.screwdriver"
        case .tools:
            return "hammer"
        default:
            return "shippingbox"
        }
    }
}

private extension View {
    func databaseDetailCard(material: Bool = false) -> some View {
        self
            .padding(16)
            .background(
                material ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            }
    }
}
