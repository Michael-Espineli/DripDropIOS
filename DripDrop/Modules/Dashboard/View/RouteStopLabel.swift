//
//  RouteStopLabel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/21/24.
//

import SwiftUI

struct RouteStopLabel: View {
    @EnvironmentObject var dataService: ProductionDataService
    @State var stop : ServiceStop
    @State var index:Int
    let selected:Bool
    var body: some View {
        VStack(spacing:0){
            ZStack{
                HStack{
                    Rectangle()
                        .fill(selected ? Color.poolGreen.opacity(0.5) : Color.gray.opacity(0.5))
                        .frame(width: 4)
                    Spacer()
                }
                .padding(EdgeInsets(top: 0, leading: 12.5, bottom: 0, trailing: 0))
                VStack{
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
                    if stop.otherCompany {
                            if stop.contractedCompanyId != ""{
                                HStack{
                                    Spacer()
                                    CompanyNameCardView(dataService: dataService, companyId: stop.contractedCompanyId)
                                }
                            }
                        
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))

            }
        }
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
    }
}

struct RouteStopLabel_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSignInView : Bool = false
        RouteStopLabel(stop: MockDataService().mockServiceStops.first!,index:1,selected: false)
    }
}
extension RouteStopLabel {
    var message: some View {
        VStack{
                    Image(systemName: "message.circle.fill")
                        .font(.title)
                        .foregroundColor(Color.gray)
        }
    }
    var icon: some View {
        Circle()
            .fill(selected ? Color.poolGreen : Color.gray)
            .frame(width: 30)
            .overlay(
                Image(systemName: stop.typeImage)
                    .foregroundColor(Color.white)
            )
    }
    var serviceStopNav: some View {
        Text("\(stop.customerName)")
            .frame(minWidth: 50)
            .font(.body)
            .lineLimit(2, reservesSpace: true)
            .padding(5)
            .background(selected ? Color.poolGreen : Color.darkGray)
            .foregroundColor(Color.white)
            .cornerRadius(5)
            .background(Color.white // any non-transparent background
                .cornerRadius(5)
                .shadow(color: Color.black.opacity(0.75), radius: 4, x: 4, y: 4)
            )
    }
    var homeNav: some View {
        ZStack{
            HStack{
                Image(systemName: "house.fill")
                Text("\(stop.address.streetAddress)")
                    .lineLimit(2, reservesSpace: true)
                    .font(.body)
            }
            .padding(5)
            .background(selected ? Color.poolGreen : Color.darkGray)
            .foregroundColor(Color.white)
            .cornerRadius(5)
            .background(Color.white // any non-transparent background
                .cornerRadius(5)
                .shadow(color: Color.black.opacity(0.75), radius: 4, x: 4, y: 4)
            )
        }
    }

}
