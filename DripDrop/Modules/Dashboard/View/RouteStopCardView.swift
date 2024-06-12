//
//  RouteStopCardView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//
enum numberPickerType{
    
}
enum PhoneNumberPickerType:Identifiable{
    case message, call, inApp
    var id:Int {
        hashValue
    }
}
import SwiftUI

struct RouteStopCardView: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var customerVM : CustomerViewModel
    @State var stop : ServiceStop
    @State var index:Int

    init(dataService:any ProductionDataServiceProtocol,stop:ServiceStop,index:Int){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _stop = State(wrappedValue: stop)
        _index = State(wrappedValue: index)

    }
    @State var customer:Customer? = nil
    @State var color:Color = .gray
    @State var foreGroundColor:Color = .black
    @State var showPhoneNumberPicker:Bool = false
    @State var phoneNumberPickerType:PhoneNumberPickerType? = nil

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
                HStack{
                    icon
                    Image(systemName: "\(String(index)).square.fill")
                        .font(.headline)
                    Spacer()
                    HStack{
                        homeNav
                        Spacer()
                        serviceStopNav
                        message
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
            }
        }
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))

        .onAppear(perform: {
            if let company = masterDataManager.selectedCompany {
                if stop.skipped {
                    color = .realYellow
                    foreGroundColor = .poolWhite
                } else if stop.finished {
                    color = .poolGreen
                    foreGroundColor = .poolWhite
                    
                } else {
                    color = .gray
                    foreGroundColor = .poolWhite
                }
                //Get Current Customer
                Task{
                    do {
                        //Maybe Change this to get the contact from the service Location
                        try await customerVM.getCustomer(companyId: company.id, customerId: stop.customerId)
                    } catch {
                        
                    }
                }
            } else {
                print("No Company")
            }
        })
        .onChange(of: phoneNumberPickerType, perform: { type in
            if let selectedType = type, let customer = customerVM.customer {
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
        RouteStopCardView(dataService: dataService, stop: ServiceStop(id: UUID().uuidString, typeId: "Estimate", customerName: "Kellie Lewis", customerId: "", address: Address(streetAddress: "3300 W Camelback Rd", city: "Phoeniz", state: "Az", zip: "85017", latitude: 33.30389, longitude: -112.07432), dateCreated: Date(), serviceDate: Date(), duration: 60, rate: 0, tech: "Keler Smith", techId: "2M8ws9EtYCZufCeoZDl1Z5J28pq1", recurringServiceStopId: "", description: "", serviceLocationId: "", type: "", typeImage: "list.bullet.clipboard", jobId: "", finished: true, skipped: false, invoiced: false, checkList: [], includeReadings: true, includeDosages: true),index:1)
    }
}
extension RouteStopCardView {
    var message: some View {
        VStack{
            if let phoneNumber = customerVM.customer?.phoneNumber {
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
              .shadow(color: Color.black, radius: 5, x: 5, y: 5)
            )
    }
    var serviceStopNav: some View {
        ZStack{
            if UIDevice.isIPhone {
                NavigationLink(value: Route.dailyDisplayStop(dataService:dataService, serviceStop: stop), label: {
                    Text("\(stop.customerName)")
                        .frame(minWidth: 50)
                        .font(.body)

                })
                .lineLimit(2, reservesSpace: true)
                .padding(5)
                .background(color)
                .foregroundColor(foreGroundColor)
                .cornerRadius(5)
                .background(Color.white // any non-transparent background
                    .cornerRadius(5)
                    .shadow(color: Color.black, radius: 5, x: 5, y: 5)
                )
            } else {
                Button(action: {
                    masterDataManager.selectedID = stop.id
                    masterDataManager.selectedServiceStops = stop
                    
                    
                }, label: {
                    Text("\(stop.customerName)")
                        .frame(minWidth: 50)
                        .font(.body)

                })
                .lineLimit(2, reservesSpace: true)
                .padding(5)
                .background(color)
                .foregroundColor(foreGroundColor)
                .cornerRadius(5)
                .background(Color.white // any non-transparent background
                    .cornerRadius(5)
                    .shadow(color: Color.black, radius: 5, x: 5, y: 5)
                )
            }
        }
    }
    var homeNav: some View {
        ZStack{
            if stop.skipped {
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
                    HStack{
//                        Image(systemName: "house.fill")
                        Text("\(stop.address.streetAddress)")
                            .lineLimit(2, reservesSpace: true)
                            .font(.body)
                    }
                })
                .padding(5)
                .background(Color.realYellow)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .background(Color.white // any non-transparent background
                    .cornerRadius(5)
                  .shadow(color: Color.black, radius: 5, x: 5, y: 5)
                )
                
            } else {
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
                    HStack{
//                        Image(systemName: "house.fill")
                        Text("\(stop.address.streetAddress)")
                            .lineLimit(2, reservesSpace: true)
                            .font(.body)
                    }
                })
                .padding(5)
                .background(stop.finished ? Color.poolGreen: Color.gray)
                .foregroundColor(foreGroundColor)
                .cornerRadius(5)
                .background(Color.white // any non-transparent background
                    .cornerRadius(5)
                  .shadow(color: Color.black, radius: 5, x: 5, y: 5)
                )
                
            }
        }
    }

}
