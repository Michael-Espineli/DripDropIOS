//
//  RouteManagmentView2.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/7/26.
//

import SwiftUI
struct RouteManagmentView2: View {

    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @EnvironmentObject var VM: RouteBoardViewModel

    init(dataService: any ProductionDataServiceProtocol) {

    }

    private let days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack {
                    if VM.isInitialLoading {
                        ProgressView("Loading Routes")
                    } else {
                        dayThenTech
                    }
                }
                .padding(.horizontal, 8)
            }
	            Text("")
	                .confirmationDialog("Select Type", isPresented: self.$VM.editRoute, actions: {
	                    Button(action: {
	                        VM.prepareAssignment(mode: .route)
	                    }, label: {
	                        Text("Assign Whole Route")
	                    })
	                    Button(action: {
	                        VM.prepareAssignment(mode: .merge)
	                    }, label: {
	                        Text("Merge Into Route")
	                    })
	                    Button(action: {
	                            VM.showModifyRoute = true
                    }, label: {
                        Text("Edit")
                    })
                    Button(action: {
                        VM.alertMessage = "Confirm Delete Recurring Route"
                        VM.showDelete.toggle()
                    }, label: {
                        Text("Delete")
                    })
                    .disabled(VM.isLoading)
                    .opacity(VM.isLoading ? 0.7 : 1)
                })
                .sheet(isPresented: $VM.showModifyRoute, onDismiss: {
                    print("done")
                    
                    VM.selectedDay = nil
                    VM.selectedTech = nil
                    VM.selectedRoute = nil
                }, content: {
                    ZStack{
                        Color.listColor.ignoresSafeArea()
                        if let selectedRoute = VM.selectedRoute, let tech = VM.selectedTech, let day = VM.selectedDay {
//                            ModifyRecurringRoute(dataService: dataService, tech: tech, day: day, recurringRoute: selectedRoute)
                            NewRouteView(dataService: dataService, tech: tech, day: day)

	                        }
	                    }
	                })
	                .sheet(isPresented: $VM.showAssignmentSheet, onDismiss: {
	                    VM.resetAssignmentState(clearSelections: true)
	                }, content: {
	                    PlannedRouteAssignmentSheet()
	                })
	            Text("")
	                .confirmationDialog("Select Type", isPresented: self.$VM.editRecurringServiceStop, actions: {
	                    Button(action: {
	                        VM.prepareAssignment(mode: .stop)
	                    }, label: {
	                        Text("Assign RSS")
	                    })
	                    Button(action: {
	                        print("Edit Recurring Service Stop")
	                        VM.showModifyRSS.toggle()
                    
                    }, label: {
                        Text("Edit")
                    })
                    
                    Button(action: {
                        print("Delete Recurring Service Stop")
                        VM.alertMessage = "Confirm Delete Recurring Service Stop"
                        VM.showDeleteRSS.toggle()
                    }, label: {
                        Text("Delete")
                    })
                    .disabled(VM.isLoading)
                    .opacity(VM.isLoading ? 0.7 : 1)
                })
                .sheet(isPresented: $VM.showModifyRSS, onDismiss: {
                    print("done")
                    
                    VM.selectedDay = nil
                    VM.selectedTech = nil
                    VM.selectedRecurringServiceStop = nil
                }, content: {
                    ZStack{
                        Color.listColor.ignoresSafeArea()
                        Text("Edit Recurring Route")
                    }
                })
        }
        .navigationTitle("Routes")
        
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        //For Deleting Route
        .alert(isPresented:$VM.showDelete) {
            Alert(
                title: Text("Alert"),
                message: Text("\(VM.alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    VM.deleteRecurringRoute(companyId: masterDataManager.currentCompany?.id)
                },
                secondaryButton: .cancel()
            )
        }
            //For Deleting Recurring Service stop
        .alert(isPresented:$VM.showDeleteRSS) {
            Alert(
                title: Text("Alert"),
                message: Text("\(VM.alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    VM.deleteRecurringServiceStop(companyId: masterDataManager.currentCompany?.id)
                },
                secondaryButton: .cancel()
            )
        }
        // Start listeners once
        .task(id: masterDataManager.currentCompany?.id) {
            guard let companyId = masterDataManager.currentCompany?.id else { return }
            VM.start(companyId: companyId)
        }

        // Stop listeners when leaving screen
        .onDisappear {
            VM.stopListeners()
        }

        .refreshable {
            VM.forceRecompute(companyId: masterDataManager.currentCompany?.id)
	}
}

private struct PlannedRouteAssignmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var VM: RouteBoardViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Selection") {
                    Text(VM.assignmentCurrentSummary)
                    Text("\(VM.assignmentStopCount) RSS record\(VM.assignmentStopCount == 1 ? "" : "s")")
                        .foregroundColor(.secondary)
                }

                if VM.assignmentMode == .merge {
                    Section("Destination Route") {
                        Picker("Route", selection: $VM.assignmentDestinationRouteId) {
                            if VM.assignmentDestinationRoutes.isEmpty {
                                Text("No other routes").tag("")
                            }
                            ForEach(VM.assignmentDestinationRoutes) { route in
                                Text(VM.destinationRouteLabel(route)).tag(route.id)
                            }
                        }
                    }
                } else {
                    Section("Assignment") {
                        Picker("Day", selection: $VM.assignmentDay) {
                            ForEach(DaysOfWeek.allCases, id: \.self) { day in
                                Text(day.rawValue).tag(day)
                            }
                        }
                        Picker("Technician", selection: $VM.assignmentTechId) {
                            Text("Technician").tag("")
                            ForEach(VM.assignmentTechOptions) { tech in
                                Text(tech.userName).tag(tech.userId.isEmpty ? tech.id : tech.userId)
                            }
                        }
                    }
                }

                Section {
                    Button(action: {
                        Task {
                            let saved = await VM.savePlannedRouteAssignment(
                                companyId: masterDataManager.currentCompany?.id
                            )
                            if saved {
                                dismiss()
                            }
                        }
                    }, label: {
                        HStack {
                            Spacer()
                            if VM.isLoading {
                                ProgressView()
                            } else {
                                Text(VM.assignmentMode.saveTitle)
                            }
                            Spacer()
                        }
                    })
                    .disabled(VM.isLoading || !VM.assignmentCanSave)
                }
            }
            .navigationTitle(VM.assignmentMode.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
}
extension RouteManagmentView2 {

    var dayThenTech: some View {
        VStack {
            ForEach(DaysOfWeek.allCases, id: \.self) { day in
                RouteDayView(day: day)
            }
        }
    }
}
