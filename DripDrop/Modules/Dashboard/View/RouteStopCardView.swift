//
//  RouteStopCardView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//
import SwiftUI
import Darwin
enum numberPickerType{
    
}
enum PhoneNumberPickerType:Identifiable{
    case message, call, inApp
    var id:Int {
        hashValue
    }
}

@MainActor
final class RouteStopCardViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var customer: Customer? = nil
    @Published private(set) var weather: Weather? = nil

    func onLoad(companyId:String,serviceStop:ServiceStop) async throws {
        self.customer = try? await dataService.getCustomerById(companyId: companyId, customerId: serviceStop.customerId)
        self.weather = try? await WeatherManager.shared.fetchWeather(address: serviceStop.address)
    }
}
struct RouteStopCardView: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var VM : RouteStopCardViewModel


    init(dataService:any ProductionDataServiceProtocol,stop:ServiceStop,index:Int){
        _VM = StateObject(wrappedValue: RouteStopCardViewModel(dataService: dataService))
        _stop = State(wrappedValue: stop)
        _index = State(wrappedValue: index)

    }
    @State var customer:Customer? = nil
    @State var color:Color = .gray
    @State var foreGroundColor:Color = .black
    @State var showPhoneNumberPicker:Bool = false
    @State var phoneNumberPickerType:PhoneNumberPickerType? = nil
    @State var stop : ServiceStop
    @State var index:Int
    
    var body: some View {
        VStack(spacing:0){
            ZStack{
                HStack{
                    Rectangle()
                        .fill(color.opacity(0.5))
                        .frame(width: 4)
                    Spacer()
                }
                .padding(EdgeInsets(top: 0, leading: 12.5, bottom: 0, trailing: 0))
                VStack{
                    HStack{
                        Image(systemName: "\(String(index + 1)).square.fill")
                            .font(.title)
                            .background(Color.listColor)
                            .foregroundColor(color)
                            .frame(width: 30,height: 30)
                    
                        homeNav
                        if let weather = VM.weather {
                            WeatherSnapShotView(weather: weather)
                        }
                        Spacer()
                        serviceStopNav
                        message
                        
                    }
                    if stop.otherCompany {
                        if stop.contractedCompanyId != ""{
                            
                            HStack{
                                Spacer()
                                CompanyNameCardView(dataService: dataService, companyId: stop.contractedCompanyId)
                                    .modifier(OutLineButtonModifier())
                            }
                            .padding(.vertical,4)
                        }
                        
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
            }
        }
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))

        .task{
            if let company = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: company.id, serviceStop: stop)
                } catch {
                    print("Error onLoad - [RouteStopCardView]")
                    print(error)
                }
                
            } else {
                print("No Company")
            }
        }
        .onChange(of: phoneNumberPickerType, perform: { type in
            if let selectedType = type, let customer = VM.customer {
                if let strNumber = customer.phoneNumber {
                    
                    
                    print(selectedType)
                    switch selectedType {
                    case .call:
                        let tel = "tel://"
                        let formattedString = tel + strNumber
                        guard let url = URL(string: formattedString) else { return }
                        UIApplication.shared.open(url)
                        print(selectedType)
                    case .message:
                        let tel = "sms://"
                        let formattedString = tel + strNumber
                        guard let url = URL(string: formattedString) else { return }
                        UIApplication.shared.open(url)
                        print(selectedType)
                        print(selectedType)
                    case .inApp:
                        
                        print("Need to set up internal App Communication")
                    }
                }
            }
        })
    }
}

struct RouteStopCardView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()

    static var previews: some View {
        @State var showSignInView : Bool = false
        RouteStopCardView(
            dataService: dataService,
            stop: MockDataService().mockServiceStops.first!,
            index:1
        )
    }
}
extension RouteStopCardView {
    var message: some View {
        VStack{
            if let phoneNumber = VM.customer?.phoneNumber {
                Button(action: {
                    showPhoneNumberPicker.toggle()
                }, label: {
                    Image(systemName: "message.circle.fill")
                        .font(.title)
                        .foregroundColor(Color.darkGray)
                })
                .confirmationDialog("Select Type", isPresented: self.$showPhoneNumberPicker, actions: {
                    Button(action: {
                        self.phoneNumberPickerType = .inApp
                        
                    }, label: {
                        Text("In App")
                    })
                    Button(action: {
                        self.phoneNumberPickerType = .call
                    }, label: {
                        Text("Call: \(phoneNumber)")
                    })
                    Button(action: {
                        self.phoneNumberPickerType = .message
                    }, label: {
                        Text("Message \(phoneNumber)")
                    })
                })
            }
        }
    }
    var icon: some View {
        Circle()
            .fill(color)
            .frame(width: 30)
            .overlay(
                Image(systemName: stop.typeImage)
                    .foregroundColor(foreGroundColor)
            )
            .background(Color.white // any non-transparent background
                .cornerRadius(30)
                .shadow(color: Color.black.opacity(0.75), radius: 4, x: 4, y: 4)
            )
    }
    var serviceStopNav: some View {
        ZStack{
            switch stop.operationStatus {
            case .finished:
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.dailyDisplayStop(dataService:dataService, serviceStop: stop), label: {
                        Text("\(stop.customerName)")
                            .frame(minWidth: 50)

                    })
                    .lineLimit(2, reservesSpace: true)
                    .foregroundColor(Color.listColor)
                    .modifier(SubmitButtonModifier())
                    .modifier(OutLineButtonModifier())
                } else {
                    Button(action: {
                        masterDataManager.selectedServiceStops = nil
                        print("Selected New Service Stop \(stop.id)")
                        masterDataManager.selectedServiceStops = stop
                    }, label: {
                        Text("\(stop.customerName)")
                            .frame(minWidth: 50)
                    })
                    .lineLimit(2, reservesSpace: true)
                    .foregroundColor(Color.listColor)
                    .modifier(SubmitButtonModifier())
                    .modifier(OutLineButtonModifier())
                    
                }
            case .notFinished:
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.dailyDisplayStop(dataService:dataService, serviceStop: stop), label: {
                        Text("\(stop.customerName)")
                            .frame(minWidth: 50)
                    })
                    .lineLimit(2, reservesSpace: true)
                    .foregroundColor(Color.listColor)
                    .modifier(ListButtonModifier())
                    .modifier(OutLineButtonModifier())
                } else {
                    Button(action: {
                        masterDataManager.selectedServiceStops = nil
                        print("Selected New Service Stop \(stop.id)")
                        masterDataManager.selectedServiceStops = stop
                    }, label: {
                        Text("\(stop.customerName)")
                            .frame(minWidth: 50)
                    })
                    .lineLimit(2, reservesSpace: true)
                    .foregroundColor(Color.listColor)
                    .modifier(ListButtonModifier())
                    .modifier(OutLineButtonModifier())
                }
            case .skipped:
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.dailyDisplayStop(dataService:dataService, serviceStop: stop), label: {
                        Text("\(stop.customerName)")
                            .frame(minWidth: 50)
                    })
                    .lineLimit(2, reservesSpace: true)
                    .foregroundColor(Color.listColor)
                    .modifier(YellowButtonModifier())
                    .modifier(OutLineButtonModifier())
                } else {
                    Button(action: {
                        masterDataManager.selectedServiceStops = nil
                        print("Selected New Service Stop \(stop.id)")
                        masterDataManager.selectedServiceStops = stop
                    }, label: {
                        Text("\(stop.customerName)")
                            .frame(minWidth: 50)
                    })
                    .lineLimit(2, reservesSpace: true)
                    .foregroundColor(Color.listColor)
                    .modifier(YellowButtonModifier())
                    .modifier(OutLineButtonModifier())
                }
            }
        }
    }
    var homeNav: some View {
        ZStack{
            switch stop.operationStatus {
            case .finished:
                Button(action: {
#if os(iOS)
                    let address = "\(stop.address.streetAddress) \(stop.address.city) \(stop.address.state) \(stop.address.zip)"
                    
                    let urlText = address.replacingOccurrences(of: " ", with: "?")
                    
                    let url = URL(string: "maps://?saddr=&daddr=\(urlText)")
                    
                    if UIApplication.shared.canOpenURL(url!) {
                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    }
#endif
                }, label: {
                    ZStack{
                        Text("1")
                            .foregroundColor(Color.clear)
                            .lineLimit(2, reservesSpace: true)
                        Image(systemName: "house.fill")
                    }
                    .foregroundColor(Color.listColor)
                    .modifier(SubmitButtonModifier())
                    .modifier(OutLineButtonModifier())
                })

            case .notFinished:
                Button(action: {
#if os(iOS)
                    let address = "\(stop.address.streetAddress) \(stop.address.city) \(stop.address.state) \(stop.address.zip)"
                    
                    let urlText = address.replacingOccurrences(of: " ", with: "?")
                    
                    let url = URL(string: "maps://?saddr=&daddr=\(urlText)")
                    
                    if UIApplication.shared.canOpenURL(url!) {
                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    }
#endif
                }, label: {
                    ZStack{
                        Text("1")
                            .foregroundColor(Color.clear)
                            .lineLimit(2, reservesSpace: true)
                        Image(systemName: "house.fill")
                    }
                    .foregroundColor(Color.listColor)
                    .modifier(ListButtonModifier())
                    .modifier(OutLineButtonModifier())

                })
            case .skipped:
                Button(action: {
#if os(iOS)
                    let address = "\(stop.address.streetAddress) \(stop.address.city) \(stop.address.state) \(stop.address.zip)"
                    
                    let urlText = address.replacingOccurrences(of: " ", with: "?")
                    
                    let url = URL(string: "maps://?saddr=&daddr=\(urlText)")
                    
                    if UIApplication.shared.canOpenURL(url!) {
                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    }
#endif
                }, label: {
                    
                    ZStack{
                        Text("1")
                            .foregroundColor(Color.clear)
                            .lineLimit(2, reservesSpace: true)
                        Image(systemName: "house.fill")
                    }
                    .foregroundColor(Color.listColor)
                    .modifier(YellowButtonModifier())
                    .modifier(OutLineButtonModifier())
                })
            }
        }
    }
}
