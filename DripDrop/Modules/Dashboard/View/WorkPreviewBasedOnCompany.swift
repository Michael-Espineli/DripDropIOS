//
//  WorkPreviewBasedOnCompany.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/13/24.
//

import SwiftUI

struct WorkPreviewBasedOnCompany: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @StateObject private var VM : AllViewModel
    
    init(dataService:any ProductionDataServiceProtocol,company:Company){
        _VM = StateObject(wrappedValue: AllViewModel(dataService: dataService))
        _company = State(wrappedValue: company)
    }
    @State var company:Company
    var body: some View {
        ZStack{
            if VM.activeRoute != nil{
                routePreview
            }
        }
        .task {
            if let user = masterDataManager.user {
                do {
                    try await VM.loadCompanyWorkPreview(companyId: company.id, user: user)
                } catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
    WorkPreviewBasedOnCompany(dataService: MockDataService(), company: MockDataService.mockCompany)
}
extension WorkPreviewBasedOnCompany {
    var routePreview: some View {
        VStack(alignment: .leading){
            HStack{
                Text("Preview For \(company.name ?? "")")
                    .font(.headline)
                    .fontDesign(.monospaced)
                    .foregroundColor(Color.basicFontText)
                Spacer()
            }
            NavigationLink(value: Route.mainDailyDisplayView(dataService:dataService), label: {
                HStack{
                    ZStack{
                        Circle()
                            .fill(.gray.opacity(0.5))
                            .frame(width: 90, height: 90)
                        
                        Circle()
                            .trim(from: 0, to: Double(VM.finishedStops ?? 0) / Double(VM.totalStops ?? 1))
                            .stroke(Color.poolGreen, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        Text("\(String( VM.finishedStops ?? 0)) / \(String( VM.totalStops ?? 0))")
                            .foregroundColor(Color.basicFontText)
                            .font(.headline)
                            .bold(true)
                    }
                    .foregroundColor(Color.basicFontText)
                    Spacer()
                    
                    if let activeRoute = VM.activeRoute {
                        VStack(alignment: .leading){
                            VStack{
                                Text("Miles:")
                                HStack{
                                    if let startMilage = activeRoute.startMilage {
                                        Text("\(startMilage)")
                                            .foregroundColor(Color.white)
                                    }
                                    if let endMilage = activeRoute.endMilage {
                                        Text(" - \(endMilage)")
                                            .foregroundColor(Color.white)
                                    }
                                }
                            }
                            VStack{
                                Text("Time:")
                                HStack{
                                    if let startTime = activeRoute.startTime {
                                        Text("\(time(date:startTime))")
                                            .foregroundColor(Color.white)
                                    }
                                    if let endTime = activeRoute.endTime {
                                        Text(" - \(time(date:endTime))")
                                            .foregroundColor(Color.white)
                                    }
                                }
                            }
                        }
                        .font(.footnote)
                    }
                }
                .padding(8)
                .background(Color.darkGray)
                .cornerRadius(8)
            })
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
    }
}
