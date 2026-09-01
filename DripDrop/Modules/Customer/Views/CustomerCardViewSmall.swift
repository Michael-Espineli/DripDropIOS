//
//  CustomerCardViewSmall.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//

import SwiftUI
struct CustomerCardViewSmall: View{
    @EnvironmentObject var naviagionManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService


    let customer:Customer
    @State private var unresolvedCustomerNoteCount: Int = 0

    func checkPercentageFilledOut(customer:Customer) ->(filledOut:Bool,percentage:Double){
        //DEVELOPER Please Change this Name
        //Variables To Return
        var filledOut:Bool = false
        var percentage:Double = 0.5
        //Working Variables
        var sum:Double = 0
        var total:Double = 0
        if customer.firstName != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.lastName != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.email != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.phoneNumber ?? "" != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.billingAddress.city != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.billingAddress.state != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.billingAddress.streetAddress != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.billingAddress.zip != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if sum == total {
            filledOut = true
        }
        percentage = total == 0 ? 0 : sum / total
        return (filledOut:filledOut,percentage:percentage)
    }
    var body: some View{
        Group {
            if UIDevice.isIPhone {
                mobileCustomerCard
            } else {
                legacyCustomerCard
                    .modifier(ListButtonModifier())
            }
        }
        .task(id: customer.id) {
            await loadUnresolvedCustomerNoteCount()
        }
    }

    private var mobileCustomerCard: some View {
        let profileStatus = checkPercentageFilledOut(customer: customer)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 11) {
                Text(customerInitials)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 38, height: 38)
                    .background(Color.poolBlue.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(customerDisplayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(customerSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        customerChip(
                            title: customer.active ? "Active" : "Inactive",
                            systemImage: customer.active ? "checkmark.circle.fill" : "pause.circle.fill",
                            tint: customer.active ? .poolGreen : Color.secondary
                        )

                        if customer.phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                            customerChip(
                                title: "Phone",
                                systemImage: "phone.fill",
                                tint: .poolBlue
                            )
                        }

                        if !customer.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            customerChip(
                                title: "Email",
                                systemImage: "envelope.fill",
                                tint: .orange
                            )
                        }
                    }

                    if unresolvedCustomerNoteCount > 0 {
                        unresolvedCustomerNotesBadge
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondary.opacity(0.55))
                    .padding(.top, 5)
            }

            if !profileStatus.filledOut {
                ProgressView(value: profileStatus.percentage)
                    .tint(Color.orange)
                    .progressViewStyle(.linear)
                    .accessibilityLabel("Customer profile completion")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        }
    }

    private var unresolvedCustomerNotesBadge: some View {
        Label(
            "\(unresolvedCustomerNoteCount) unresolved \(unresolvedCustomerNoteCount == 1 ? "comment" : "comments")",
            systemImage: "text.bubble.fill"
        )
        .font(.caption2.weight(.semibold))
        .foregroundStyle(Color.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.12), in: Capsule())
        .accessibilityLabel("\(unresolvedCustomerNoteCount) unresolved customer comments")
    }

    @MainActor
    private func loadUnresolvedCustomerNoteCount() async {
        guard let companyId = masterDataManager.currentCompany?.id else {
            unresolvedCustomerNoteCount = 0
            return
        }

        do {
            let notes = try await dataService.getCustomerNotes(
                companyId: companyId,
                customerId: customer.id,
                visibleFromFieldOnly: false,
                limit: 50
            )

            unresolvedCustomerNoteCount = notes.filter { !($0.resolved ?? false) }.count
        } catch {
            print("[CustomerCardViewSmall][loadUnresolvedCustomerNoteCount] \(error)")
            unresolvedCustomerNoteCount = 0
        }
    }

    @ViewBuilder
    private var legacyCustomerCard: some View {
        ZStack{
            switch masterDataManager.mainScreenDisplayType {
            case .compactList:
                VStack{
                    HStack{
                        VStack{
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 25, height: 25)
                        }
                        VStack{
                            if customer.displayAsCompany {
                                HStack{
                                    Text(customer.company ?? "No Company Name" )
                                }
                            } else {
                                HStack{
                                    Text(customer.firstName )
                                    Text(customer.lastName )
                                }
                            }
                        }
                        Spacer()
                    }
                    if unresolvedCustomerNoteCount > 0 {
                        unresolvedCustomerNotesBadge
                    }
                }
            case .preview:
                VStack{
                    HStack{
                        VStack{
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 30, height: 30)
                        }
                        VStack{
                            if customer.displayAsCompany {
                                HStack{
                                    Text(customer.company ?? "No Company Name" )
                                }
                            } else {
                                HStack{
                                    Text(customer.firstName )
                                    Text(customer.lastName )
                                }
                            }
                        }
                        Spacer()
                    }
                    if !checkPercentageFilledOut(customer: customer).filledOut {
                        ProgressView(value: checkPercentageFilledOut(customer: customer).percentage)
                            .tint(Color.red)
                    }
                    if unresolvedCustomerNoteCount > 0 {
                        unresolvedCustomerNotesBadge
                    }
                }
            case .fullPreview:
                VStack{
                    HStack{
                        VStack{
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
                        VStack{
                            if customer.displayAsCompany {
                                HStack{
                                    Text(customer.company ?? "No Company Name" )
                                }
                            } else {
                                HStack{
                                    Text(customer.firstName )
                                    Text(customer.lastName )
                                }
                            }
                            HStack{
                                Text(customer.billingAddress.streetAddress)
                                    .font(.footnote)
                            }
                        }
                        Spacer()
                    }
                    if !checkPercentageFilledOut(customer: customer).filledOut {
                        ProgressView(value: checkPercentageFilledOut(customer: customer).percentage)
                            .tint(Color.red)
                    }
                    if unresolvedCustomerNoteCount > 0 {
                        unresolvedCustomerNotesBadge
                    }
                }
            }
            
        }
    }

    private var customerDisplayName: String {
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

        if !customer.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customer.email
        }

        return "Unnamed Customer"
    }

    private var customerInitials: String {
        let initials = customerDisplayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()

        return initials.isEmpty ? "?" : initials
    }

    private var customerSubtitle: String {
        if !customerAddressLine.isEmpty {
            return customerAddressLine
        }

        if let phone = customer.phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines), !phone.isEmpty {
            return phone
        }

        if !customer.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customer.email
        }

        return "No contact details"
    }

    private var customerAddressLine: String {
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

    private func customerChip(
        title: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10), in: Capsule())
    }
}
