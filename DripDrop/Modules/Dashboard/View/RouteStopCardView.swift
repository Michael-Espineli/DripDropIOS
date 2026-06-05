//
//  RouteStopCardView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI
import Darwin

enum numberPickerType {}

enum PhoneNumberPickerType: Identifiable {
    case message, call, inApp
    var id: Int { hashValue }
}

@MainActor
final class RouteStopCardViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published private(set) var customer: Customer? = nil
    @Published private(set) var weather: Weather? = nil

    func onLoad(companyId: String, serviceStop: ServiceStop) async throws {
        self.customer = try? await dataService.getCustomerById(
            companyId: companyId,
            customerId: serviceStop.customerId
        )
        self.weather = try? await WeatherManager.shared.fetchWeather(
            address: serviceStop.address
        )
    }
}

struct RouteStopCardView: View {

    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: RouteStopCardViewModel

    init(dataService: any ProductionDataServiceProtocol, stop: ServiceStop, index: Int) {
        _VM = StateObject(wrappedValue: RouteStopCardViewModel(dataService: dataService))
        _stop = State(wrappedValue: stop)
        _index = State(wrappedValue: index)
    }

    @State var customer: Customer? = nil
    @State var showPhoneNumberPicker: Bool = false
    @State var phoneNumberPickerType: PhoneNumberPickerType? = nil
    @State var stop: ServiceStop
    @State var index: Int

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
                let customer = VM.customer,
                let strNumber = customer.phoneNumber
            else { return }

            switch selectedType {
            case .call:
                if let url = URL(string: "tel://\(strNumber)") {
                    UIApplication.shared.open(url)
                }
            case .message:
                if let url = URL(string: "sms://\(strNumber)") {
                    UIApplication.shared.open(url)
                }
            case .inApp:
                print("Need to set up internal App Communication")
            }
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
            if let phoneNumber = VM.customer?.phoneNumber {
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
                    Button("Call: \(phoneNumber)") { phoneNumberPickerType = .call }
                    Button("Message \(phoneNumber)") { phoneNumberPickerType = .message }
                }
            }
        }
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
