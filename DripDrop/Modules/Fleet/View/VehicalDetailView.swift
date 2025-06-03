//
//  FleetDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import SwiftUI

@MainActor
final class VehicalDetailViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var routes: [ActiveRoute] = []
    
    func onLoad(companyId:String,vehicalId:String) async throws {
        self.routes = try await dataService.getAllActiveRoutesBasedOnVehical(companyId: companyId, vehicalId: vehicalId, count: 5)
        //Maybe Give Summary // Maybe get vehical summary based on dates
    }
}
struct VehicalDetailView: View {
    
        @Environment(\.locale) private var locale

    //Init
    init(dataService:any ProductionDataServiceProtocol,vehical:Vehical){
        _vehical = State(initialValue: vehical)
        _VM = StateObject(wrappedValue: VehicalDetailViewModel(dataService: dataService))
    }
    
    //Enviromental
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : VehicalDetailViewModel

    //Received
    @State var vehical : Vehical? = nil
    //Variables
    @State var showSheet:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                info
                Rectangle()
                    .frame(height: 1)
                details
            }
            Text("")
                .sheet(isPresented: $showSheet, onDismiss: {
                    
                }, content: {
                    if let vehical {
                        EditVehicalView(dataService: dataService, vehical: vehical)
                    }
                })
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany, let vehical {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, vehicalId: vehical.id)
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: masterDataManager.selectedVehical, perform: { datum in
            vehical = datum
        })
        .toolbar{
            ToolbarItem(content: {
                Button(action: {
                    showSheet.toggle()
                }, label: {
                    Text("Edit")
                })
            })
        }
    }
}

//struct FleetDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        VehicalDetailView()
//    }
//}

extension VehicalDetailView {
    var info: some View {
        VStack{
            if let vehical {
                HStack{
                    Text("Nick Name: \(vehical.nickName)")
                    Spacer()
                }
                HStack{
                    Text("\(vehical.color)")
                    Spacer()
                }
                HStack{
                    Text("Make: \(vehical.make)")
                    Spacer()
                }
                HStack{
                    Text("Model: \(vehical.model)")
                    Spacer()
                }
                HStack{
                    Text("Miles: \(Measurement(value: Double(vehical.miles), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)))")
                    Spacer()
                }
                HStack{
                    Text("Date Purchased\(fullDate(date:vehical.datePurchased))")
                    Spacer()
                }
            }
        }
        .padding(.horizontal,8)
        .background(Color.darkGray)
        .foregroundColor(Color.poolWhite)
        .fontDesign(.monospaced)
    }
    var details: some View {
        VStack{
            Text("Recent Trips")
            ForEach(VM.routes) { route in
                HStack{
                    if let start = route.startMilage, let end = route.endMilage{
                        Text("Miles: \(Measurement(value: Double(start), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))) - \(Measurement(value: Double(end), unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))) (\(Measurement(value: route.distanceMiles, unit: UnitLength.miles).formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))))")

                    }
                }
                .modifier(ListButtonModifier())
                .padding(8)
                
            }
        }
    }
}
