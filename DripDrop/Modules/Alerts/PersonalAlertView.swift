//
//  PersonalAlertView.swift
//  DripDrop
//
//  Created by Michael Espineli on 9/25/24.
//



    import SwiftUI

    struct PersonalAlertView: View {
        init(dataService: any ProductionDataServiceProtocol){
            _VM = StateObject(wrappedValue: PersonalAlertViewModel(dataService: dataService))

        }
        @EnvironmentObject var masterDataManager: MasterDataManager
        @EnvironmentObject var dataService : ProductionDataService

        @StateObject var VM : PersonalAlertViewModel

        var body: some View {
            ZStack{
                Color.listColor.ignoresSafeArea()
                list
            }
            .task {
                if let user = masterDataManager.user {
                    do {
                        try await VM.onLoad(user.id)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }

    #Preview {
        PersonalAlertView(dataService: MockDataService())
    }
    extension PersonalAlertView {
        var list: some View {
            ScrollView{
                Text("New Company Invites")
                    .font(.headline)
                if VM.alerts.isEmpty {
                    Text("No Alerts")
                        .modifier(DismissButtonModifier())
                } else {
                    ForEach(VM.alerts){ alert in
                        Button(action: {
                            
                        }, label: {
                            Text("\(alert.name)")
                                .modifier(ListButtonModifier())
                        })
                        Divider()
                    }
                }
            }
        }
    }
