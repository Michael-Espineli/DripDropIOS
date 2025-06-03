//
//  DailyRouteCardView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/3/23.
//

import SwiftUI

struct DailyRouteCardView: View {
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var weatherVM = WeatherViewModel()
    
    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State var stop:ServiceStop
    @State var company:Company

    var body: some View {
        ZStack{
            HStack{
                switch stop.operationStatus {
                case .finished:
                    Line()
                        .stroke(style: .init(dash: [10]))
                        .foregroundStyle(Color.poolGreen.opacity(0.5))
                        .frame(height: 1)
                case .notFinished:
                    Line()
                        .stroke(style: .init(dash: [10]))
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .frame(height: 1)
                case .skipped:
                    Line()
                        .stroke(style: .init(dash: [10]))
                        .foregroundStyle(Color.realYellow)
                        .frame(height: 1)
                }
            }
            
            HStack{
                icon
                
                Spacer()

                VStack{
                    homeNav
                    NavigationLink(destination: {
                        VStack{
                            ServiceStopDetailView(dataService:dataService, serviceStop: stop)
                        }
                    }, label: {
                        name
                    })
                }
//                WeatherSnapShotView(weather: weatherVM.currentWeather ?? Weather(temperature: Int(72), weatherCode: .icePellets))
//                    .frame(width: 75,height: 25)
            }
        }
        .frame(height: 100)
        .task{
            do {
                try await weatherVM.fetchWeather(address: stop.address)
            } catch {
                print("Failed to Get Weather")
            }
        }
        
    }
}

struct DailyRouteCardView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSignInView:Bool = false
        DailyRouteCardView(showSignInView:$showSignInView,user:DBUser(id: "", email: "", firstName: "", lastName: "", exp: 0,recentlySelectedCompany: "") ,stop: MockDataService().mockServiceStops.first!, company: MockDataService.mockCompany)
    }
}
func getJobIcon(jobTypeId:String)->String{
    switch jobTypeId {
    case "Weekly Cleaning":
        return "bubbles.and.sparkles.fill"
    case "Estimate":
        return "list.bullet.clipboard"
    case "Repair":
        return "wrench.adjustable.fill"
    default:
        return "bubbles.and.sparkles.fill"
    }
    //Maintenance
}
extension DailyRouteCardView {
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
                    HStack{
                        Image(systemName: "point.topleft.down.curvedto.point.filled.bottomright.up")
                        Text("\(stop.address.streetAddress)")

                            Spacer()
                            Image(systemName: "chevron.right")
                        
                    }
                    .frame(width: 200,height: 25)
                    .padding(3)
                    .background(Color.poolGreen)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
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
                    HStack{
                        Image(systemName: "point.topleft.down.curvedto.point.filled.bottomright.up")
                        Text("\(stop.address.streetAddress)")

                            Spacer()
                            Image(systemName: "chevron.right")
                        
                    }
                    .frame(width: 200,height: 25)
                    .padding(3)
                    .background(Color.gray)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
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
                    HStack{
                        Image(systemName: "point.topleft.down.curvedto.point.filled.bottomright.up")
                        Text("\(stop.address.streetAddress)")

                            Spacer()
                            Image(systemName: "chevron.right")
                        
                    }
                    .frame(width: 200,height: 25)
                    .padding(3)
                    .background(Color.realYellow)
                    .foregroundColor(Color.basicFontText)
                    .cornerRadius(10)
                    .font(.footnote)

                })
            }
        }
    }
    var timer: some View {
        ZStack{
            switch stop.operationStatus {
            case .finished:
                HStack{
                    Image(systemName: "timer")
                    Text("0:20")
                }
                .padding(5)
                .background(Color.poolGreen)
                .foregroundColor(Color.white)
                .cornerRadius(10)
            case .notFinished:
                HStack{
                    Image(systemName: "timer")
                    Text("0:20")
                }
                .padding(5)
                .background(Color.gray)
                .foregroundColor(Color.white)
                .cornerRadius(10)
            case .skipped:
                HStack{
                    Image(systemName: "timer")
                    Text("0:20")
                }
                .padding(5)
                .background(Color.realYellow)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(10)
            }
            
        }
    }
    var icon: some View {
        ZStack{
            switch stop.operationStatus {
            case .finished:
                ZStack{
                    Rectangle()
                        .fill(Color.poolGreen.opacity(0.5))
                        .frame(width: 5)
                    ZStack{
                        Circle()
                            .fill(Color.poolGreen)
                            .frame(width: 30)
                        Image(systemName: stop.typeImage)
                            .frame(width: 20)
                            .foregroundColor(Color.white)
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            case .notFinished:
                ZStack{
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 5)
                    ZStack{
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 30)
                        Image(systemName: stop.typeImage)
                            .frame(width: 20)
                            .foregroundColor(Color.white)
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            case .skipped:
                ZStack{
                    Rectangle()
                        .fill(Color.realYellow.opacity(0.5))
                        .frame(width: 5)
                    ZStack{
                        Circle()
                            .fill(Color.realYellow)
                            .frame(width: 30)
                        Image(systemName: stop.typeImage)
                            .frame(width: 20)
                            .foregroundColor(Color.basicFontText)
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            }
        }
    }
    var name: some View {
        HStack{
            switch stop.operationStatus {
            case .finished:
                HStack{
                    
                    Text("\(stop.customerName)")
                    Spacer()
                    Image(systemName: "chevron.forward")
                }
                    .padding(5)
                    .background(Color.poolGreen)
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
            case .notFinished:
                HStack{
                    
                    Text("\(stop.customerName)")
                    Spacer()
                    Image(systemName: "chevron.forward")
                }
                    .padding(5)
                    .background(Color.gray)
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
            case .skipped:
                HStack{
                    Text("\(stop.customerName)")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding(5)
                    .background(Color.realYellow)
                    .foregroundColor(Color.basicFontText)
                    .cornerRadius(8)
            }
        }
        .frame(width: 200)
    }
}
