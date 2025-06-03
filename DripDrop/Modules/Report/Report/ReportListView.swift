//
//  ReportListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/17/24.
//

import SwiftUI

struct ReportListView: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService

    var body: some View {
        ZStack{
            list
            
        }
    }
}

struct ReportListView_Previews: PreviewProvider {
    static var previews: some View {
        ReportListView()
    }
}
extension ReportListView {
    var list: some View {
        VStack{
            ScrollView{
                ForEach(ReportType.allCases){ report in
                    if UIDevice.isIPhone {
                        NavigationLink(value: Route.reports(dataService:dataService), label: {
                            ReportCardView(report: report)
                        })
                        .padding(8)
                    } else {
                        Button(action: {
                            masterDataManager.selectedReport = report
                        }, label: {
                            ReportCardView(report: report)
                        })
                        .padding(8)
                    }
                }
            }
        }
    }
}
