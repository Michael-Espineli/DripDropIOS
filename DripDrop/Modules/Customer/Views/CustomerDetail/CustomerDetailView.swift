//
//  CustomerDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//

enum customerDetailViewEnum: Int, CaseIterable, Identifiable {
    var id: Int { rawValue }
    case profile
    case location
    case upcomingWork
    case notes
    case serviceHistory
}

extension customerDetailViewEnum {
    
    var title: String {
        switch self {
        case .profile:
            return "Profile"
        case .location:
            return "Location"
        case .upcomingWork:
            return "Operation"
        case .notes:
            return "Notes"
        case .serviceHistory:
            return "History"
        }
    }
    
    var systemImage: String {
        switch self {
        case .profile:
            return "person.circle.fill"
        case .location:
            return "house.fill"
        case .upcomingWork:
            return "wrench.adjustable.fill"
        case .notes:
            return "text.bubble.fill"
        case .serviceHistory:
            return "doc.text"
        }
    }
    var color: Color {
        switch self {
        case .profile:
            return Color.red
        case .location:
            return Color.blue
        case .upcomingWork:
            return Color.purple
        case .notes:
            return Color.orange
        case .serviceHistory:
            return Color.brown
        }
    }
}

import SwiftUI

struct CustomerDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var VM : CustomerListViewModel
    @EnvironmentObject var customerProfileVM: CustomerProfileViewModel
    private var customer: Customer? {
        VM.customers.first { $0.id == customerId }
    }
    let customerId: String
    @State var selectedCustomer:Customer? = nil
    @State var isLoading:Bool = false
    @State var showEditView:Bool = false
    @State var viewType:customerDetailViewEnum = .location
    

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView(showsIndicators: false){
                if let customer{
                    VStack(spacing: 12) {
                        customerSummaryHeader(customer)

                        LazyVStack(alignment: .center,
                                   pinnedViews: [.sectionHeaders],
                                   content: {
                            Section(content: {
                                VStack{
                                    selectedCustomerDetailContent(customer)
                                }
                                .padding(.horizontal,14)
                            },
                            header: {
                                sectionTitles
                            })
                        })

                        Color.clear.frame(height: 90)
                    }
                    .padding(.top, 14)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 48, height: 48)
                            .background(.thinMaterial, in: Circle())

                        Text("No Customer")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("The selected customer could not be loaded.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(14)
                }
            }
            .clipped()

        }
        .navigationTitle(customer.map { customerDisplayName($0) } ?? "Customer")
        .font(.system(.body , design: .rounded))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: customerId) {
            if let company = masterDataManager.currentCompany {
                customerProfileVM.startUpcomingWorkListeners(
                    companyId: company.id,
                    customerId: customerId
                )
            }
        }
//        .navigationBarBackground()
//        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension CustomerDetailView {
    @ViewBuilder
    private func selectedCustomerDetailContent(_ customer: Customer) -> some View {
        switch viewType{
        case .profile:
            CustomerProfileView(
                customerId: customerId
            )
        case .location:
            CustomerLocationView(
                dataService: dataService,
                customerId: customerId
            )
        case .upcomingWork:
            CustomerUpcomingWork(
                dataService: dataService,
                customerId: customerId
            )
        case .notes:
            CustomerUpcomingWork(
                dataService: dataService,
                customerId: customerId,
                mode: .notes
            )
        case .serviceHistory:
            VStack(spacing: 12) {
                CustomerTimelineView(
                    dataService: dataService,
                    customer: customer
                )

                CustomerStopDataDetailView(
                    dataService: dataService,
                    customerId: customerId
                )
                            }
                //Developer Figure out whats better
                //                                CustomerServiceHistoryView(
                //                                    dataService: dataService,
                //                                    customer: customer
                //                                )
        }
    }

    private func customerSummaryHeader(_ customer: Customer) -> some View {
        HStack(alignment: .center, spacing: 10) {
                Text(customerInitials(customer))
                .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.poolBlue)
                .frame(width: 36, height: 36)
                    .background(Color.poolBlue.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                    Text(customerDisplayName(customer))
                    .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(customerSubtitle(customer))
                    .font(.caption2)
                        .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    compactCustomerChip(
                        title: customer.active ? "Active" : "Inactive",
                        systemImage: customer.active ? "checkmark.circle.fill" : "pause.circle.fill",
                        tint: customer.active ? .poolGreen : Color.secondary
                    )

                    if hasPhone(customer) {
                        compactCustomerChip(title: "Phone", systemImage: "phone.fill", tint: .poolBlue)
                    }

                    if hasEmail(customer) {
                        compactCustomerChip(title: "Email", systemImage: "envelope.fill", tint: .orange)
                    }
                }
            }

                Spacer()

            Image(systemName: "person.crop.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.thinMaterial, in: Circle())
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
    }

    var sectionTitles:some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(customerDetailViewEnum.allCases) { screen in
                    customerDetailTabButton(screen)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
        }
        .background(.regularMaterial)

        /*
        VStack{
            ScrollView(.vertical, showsIndicators: false){
                HStack(spacing: 0){
                    
                    Button(action: {
                        viewType = .profile
                    }, label: {
                        if viewType == .profile {
                            Image(systemName: "person.circle")
                                .modifier(BlueButtonModifier())
                        } else {
                            Image(systemName: "person.circle")
                                .modifier(ListButtonModifier())
                        }
                    })
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack{
                            ForEach(customerDetailViewEnum.allCases){ screen in
                                if screen != .profile {
                                    if screen != viewType {
                                        Button(action: {
                                            viewType = screen
                                        }, label: {
                                            HStack{
                                                Text(screen.title)
                                            }
                                            .modifier(ListButtonModifier())
                                        })
                                    } else {
                                        Button(action: {
                                            viewType = screen
                                        }, label: {
                                            HStack{
                                                Text(screen.title)
                                            }
                                            .modifier(BlueButtonModifier())
                                        })
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 0))
                    }
                    .padding(.leading,8)
                    .overlay(
                        HStack{
                            LinearGradient(colors: [
                                Color.listColor,
                                Color.listColor.opacity(0.5),
                                Color.clear
                            ],
                                           startPoint: .leading,
                                           endPoint: .trailing)
                            .frame(width: 20)
                            Spacer()
                        }
                    )
                }
            }
            Rectangle()
                .frame(height: 1)
        }
         */
    }

    private func customerDetailTabButton(_ screen: customerDetailViewEnum) -> some View {
        let isSelected = viewType == screen

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                viewType = screen
            }
        } label: {
            HStack(spacing: 7) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: screen.systemImage)
                        .font(.caption.weight(.semibold))

                    if screen == .notes && unresolvedCustomerNotesCount > 0 {
                        Text(unresolvedCustomerNotesCount > 9 ? "9+" : "\(unresolvedCustomerNotesCount)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.poolRed, in: Capsule())
                            .offset(x: 8, y: -8)
                    }
                }

                Text(screen.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var unresolvedCustomerNotesCount: Int {
        customerProfileVM.customerNotes.filter { !($0.resolved ?? false) }.count
    }

    private func compactCustomerChip(
        title: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(tint.opacity(0.10), in: Capsule())
    }

    private func customerDisplayName(_ customer: Customer) -> String {
        if customer.displayAsCompany,
           let company = customer.company?.trimmingCharacters(in: .whitespacesAndNewlines),
           !company.isEmpty {
            return company
        }

        let name = [customer.firstName, customer.lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if !name.isEmpty {
            return name
        }

        if hasEmail(customer) {
            return customer.email
        }

        return "Unnamed Customer"
    }

    private func customerInitials(_ customer: Customer) -> String {
        let initials = customerDisplayName(customer)
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()

        return initials.isEmpty ? "?" : initials
    }

    private func customerSubtitle(_ customer: Customer) -> String {
        let address = customerAddressLine(customer)

        if !address.isEmpty {
            return address
        }

        if let phone = customer.phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines), !phone.isEmpty {
            return phone
        }

        if hasEmail(customer) {
            return customer.email
        }

        return "No contact details"
    }

    private func customerAddressLine(_ customer: Customer) -> String {
        let street = customer.billingAddress.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = customer.billingAddress.city.trimmingCharacters(in: .whitespacesAndNewlines)
        let state = customer.billingAddress.state.trimmingCharacters(in: .whitespacesAndNewlines)
        let zip = customer.billingAddress.zip.trimmingCharacters(in: .whitespacesAndNewlines)
        let cityStateZip = [city, state, zip]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return [street, cityStateZip]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private func hasPhone(_ customer: Customer) -> Bool {
        customer.phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private func hasEmail(_ customer: Customer) -> Bool {
        !customer.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var viewController: some View {
        Picker("", selection: $viewType) {
            ForEach(customerDetailViewEnum.allCases){
                Text($0.title).tag($0)
            }
        }
        .pickerStyle(.segmented)
        .padding(5)
        .background(Color.white)
        .cornerRadius(5)
        .shadow(color: Color.basicFontText, radius: 5)
    }
    var viewController2: some View {
        HStack{
            Spacer()
            ForEach(customerDetailViewEnum.allCases) { category in
                VStack{
                    Button(action: {
                        viewType = category
                    }, label: {
                        Image(systemName: category.systemImage)
                            .font(viewType == category ? .largeTitle : .title)
                            .foregroundColor(viewType == category ? Color.poolGreen : Color.basicFontText)
                            .padding(5)
                    })
                    Text(category.title)
                        .underline(viewType == category,color: Color.accentColor)
                }
                Spacer()
            }
        }
        .padding(5)
        .background(Color.poolBlue)
    }
}
