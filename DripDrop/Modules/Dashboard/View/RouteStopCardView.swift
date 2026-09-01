//
//  RouteStopCardView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI
import Darwin
import FirebaseFirestore

enum numberPickerType {}

enum PhoneNumberPickerType: Identifiable {
    case message, call, inApp
    var id: Int { hashValue }
}

struct RouteTextMessageTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let body: String
    let sortOrder: Int
    let active: Bool

    static let defaultTemplates: [RouteTextMessageTemplate] = [
        RouteTextMessageTemplate(
            id: "pre_arrival",
            name: "On My Way",
            description: "Let the customer know the technician is headed to the property.",
            body: "Hi {{customerFirstName}}, this is {{technicianName}} with {{companyName}}. I am on my way to service your pool at {{serviceAddress}} today.",
            sortOrder: 10,
            active: true
        ),
        RouteTextMessageTemplate(
            id: "arrival_notice",
            name: "Arrived",
            description: "Let the customer know service is beginning.",
            body: "Hi {{customerFirstName}}, this is {{technicianName}} with {{companyName}}. I just arrived and am starting your pool service now.",
            sortOrder: 20,
            active: true
        ),
        RouteTextMessageTemplate(
            id: "running_late",
            name: "Running Late",
            description: "Send a quick schedule update when the route is behind.",
            body: "Hi {{customerFirstName}}, this is {{technicianName}} with {{companyName}}. I am running a little behind today, but your pool service is still on my route.",
            sortOrder: 30,
            active: true
        ),
        RouteTextMessageTemplate(
            id: "access_issue",
            name: "Access Issue",
            description: "Ask the customer for help when the technician cannot access the pool.",
            body: "Hi {{customerFirstName}}, this is {{technicianName}} with {{companyName}}. I am at {{serviceAddress}} and cannot access the pool area. Could you please let me know the best way in?",
            sortOrder: 40,
            active: true
        ),
        RouteTextMessageTemplate(
            id: "service_complete",
            name: "Service Complete",
            description: "Let the customer know the visit is complete.",
            body: "Hi {{customerFirstName}}, this is {{technicianName}} with {{companyName}}. Your pool service at {{serviceAddress}} is complete. Thank you!",
            sortOrder: 50,
            active: true
        )
    ]

    init(
        id: String,
        name: String,
        description: String,
        body: String,
        sortOrder: Int,
        active: Bool
    ) {
        self.id = RouteTextMessageTemplate.clean(id)
        self.name = RouteTextMessageTemplate.clean(name).isEmpty ? "Text Template" : RouteTextMessageTemplate.clean(name)
        self.description = RouteTextMessageTemplate.clean(description)
        self.body = RouteTextMessageTemplate.clean(body)
        self.sortOrder = sortOrder
        self.active = active
    }

    init(documentId: String, data: [String: Any], fallbackIndex: Int) {
        let id = Self.clean(data["id"] as? String).isEmpty
            ? documentId
            : Self.clean(data["id"] as? String)
        let body = Self.firstCleanString([
            data["body"],
            data["content"],
            data["message"]
        ])

        self.init(
            id: id,
            name: Self.firstCleanString([data["name"]]),
            description: Self.firstCleanString([data["description"]]),
            body: body,
            sortOrder: Self.intValue(data["sortOrder"]) ?? ((fallbackIndex + 1) * 10),
            active: Self.boolValue(data["active"]) ?? true
        )
    }

    var renderedFallbackDescription: String {
        description.isEmpty ? body : description
    }

    static func activeMerged(with companyTemplates: [RouteTextMessageTemplate]) -> [RouteTextMessageTemplate] {
        var merged = Dictionary(uniqueKeysWithValues: defaultTemplates.map { ($0.id, $0) })

        for template in companyTemplates where !template.id.isEmpty {
            merged[template.id] = template
        }

        return merged.values
            .filter { $0.active && !$0.body.isEmpty }
            .sorted {
                if $0.sortOrder != $1.sortOrder {
                    return $0.sortOrder < $1.sortOrder
                }

                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private static func clean(_ value: String?) -> String {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstCleanString(_ values: [Any?]) -> String {
        for value in values {
            if let string = value as? String {
                let cleanValue = clean(string)
                if !cleanValue.isEmpty { return cleanValue }
            } else if let value {
                let cleanValue = clean(String(describing: value))
                if !cleanValue.isEmpty { return cleanValue }
            }
        }

        return ""
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let double = value as? Double { return Int(double) }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String {
            return Int(clean(string))
        }

        return nil
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        if let bool = value as? Bool { return bool }
        if let number = value as? NSNumber { return number.boolValue }
        if let string = value as? String {
            switch clean(string).lowercased() {
            case "true", "yes", "1", "active":
                return true
            case "false", "no", "0", "inactive":
                return false
            default:
                return nil
            }
        }

        return nil
    }
}

private struct RouteTextMessageTemplateContext {
    let values: [String: String]

    static func build(
        stop: ServiceStop,
        customer: Customer?,
        serviceLocation: ServiceLocation?,
        company: Company?,
        technicianName: String?
    ) -> RouteTextMessageTemplateContext {
        let customerName = firstNonEmpty([
            customer?.displayAsCompany == true ? customer?.company : nil,
            [customer?.firstName, customer?.lastName]
                .compactMap { clean($0) }
                .filter { !$0.isEmpty }
                .joined(separator: " "),
            stop.customerName
        ])
        let customerFirstName = firstNonEmpty([
            customer?.firstName,
            customerName.components(separatedBy: .whitespacesAndNewlines).first
        ])
        let serviceAddress = [
            firstNonEmpty([stop.address.streetAddress, serviceLocation?.address.streetAddress]),
            firstNonEmpty([stop.address.city, serviceLocation?.address.city]),
            firstNonEmpty([stop.address.state, serviceLocation?.address.state]),
            firstNonEmpty([stop.address.zip, serviceLocation?.address.zip])
        ]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        return RouteTextMessageTemplateContext(values: [
            "customerName": customerName,
            "customerFirstName": customerFirstName.isEmpty ? customerName : customerFirstName,
            "technicianName": firstNonEmpty([technicianName, stop.tech]),
            "companyName": firstNonEmpty([company?.name, stop.companyName]),
            "serviceDate": routeTextServiceDateFormatter.string(from: stop.serviceDate),
            "serviceTime": routeTextServiceTimeFormatter.string(from: stop.startTime ?? stop.serviceDate),
            "serviceAddress": serviceAddress,
            "poolName": firstNonEmpty([serviceLocation?.nickName]),
            "serviceLocationName": firstNonEmpty([serviceLocation?.nickName]),
            "stopType": stop.type
        ])
    }

    private static func clean(_ value: String?) -> String {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstNonEmpty(_ values: [String?]) -> String {
        values
            .map { clean($0) }
            .first { !$0.isEmpty } ?? ""
    }
}

@MainActor
private enum RouteTextMessageTemplateStore {
    private static var cache: [String: [RouteTextMessageTemplate]] = [:]

    static func templates(companyId: String) async -> [RouteTextMessageTemplate] {
        let cleanCompanyId = companyId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanCompanyId.isEmpty else {
            return RouteTextMessageTemplate.defaultTemplates
        }

        if let cachedTemplates = cache[cleanCompanyId] {
            return cachedTemplates
        }

        do {
            let snapshot = try await Firestore.firestore()
                .collection("companies")
                .document(cleanCompanyId)
                .collection("settings")
                .document("textTemplates")
                .collection("templates")
                .order(by: "sortOrder")
                .getDocuments()
            let companyTemplates = snapshot.documents.enumerated().map { index, document in
                RouteTextMessageTemplate(
                    documentId: document.documentID,
                    data: document.data(),
                    fallbackIndex: index
                )
            }
            let templates = RouteTextMessageTemplate.activeMerged(with: companyTemplates)
            cache[cleanCompanyId] = templates
            return templates
        } catch {
            print("[RouteTextMessageTemplateStore][templates] Error loading text templates: \(error)")
            return RouteTextMessageTemplate.defaultTemplates
        }
    }
}

private let routeTextServiceDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter
}()

private let routeTextServiceTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter
}()

private let routeTextTemplateTokenExpression = try? NSRegularExpression(
    pattern: #"\{\{\s*([A-Za-z0-9_]+)\s*\}\}"#
)

private func renderRouteTextTemplate(
    _ template: RouteTextMessageTemplate,
    context: RouteTextMessageTemplateContext
) -> String {
    let body = template.body
    guard let expression = routeTextTemplateTokenExpression else { return body }

    let source = body as NSString
    let matches = expression.matches(
        in: body,
        range: NSRange(location: 0, length: source.length)
    )
    var rendered = body

    for match in matches.reversed() {
        guard match.numberOfRanges > 1,
              let tokenRange = Range(match.range(at: 1), in: body),
              let matchRange = Range(match.range(at: 0), in: rendered)
        else { continue }

        let key = String(body[tokenRange])
        rendered.replaceSubrange(matchRange, with: context.values[key] ?? "")
    }

    return rendered.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func normalizedRouteTextPhoneNumber(_ value: String?) -> String {
    let cleanValue = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanValue.isEmpty else { return "" }

    let hasPlusPrefix = cleanValue.hasPrefix("+")
    let digits = cleanValue.filter { $0.isNumber }
    guard !digits.isEmpty else { return "" }

    return "\(hasPlusPrefix ? "+" : "")\(digits)"
}

private func routeSmsURL(phoneNumber: String, body: String? = nil) -> URL? {
    let phone = normalizedRouteTextPhoneNumber(phoneNumber)
    guard !phone.isEmpty else { return nil }

    var components = URLComponents()
    components.scheme = "sms"
    components.path = phone

    if let body = body?.trimmingCharacters(in: .whitespacesAndNewlines),
       !body.isEmpty {
        components.queryItems = [
            URLQueryItem(name: "body", value: body)
        ]
    }

    return components.url
}

@MainActor
final class RouteStopCardViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published private(set) var customer: Customer? = nil
    @Published private(set) var serviceLocation: ServiceLocation? = nil
    @Published private(set) var weather: Weather? = nil
    @Published private(set) var textTemplates: [RouteTextMessageTemplate] = RouteTextMessageTemplate.defaultTemplates
    @Published private(set) var isLoadingTextTemplates: Bool = false

    func onLoad(companyId: String, serviceStop: ServiceStop) async throws {
        self.customer = try? await dataService.getCustomerById(
            companyId: companyId,
            customerId: serviceStop.customerId
        )
        if !serviceStop.serviceLocationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.serviceLocation = try? await dataService.getServiceLocationById(
                companyId: companyId,
                locationId: serviceStop.serviceLocationId
            )
        } else {
            self.serviceLocation = nil
        }
        self.weather = try? await WeatherManager.shared.fetchWeather(
            address: serviceStop.address
        )
        self.isLoadingTextTemplates = true
        self.textTemplates = await RouteTextMessageTemplateStore.templates(companyId: companyId)
        self.isLoadingTextTemplates = false
    }
}

struct RouteStopCardView: View {

    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: RouteStopCardViewModel
    let stop: ServiceStop
    let index: Int

    init(dataService: any ProductionDataServiceProtocol, stop: ServiceStop, index: Int) {
        _VM = StateObject(wrappedValue: RouteStopCardViewModel(dataService: dataService))
        self.stop = stop
        self.index = index
    }

    @State var customer: Customer? = nil
    @State var showPhoneNumberPicker: Bool = false
    @State var phoneNumberPickerType: PhoneNumberPickerType? = nil
    @State private var showTextTemplatePicker: Bool = false

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            main
        }
//            .background(.thinMaterial)
//            .cornerRadius(16)
        .task {
            if let company = masterDataManager.currentCompany {
                try? await VM.onLoad(companyId: company.id, serviceStop: stop)
            }
        }
        .onChange(of: phoneNumberPickerType) { type in
            guard
                let selectedType = type,
                !routeTextPhoneNumber.isEmpty
            else { return }

            defer {
                phoneNumberPickerType = nil
            }

            switch selectedType {
            case .call:
                if let url = URL(string: "tel://\(normalizedRouteTextPhoneNumber(routeTextPhoneNumber))") {
                    UIApplication.shared.open(url)
                }
            case .message:
                if let url = routeSmsURL(phoneNumber: routeTextPhoneNumber) {
                    UIApplication.shared.open(url)
                }
            case .inApp:
                print("Need to set up internal App Communication")
            }
        }
        .sheet(isPresented: $showTextTemplatePicker) {
            RouteTextTemplatePickerSheet(
                templates: VM.textTemplates,
                isLoadingTemplates: VM.isLoadingTextTemplates,
                customerName: routeTextCustomerName,
                phoneNumber: routeTextPhoneNumber,
                serviceAddress: routeTextServiceAddress,
                draftMessage: { template in
                    renderRouteTextTemplate(
                        template,
                        context: routeTextTemplateContext
                    )
                },
                onOpenTextDraft: { template in
                    openTextDraft(template: template)
                }
            )
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Preview
//struct RouteStopCardView_Previews: PreviewProvider {
//    static let dataService = ProductionDataService()
//
//    static var previews: some View {
//        RouteStopCardView(
//            dataService: dataService,
//            stop: MockDataService().mockServiceStops.first!,
//            index: 1
//        )
//    }
//}

// MARK: - Subviews
extension RouteStopCardView {
    @ViewBuilder
    var main: some View {
        ZStack{
            /*
            switch stop.operationStatus {
            case .finished:
                Rectangle()
                    .padding(.horizontal,6)
                    .padding(.vertical,4)
                    .background(Color.poolGreen)
                    .cornerRadius(16)
                    .foregroundColor(Color.clear)
                    .fontDesign(.monospaced)
                    .opacity(0.5)
                    .onTapGesture {
                        navigationManager.push(to: Route.dailyDisplayStop(
                            dataService: dataService,
                            serviceStop: stop
                        ))
                    }
            case .notFinished:
                Rectangle()
                    .padding(.horizontal,6)
                    .padding(.vertical,4)
                    .background(Color.poolGray)
                    .cornerRadius(16)
                    .foregroundColor(Color.clear)
                    .fontDesign(.monospaced)
                    .opacity(0.5)
                    .onTapGesture {
                        navigationManager.push(to: Route.dailyDisplayStop(
                            dataService: dataService,
                            serviceStop: stop
                        ))
                    }
            case .skipped:
                Rectangle()
                    .padding(.horizontal,6)
                    .padding(.vertical,4)
                    .background(Color.realYellow)
                    .cornerRadius(16)
                    .foregroundColor(Color.clear)
                    .fontDesign(.monospaced)
                    .opacity(0.5)
                    .onTapGesture {
                        navigationManager.push(to: Route.dailyDisplayStop(
                            dataService: dataService,
                            serviceStop: stop
                        ))
                    }
            }
            */
            card()
                .padding()
        }
    }
    private func card() -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(statusAccentColor)
                .frame(width: stop.operationStatus == .notFinished ? 4 : 7)
                .cornerRadius(3)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "\(index + 1).square.fill")
                        .font(.title2)
                        .foregroundColor(statusAccentColor)
                    homeNav
//                            if let weather = VM.weather {
//                                WeatherSnapShotView(weather: weather)
//                            }
                    Spacer()
                    serviceStopNav
                    message
                }
                if stop.otherCompany, stop.contractedCompanyId != "" {
                    CompanyNameCardView(
                        dataService: dataService,
                        companyId: stop.contractedCompanyId
                    )
                    .modifier(OutLineButtonModifier())
                    .padding(.top, 4)
                }
                routeFooter
            }
        }

    }

    private var statusAccentColor: Color {
        switch stop.operationStatus {
        case .finished:
            return .poolGreen
        case .notFinished:
            return .gray
        case .skipped:
            return .orange
        }
    }
    var message: some View {
        Group {
            if !routeTextPhoneNumber.isEmpty {
                Button {
                    showPhoneNumberPicker.toggle()
                } label: {
                    Image(systemName: "message.circle.fill")
                        .font(.title2)
                        .foregroundColor(.basicFontText)
                }
                .confirmationDialog(
                    "Select Type",
                    isPresented: $showPhoneNumberPicker
                ) {
                    Button("In App") { phoneNumberPickerType = .inApp }
                    Button("Text Template") { showTextTemplatePicker = true }
                    Button("Call: \(routeTextPhoneNumber)") { phoneNumberPickerType = .call }
                    Button("Blank Message \(routeTextPhoneNumber)") { phoneNumberPickerType = .message }
                }
            }
        }
    }

    private var routeTextPhoneNumber: String {
        [
            VM.customer?.phoneNumber,
            VM.serviceLocation?.mainContact.phoneNumber
        ]
            .map { ($0 ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }

    private var routeTextCustomerName: String {
        let customerCompanyName = VM.customer?.displayAsCompany == true
            ? VM.customer?.company
            : nil
        let fullName = [
            VM.customer?.firstName,
            VM.customer?.lastName
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return [
            customerCompanyName,
            fullName,
            stop.customerName
        ]
            .map { ($0 ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Customer"
    }

    private var routeTextServiceAddress: String {
        [
            stop.address.streetAddress,
            stop.address.city,
            stop.address.state,
            stop.address.zip
        ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private var routeTextTemplateContext: RouteTextMessageTemplateContext {
        RouteTextMessageTemplateContext.build(
            stop: stop,
            customer: VM.customer,
            serviceLocation: VM.serviceLocation,
            company: masterDataManager.currentCompany,
            technicianName: masterDataManager.companyUser?.userName
        )
    }

    private func openTextDraft(template: RouteTextMessageTemplate) {
#if os(iOS)
        let draft = renderRouteTextTemplate(
            template,
            context: routeTextTemplateContext
        )

        guard let url = routeSmsURL(
            phoneNumber: routeTextPhoneNumber,
            body: draft
        ) else {
            return
        }

        UIApplication.shared.open(url)
#endif
    }

    private var routeFooter: some View {
        HStack(spacing: 10) {
            footerItem(
                systemImage: "clock",
                text: startTimeFooterText
            )

            Rectangle()
                .fill(Color.basicFontText.opacity(0.18))
                .frame(width: 1, height: 10)

            footerItem(
                systemImage: "timer",
                text: durationFooterText
            )

            Spacer(minLength: 0)
        }
        .font(.caption2.weight(.medium))
        .foregroundColor(Color.basicFontText.opacity(0.68))
        .padding(.top, 2)
        .accessibilityElement(children: .combine)
    }

    private func footerItem(systemImage: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.semibold))
                .accessibilityHidden(true)

            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var startTimeFooterText: String {
        guard let startTime = stop.startTime else {
            return "Start not set"
        }

        return "Started \(time(date: startTime))"
    }

    private var durationFooterText: String {
        if stop.duration > 0 {
            return "Duration \(compactMinutes(stop.duration))"
        }

        if let startTime = stop.startTime,
           let endTime = stop.endTime,
           endTime > startTime {
            return "Duration \(compactMinutes(minBetween(start: startTime, end: endTime)))"
        }

        if stop.estimatedDuration > 0 {
            return "Est. \(compactMinutes(stop.estimatedDuration))"
        }

        return "Duration not set"
    }

    private func compactMinutes(_ minutes: Int) -> String {
        let safeMinutes = max(minutes, 0)
        let hours = safeMinutes / 60
        let remainingMinutes = safeMinutes % 60

        if hours > 0 && remainingMinutes > 0 {
            return "\(hours)h \(remainingMinutes)m"
        }

        if hours > 0 {
            return "\(hours)h"
        }

        return "\(remainingMinutes)m"
    }

    // ✅ FIXED — switch lives INSIDE the view
    @ViewBuilder
    var serviceStopNav: some View {
        
            navButton()
                .modifier(ListButtonModifier())

//            switch stop.operationStatus {
//            case .finished:
//                navButton()
//                    .modifier(SubmitButtonModifier())
//
//            case .notFinished:
//                navButton()
//                    .modifier(ListButtonModifier())
//
//            case .skipped:
//                navButton()
//                    .modifier(YellowButtonModifier())
//            }
    }

    // ✅ NO ViewModifier parameter
    private func navButton() -> some View {
        Group {
            if UIDevice.isIPhone {
                NavigationLink(
                    value: Route.dailyDisplayStop(
                        dataService: dataService,
                        serviceStop: stop
                    )
                ) {
                    Text(stop.customerName)
                        .lineLimit(2)
                }
            } else {
                Button {
                    masterDataManager.selectedServiceStops = nil
                    masterDataManager.selectedServiceStops = stop
                } label: {
                    Text(stop.customerName)
                        .lineLimit(2)
                }
            }
        }
        .foregroundColor(Color.basicFontText)
//            .modifier(OutLineButtonModifier())
    }

    var homeNav: some View {
        Button {
#if os(iOS)
            let address =
            "\(stop.address.streetAddress) \(stop.address.city) \(stop.address.state) \(stop.address.zip)"
                .replacingOccurrences(of: " ", with: "?")

            if let url = URL(string: "maps://?saddr=&daddr=\(address)"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
#endif
        } label: {
            Image(systemName: "house.fill")
                .foregroundColor(Color.basicFontText)
        }
//            .modifier(OutLineButtonModifier())
    }
}

private struct RouteTextTemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let templates: [RouteTextMessageTemplate]
    let isLoadingTemplates: Bool
    let customerName: String
    let phoneNumber: String
    let serviceAddress: String
    let draftMessage: (RouteTextMessageTemplate) -> String
    let onOpenTextDraft: (RouteTextMessageTemplate) -> Void

    @State private var selectedTemplateId: String

    init(
        templates: [RouteTextMessageTemplate],
        isLoadingTemplates: Bool,
        customerName: String,
        phoneNumber: String,
        serviceAddress: String,
        draftMessage: @escaping (RouteTextMessageTemplate) -> String,
        onOpenTextDraft: @escaping (RouteTextMessageTemplate) -> Void
    ) {
        self.templates = templates
        self.isLoadingTemplates = isLoadingTemplates
        self.customerName = customerName
        self.phoneNumber = phoneNumber
        self.serviceAddress = serviceAddress
        self.draftMessage = draftMessage
        self.onOpenTextDraft = onOpenTextDraft
        _selectedTemplateId = State(initialValue: templates.first?.id ?? "")
    }

    private var selectedTemplate: RouteTextMessageTemplate? {
        templates.first { $0.id == selectedTemplateId } ?? templates.first
    }

    private var selectedDraftMessage: String {
        guard let selectedTemplate else { return "" }
        return draftMessage(selectedTemplate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                recipientCard

                if isLoadingTemplates {
                    ProgressView("Loading templates...")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if templates.isEmpty {
                    emptyTemplatesView
                } else {
                    templateList
                    draftPreview
                    openDraftButton
                }
            }
            .padding(16)
            .navigationTitle("Text Customer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                ensureSelectedTemplate()
            }
            .onChange(of: templates) { _, _ in
                ensureSelectedTemplate()
            }
        }
    }

    private var recipientCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(customerName)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(phoneNumber.isEmpty ? "No phone number saved" : phoneNumber)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(phoneNumber.isEmpty ? Color.red : Color.secondary)

            if !serviceAddress.isEmpty {
                Text(serviceAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var templateList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(templates) { template in
                    Button {
                        selectedTemplateId = template.id
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.caption.weight(.bold))
                                .lineLimit(1)

                            Text(template.renderedFallbackDescription)
                                .font(.caption2)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundStyle(selectedTemplate?.id == template.id ? Color.white : Color.primary)
                        .frame(width: 176, alignment: .leading)
                        .padding(10)
                        .background(
                            selectedTemplate?.id == template.id
                            ? Color.accentColor
                            : Color.primary.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var draftPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Draft Preview")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView {
                Text(selectedDraftMessage.isEmpty ? "Select a template to preview the text." : selectedDraftMessage)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(selectedDraftMessage.isEmpty ? Color.secondary : Color.primary)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 180)
            .padding(12)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var openDraftButton: some View {
        Button {
            guard let selectedTemplate else { return }
            dismiss()
            onOpenTextDraft(selectedTemplate)
        } label: {
            Label("Open Text Draft", systemImage: "paperplane.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .disabled(phoneNumber.isEmpty || selectedDraftMessage.isEmpty || selectedTemplate == nil)
    }

    private var emptyTemplatesView: some View {
        VStack(spacing: 8) {
            Image(systemName: "message.badge")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No active text templates found.")
                .font(.subheadline.weight(.semibold))

            Text("Templates can be managed from Company Settings > Text Templates.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func ensureSelectedTemplate() {
        if selectedTemplateId.isEmpty || !templates.contains(where: { $0.id == selectedTemplateId }) {
            selectedTemplateId = templates.first?.id ?? ""
        }
    }
}
