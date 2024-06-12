//
//  RouteManagmentView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//
//DEVELOPER CREATE A WAY TO CHECK IF THERE IS A RECURRING ROUTE THAT ALREADY EXISTS THERE So that One person does not have two Recurring Routes on their board.
import SwiftUI

struct RouteManagmentView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @StateObject var VM : RouteManagmentViewModel

    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: RouteManagmentViewModel(dataService: dataService))
    }
    @State var days:[String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    @State var isLoading:Bool = false

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView(showsIndicators: false){
                LazyVStack{
                    if VM.isLoading {
                        VStack{
                            ProgressView()
                            Text("Loading")
                        }
                    } else {
                        Group{
                            dayThenTech
                        }
                       
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 10))
            }
        }
        .toolbar{
            ToolbarItem{
                Button(action: {
                   VM.reload()
                }, label: {
                    Image(systemName: "gobackward")
                })
            }
        }
        .refreshable {
            Task{
                if let company = masterDataManager.selectedCompany {
                    do {
                        try await VM.firstLoad(companyId: company.id)
                    } catch {
                        print("Error")
                    }
                }
            }
                }
        .task {
            if let company = masterDataManager.selectedCompany {
                do {
                    try await VM.firstLoad(companyId: company.id)
                } catch {
                    print("Error")
                }
            }
        }
        .onChange(of: masterDataManager.reloadBuilderView, perform: { reload in
            Task{
                if let company = masterDataManager.selectedCompany {
                    do {
                        try await VM.firstLoad(companyId: company.id)
                        masterDataManager.reloadBuilderView = false
                    } catch {
                        print("Error")
                    }
                }
            }
        })
    }
}

struct RouteManagmentView_Previews: PreviewProvider {
    static let dataService = MockDataService()
    static var previews: some View {
        
        @State var showSignInView: Bool = false
        RouteManagmentView(dataService:dataService)
        
    }
}
extension RouteManagmentView {
    var dayThenTech: some View {
        VStack{
            ForEach(days,id:\.self){ day in
                RouteDayView(dataService:dataService,day: day)
            }
        }
    }
}
