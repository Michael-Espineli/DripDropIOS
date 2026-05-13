//
//  RouteTechView2.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/7/26.
//

import SwiftUI

struct RouteTechView2: View {

    @EnvironmentObject var VM: RouteBoardViewModel
    @EnvironmentObject var dataService: ProductionDataService

    let tech: CompanyUser
    let day: DaysOfWeek

    var route: RecurringRoute? {
        VM.route(for: tech.userId, day: day)
    }

    var stops: [RecurringServiceStop] {
        VM.stops(for: tech.userId, day: day)
    }

    var body: some View {
        VStack {
            if let route {
                
                HStack{
                    VStack{
                        Text(route.tech)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Stops In Route: \(String(route.order.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {
                            VM.editRoute.toggle()
                            VM.selectedDay = day
                            VM.selectedTech = tech
                            VM.selectedRoute = route
                    }, label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.subheadline)
                            .padding(8)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    })
                    Button(action: {
                        if let selectedRoute = VM.selectedRoute, selectedRoute.id == route.id {
                            VM.selectedRoute = nil
                        } else {
                            VM.selectedRoute = route
                        }
                    }, label: {
                            if let selectedRoute = VM.selectedRoute, selectedRoute.id == route.id {
                                Image(systemName: "chevron.down.square")
                                    .font(.subheadline)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "chevron.right.square")
                                    .font(.subheadline)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        
                    })
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                if let selectedRoute = VM.selectedRoute, selectedRoute.id == route.id {
                    ForEach(route.order) { order in
                        RecurringRouteStopView2(
                            order: order,
                            day: day,
                            tech: tech
                        )
                    }
                    .padding(.leading, 8)
                }
            }
        }
    }
}

struct RecurringRouteStopView2: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var VM : RouteBoardViewModel
    init(
        order: recurringRouteOrder,
        day: DaysOfWeek,
        tech: CompanyUser
    ){
        _order = State(wrappedValue: order)
        _day = State(wrappedValue: day)
        _tech = State(wrappedValue: tech)
        
    }
    var stop: RecurringServiceStop? {
        VM.stop(for: order.recurringServiceStopId)
    }
    
    @State var order: recurringRouteOrder
    @State var day: DaysOfWeek
    @State var tech: CompanyUser
    
    @State var showNewRoute : Bool = false
    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Order Badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.poolBlue.opacity(0.15))
                    .frame(width: 34, height: 34)

                Text("\(order.order)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.poolBlue)
            }

            VStack(alignment: .leading, spacing: 6) {

                // Customer + Frequency
                HStack(spacing: 8) {

                    Text("\(order.customerName)")
                        .font(.headline)
                        .fontWeight(.semibold)

                    if let reucrringServiceStop = stop {
                        Group {
                            switch reucrringServiceStop.frequency {
                            case .daily:
                                Text("Daily")
                            case .weekDay:
                                Text("Week Day")
                            case .weekly:
                                Text("Weekly")
                            case .monthly:
                                Text("Monthly")
                            case .yearly:
                                Text("Annually")
                            default:
                                Text("Frequency")
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.poolBlue.opacity(0.12))
                        .foregroundColor(Color.poolBlue)
                        .clipShape(Capsule())
                    }
                }

                // Dates + Company
                HStack {
                    if let reucrringServiceStop = stop {
                        HStack(spacing: 4) {
                            Text("\(fullDate(date: reucrringServiceStop.startDate))")
                            Text("–")

                            if reucrringServiceStop.noEndDate {
                                Text("No End Date")
                            } else {
                                if let endDate = reucrringServiceStop.endDate {
                                    Text("\(fullDate(date: endDate))")
                                } else {
                                    Text("No End Date")
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Spacer()

                        RecurringServiceStopCompanyNameCardView(
                            dataService: dataService,
                            recurringServiceStopId: reucrringServiceStop.id
                        )
                    }
                }
            }

            Spacer()

            Button(action: {
                VM.editRecurringServiceStop.toggle()
                VM.selectedDay = day
                VM.selectedTech = tech
                VM.selectedRecurringServiceStop = stop
            }) {
                Image(systemName: "pencil")
                    .font(.subheadline)
                    .padding(8)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}
/*
 HStack{
     Image(systemName: "\(String(order.order)).square.fill")
     Spacer()
     VStack{
         HStack{
             Text("\(order.customerName)")
                 .padding(5)
                 .background(Color.blue)
                 .foregroundColor(Color.white)
                 .cornerRadius(5)
             if let reucrringServiceStop = stop {
                 switch reucrringServiceStop.frequency {
                 case .daily:
                     Text("- Daily")
                 case .weekDay:
                     Text("- Week Day")
                 case .weekly:
                     Text("- Weekly")
                 case .monthly:
                     Text("- Monthly")
                 case .yearly:
                     Text("- Annually")
                 default:
                     Text("Frequency")
                 }
                 
             }
         }
         HStack{
             if let reucrringServiceStop = stop {
                 Text("\(fullDate(date:reucrringServiceStop.startDate))")
                     .font(.footnote)
                 
                 Text(" - ")
                     .font(.footnote)
                 
                 if reucrringServiceStop.noEndDate {
                     Text("No End Date")
                         .font(.footnote)
                     
                 } else {
                     if let endDate = reucrringServiceStop.endDate {
                         Text("\(fullDate(date:endDate))")
                             .font(.footnote)
                         
                     } else  {
                         Text("No End Date")
                             .font(.footnote)
                     }
                 }
                 Spacer()
                 RecurringServiceStopCompanyNameCardView(dataService: dataService, recurringServiceStopId: reucrringServiceStop.id)
             }
         }
     }
     Spacer()
     Button(action: {
         VM.editRecurringServiceStop.toggle()
         VM.selectedDay = day
         VM.selectedTech = tech
         VM.selectedRecurringServiceStop = stop
     }, label: {
         Image(systemName: "pencil")
     })
 }
 .padding(5)
 */
