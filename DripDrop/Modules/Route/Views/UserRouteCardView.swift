//
//  UserRouteCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/19/23.
//

import SwiftUI

struct UserRouteCardView: View {
    @Environment(\.locale) var locale
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager


    
    let tech:DBUser
    let activeRoute:ActiveRoute
    let statusList:[String] = [
    "In Progress",
    "Traveling",
    "Did Not Start",
    "Break",
    "Finished"
    ]
    @State var finished:Bool = false
    @State var time:Date = Date().startOfDay()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var duration = 0

    var body: some View {
        VStack{
            HStack{
                Text("\(tech.firstName ?? "") \(tech.lastName ?? "")")
                Text("3 /\(activeRoute.serviceStopsIds.count)")

            }
            HStack{
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(height: 10)
                    .cornerRadius(10)
                    .overlay(overlayView.mask(Rectangle()))
            }
            HStack{
                Text("\(Measurement(value: activeRoute.distanceMiles, unit: UnitLength.kilometers).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))")

                Spacer()

            }
            HStack{
                Text("Start: 7:38 Am")
                Spacer()
                if finished {
                    Text("End: 4:38 Pm")
                } else {
                    Text("Duration: 4:20")
                }
            }
            HStack{
                Text("Status: ")
                let status = "Break"//statusList.randomElement() ?? ""
                Text("\(status)")
                    .padding(5)
                    .background(getColor(status: status))
                    .cornerRadius(5)
                Text("Duration: \(displayNumberAsMinAndHourAndSecond(seconds:duration))")
                Spacer()
            }
            NavigationLink(value: Route.routeOverview(route: activeRoute,dataService:dataService), label: {
                Text("See Detail")
                    .foregroundColor(Color.basicFontText)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(5)
            })

        }
        .padding(5)
        .background(Color.gray)
        .cornerRadius(5)

    }
    func getColor(status:String)->Color{
        switch status {
        case "In Progress":
            return Color.yellow
        case "Did Not Start":
            return Color.basicFontText.opacity(0.5)
        case "Traveling":
            return Color.blue
        case "Break":
            return Color.purple
        case "Finished":
            return Color.poolGreen
        default:
            return Color.gray
        }
    }
    private var overlayView:some View {
        GeometryReader{ geo in
            ZStack(alignment: .leading){
                Rectangle()
                    .foregroundColor(Color.poolGreen)
                    .frame(width: CGFloat(3) / (7) * geo.size.width)
                    .cornerRadius(10)

            }
        }
    }
}

//
//  UserRouteCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/19/23.
//

import SwiftUI

struct UserRouteCardView2: View {
    @Environment(\.locale) var locale
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    let activeRoute:ActiveRoute
    let statusList:[String] = [
    "In Progress",
    "Traveling",
    "Did Not Start",
    "Break",
    "Finished"
    ]
    @State var finished:Bool = false
    @State var time:Date = Date().startOfDay()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var duration = 0

    var body: some View {
        ZStack{
            if UIDevice.isIPhone {
                    NavigationLink(value: Route.routeOverview(route: activeRoute,dataService: dataService), label: {
                        info
                })
            } else {
                Button(action: {
                    masterDataManager.selectedActiveRoute = activeRoute
                }, label: {
                    info
                })
            }
        }
        .onReceive(timer) { time in
            if activeRoute.startTime != nil {
                if duration > -1 {
                    duration += 1
                }
            }
        }
    }
    func getColor(status:String)->Color{
        switch status {
        case "In Progress":
            return Color.yellow
        case "Did Not Start":
            return Color.basicFontText.opacity(0.5)
        case "Traveling":
            return Color.blue
        case "Break":
            return Color.purple
        case "Finished":
            return Color.poolGreen
        default:
            return Color.gray
        }
    }
    private var overlayView:some View {
        GeometryReader{ geo in
            ZStack(alignment: .leading){
                Rectangle()
                    .foregroundColor(Color.poolGreen)
                    .frame(width: CGFloat(1) / CGFloat(activeRoute.serviceStopsIds.count) * geo.size.width)
                    .cornerRadius(10)
            }
        }
    }
}
extension UserRouteCardView2 {
    var info: some View {
        VStack{
            HStack{
                Text("\(activeRoute.techName)")
                    .font(.headline)
                Spacer()
  
                Text("\(weekDay(date:activeRoute.date))")
            }
            
            ProgressView("\(String(activeRoute.finishedStops)) / \(String(activeRoute.totalStops))", value: Double(activeRoute.finishedStops), total: Double(activeRoute.totalStops))
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            HStack{
                
//                Text("Start: \(DripDropApp.time(date: activeRoute.startTime))")
                Text("Time")

                Spacer()
                if let ending = activeRoute.endTime {
//                    Text("End: \(DripDropApp.time(date:ending))")
                    Text("Time")

                } else {
                    Text("Duration: \(displayNumberAsMinAndHourAndSecond(seconds:duration))")
                }
            }
            HStack{
                Text("Distance")
                Spacer()
                Text("\(Measurement(value: activeRoute.distanceMiles, unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))")
                Spacer()
            }
            HStack{
                Text("Status: ")
                let status = "Break"//statusList.randomElement() ?? ""
                Text("\(activeRoute.status.rawValue )")
                    .padding(.horizontal,8)
                    .padding(.vertical,4)
                    .background(getColor(status: status))
                    .cornerRadius(4)
                    .foregroundColor(Color.white)
                    .fontDesign(.monospaced)
                Spacer()
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.75))
        .cornerRadius(8)
    }
}

