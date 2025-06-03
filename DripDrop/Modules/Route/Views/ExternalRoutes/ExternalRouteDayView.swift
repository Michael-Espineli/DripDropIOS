//
//  ExternalRouteDayView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/29/24.
//

import SwiftUI

struct ExternalRouteDayView: View {
    init(dataService: any ProductionDataServiceProtocol,day:String,externalRouteStopList:[ExternalRouteStop]){
        _VM = StateObject(wrappedValue: ExternalRouteDayViewModel(dataService: dataService))
        _day = State(wrappedValue: day)
        _externalRouteStopList = State(wrappedValue: externalRouteStopList)
    }
    @Environment(\.locale) var locale
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var VM : ExternalRouteDayViewModel

    @State var day:String
    @State var externalRouteStopList:[ExternalRouteStop]

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            list
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(
                        companyId:currentCompany.id,
                        day:day,
                        externalRoutestopList:externalRouteStopList
                    )
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
    }
}

#Preview {
    ExternalRouteDayView(dataService: MockDataService(), day: "Monday", externalRouteStopList: [])
}
extension ExternalRouteDayView {
    var list: some View {
        VStack{
                HStack{
                    Text("\(day)")
                    Spacer()
                }
                .fontDesign(.monospaced)
                .modifier(ListButtonModifier())
            ForEach(VM.externalRoutes){ route in
                VStack{
                    ExternalRouteCardView(externalRoute: route)
                    if let list = VM.externalRoutesWithStops[route] {
                        ForEach(list){ externalRoute in
                            Button(action: {
                                
                            }, label: {
                                ExternalRouteStopCardView(externalRouteStop: externalRoute)
                            })
                            Divider()
                        }
                    }
                }
                .padding(.top,8)
                .padding(.leading,16)
            }
        }

    }
}
