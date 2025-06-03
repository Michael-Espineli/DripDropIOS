//
//  ReassignRouteView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/24/24.
//

import SwiftUI

struct ReassignRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject private var VM : ReassignRouteViewModel

    init(dataService:any ProductionDataServiceProtocol,tech:CompanyUser,day:String,recurringRoute:RecurringRoute){
        _VM = StateObject(wrappedValue: ReassignRouteViewModel(dataService: dataService))
        _tech = State(wrappedValue: tech)
        _day = State(wrappedValue: day)
        _recurringRoute = State(wrappedValue: recurringRoute)
  
    }
    @State var tech:CompanyUser
    @State var day:String
    @State var recurringRoute:RecurringRoute
    

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
                ScrollView{
                    if UIDevice.isIPad{
                        HStack{
                            Spacer()
                            Button(action: {
                                masterDataManager.selectedRouteBuilderTech = nil
                                masterDataManager.selectedRouteBuilderDay = nil
                                dismiss()
                            }, label: {
                                Image(systemName: "xmark")
                            })
                        }
                        .padding()
                    }
                    form
                    button
                }
            
            if VM.isLoading {
                ProgressView()
            }
        }
        .fontDesign(.monospaced)
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert(isPresented:$VM.showChangeConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(VM.alertMessage)"),
                primaryButton: .destructive(Text("Confirm")) {
                    Task{
                        print("Changing Route...")
                        if let company = masterDataManager.currentCompany{
                            do {
                                try await VM.saveChanges(companyId: company.id)
                                masterDataManager.selectedRouteBuilderTech = nil
                                masterDataManager.selectedRouteBuilderDay = nil
                                masterDataManager.reloadBuilderView = true
                            } catch {
                                print("Error")
                                print(error)
                            }
                        } else {
                            print("Attempting to Change Route, but no Company selected")
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .task {
            if let company = masterDataManager.currentCompany {
                VM.receivedTechEntity = tech
                VM.selectedTechEntity = tech
                VM.receivedDay = day
                VM.selectedDay = day
                do {
                    try await VM.onLoad(companyId: company.id)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
    }
}


extension ReassignRouteView {
    var button: some View {
        HStack{
            
            Button(action: {
                VM.confirmChanges()
            }, label: {
                Text("Save Changes")
                    .modifier(SubmitButtonModifier())
            })
            if VM.selectedDay != day || tech != VM.selectedTechEntity {
                Button(action: {
                    VM.selectedDay = VM.receivedDay
                    VM.selectedTechEntity = VM.receivedTechEntity
                }, label: {
                    Text("Discard Changes")
                        .foregroundColor(Color.white)
                        .padding(5)
                        .background(Color.red)
                        .cornerRadius(5)
                        .padding(5)
                })
            }
       
        }
    }
    var form: some View {
        ScrollView{
            Text("Reassign Route View")
                .font(.title)
            technical
            changes
        }
    }
  
    var changes: some View {
        HStack{
            VStack{
                if VM.selectedDay != VM.selectedDay {
                    Text("\(VM.receivedDay) -> \(VM.selectedDay)")
                }
                if VM.receivedTechEntity != VM.selectedTechEntity {
                    Text("\(VM.receivedTechEntity.userName) -> \(VM.selectedTechEntity.userName)")
                }
            }

        }
    }
    var technical: some View {
        VStack{
            Picker("Tech", selection: $VM.selectedTechEntity) {
                    Text("Tech").tag( DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: ""))
                    ForEach(VM.techList){ tech in
                        Text("\(tech.userName)").tag(tech)
                    }
                }
            Picker("Day", selection: $VM.selectedDay) {
                    Text("Day").tag("")
                ForEach(VM.days,id:\.self){ day in
                        Text("\(day)").tag(day)
                    }
                }
            
            DatePicker(selection: $VM.transitionDate, displayedComponents: .date) {
                Text("Transition Date")
            }
            Toggle("Never Ends", isOn: $VM.noEndDate)
            if !VM.noEndDate {
                DatePicker(selection: $VM.endDate, displayedComponents: .date) {
                    Text("New End Date")
                }
            }
        }
        .padding()
    }
}
