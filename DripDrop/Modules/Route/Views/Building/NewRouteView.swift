//
//  NewRouteView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//
//Designed to be a sheet Or FullScreen Cover Page
import SwiftUI

struct NewRouteView: View {
    init(dataService:any ProductionDataServiceProtocol,tech: CompanyUser,day: DaysOfWeek){
//        _VM = StateObject(wrappedValue: NewRouteViewModel(dataService: dataService))
        _tech = State(wrappedValue: tech)
        _day = State(wrappedValue: day)
    }
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var routeBoardVM: RouteBoardViewModel

//    @StateObject var VM : NewRouteViewModel
    
    @State var tech: CompanyUser
    @State var day: DaysOfWeek
    
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("New Route")
                                .font(.title3.weight(.semibold))
                            Text("\(day.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    form

                    // Add some space so the bottom button bar doesn’t cover content
                    Color.clear.frame(height: 70)
                }
                .padding(12)
            }

            VStack {
                Spacer()
                button
            }

            if routeBoardVM.isLoading {
                loadingOverlay
            }
        }
        .foregroundColor(Color.basicFontText)
        
        .alert(routeBoardVM.alertMessage, isPresented: $routeBoardVM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear(perform: {
            print("[NewRouteView][onAppear]")
            routeBoardVM.onLoad(day: day)
        })
        .onChange(of: routeBoardVM.selectedTech, perform: { tech in
            print("[NewRouteView][onChange][routeBoardVM.selectedTech]")
            if let tech {
                routeBoardVM.checkForRouteOnDayAndTech(techId: tech.userId, day: day)
            }
        })
        .onChange(of: routeBoardVM.selectedDay, perform: { datum in
            print("[NewRouteView][onChange][routeBoardVM.selectedDay]")
            if let tech = routeBoardVM.selectedTech, let datum {
                routeBoardVM.checkForRouteOnDayAndTech(techId: tech.userId, day: datum)
                
            }
        })
    }
}


extension NewRouteView {
    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.12).ignoresSafeArea()
            VStack(spacing: 10) {
                ProgressView()
                Text("Loading…")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .ddCard()
            .padding(24)
        }
    }

    var button: some View {
        HStack {
            Button(action: {
                routeBoardVM.submitOrUpdateRoute(companyId: masterDataManager.currentCompany?.id)
            }, label: {
                Text((routeBoardVM.currentSelectedRoute == nil && routeBoardVM.currentRouteRecurringStops.isEmpty) ? "Submit" : "Update")
                    .frame(maxWidth: .infinity)
                    .modifier(SubmitButtonModifier())
            })
            .disabled(routeBoardVM.isLoading)
            .opacity(routeBoardVM.isLoading ? 0.6 : 1)
        }
        .ddBottomBar()
    }

    var form: some View {
        VStack(spacing: 12) {
            technical.ddCard()
            info.ddCard()
        }
    }

    var info: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recurring Stops").ddSectionHeader()
                Spacer()
                if !routeBoardVM.newRouteRecurringStops.isEmpty {
                    Text("\(routeBoardVM.newRouteRecurringStops.count)")
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                }
            }

            HStack(spacing: 10) {
                Button(action: {
                    routeBoardVM.showCustomerPicker.toggle()
                }, label: {
                    Text(routeBoardVM.newRouteRecurringStops.isEmpty ? "Add First Customer" : "Add Another")
                        .modifier(BlueButtonModifier())
                })
                .sheet(isPresented: $routeBoardVM.showCustomerPicker, onDismiss: {
                    routeBoardVM.onDismissOfCustomerPicker()
                }, content: {
                    CustomerAndLocationPicker(dataService: dataService, customer: $routeBoardVM.customer, location: $routeBoardVM.location)
                })

                if !routeBoardVM.newRouteRecurringStops.isEmpty {
                    Button(action: {
                        routeBoardVM.showCustomerSheet.toggle()
                    }, label: {
                        Text("View List")
                            .modifier(BlueButtonModifier())
                    })
                    .sheet(isPresented: $routeBoardVM.showCustomerSheet) {
                        VStack {
                            HStack {
                                Text("Customers")
                                    .font(.headline.weight(.semibold))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                            List {
                                ForEach(routeBoardVM.newRouteRecurringStops) { location in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(location.customerName)")
                                                .font(.subheadline.weight(.semibold))
                                            Text("\(location.address.streetAddress)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(location.frequency.rawValue)
                                            .font(.caption.weight(.semibold))
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(Capsule().fill(Color.primary.opacity(0.08)))
                                    }
                                    .padding(.vertical, 4)
                                }
                                .onDelete(perform: routeBoardVM.removeRecurringstops)
                            }
                        }
                        .presentationDetents([.medium, .large])
                    }
                }

                Spacer()
            }

            if routeBoardVM.newRouteRecurringStops.isEmpty {
                Text("Add at least one customer/location to build the route.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var technical: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Settings").ddSectionHeader()

            DatePicker(selection: $routeBoardVM.startDate, displayedComponents: .date) {
                Text("Start Date")
                    .foregroundStyle(.secondary)
            }

            Toggle("Never Ends", isOn: $routeBoardVM.noEndDate)

            if !routeBoardVM.noEndDate {
                DatePicker(selection: $routeBoardVM.endDate, displayedComponents: .date) {
                    Text("End Date")
                        .foregroundStyle(.secondary)
                }
            }

            Text("Description")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Description", text: $routeBoardVM.description)
                .modifier(TextFieldModifier())

            Divider().opacity(0.15)

            VStack(alignment: .leading, spacing: 10) {
                Text("Assignment").ddSectionHeader()

                Picker("Tech", selection: $routeBoardVM.newSelectedTech) {
                    Text("Tech")
                        .tag(CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .contractor))
                    ForEach(routeBoardVM.companyUsers) { tech in
                        Text("\(tech.userName)").tag(tech)
                    }
                }
                .pickerStyle(.menu)

                Picker("Day", selection: $routeBoardVM.newSelectedDay) {
                    ForEach(DaysOfWeek.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.menu)

                Picker("Frequency", selection: $routeBoardVM.standardFrequencyType) {
                    ForEach(LaborContractFrequency.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    
}

private extension View {
    func ddCard() -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
    }

    func ddSectionHeader() -> some View {
        self
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    func ddBottomBar() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Color.black.opacity(0.02)
                }
                .ignoresSafeArea(edges: .bottom)
            )
            .overlay(Divider().opacity(0.12), alignment: .top)
    }
}
