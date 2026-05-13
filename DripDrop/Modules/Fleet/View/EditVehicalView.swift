//
//  EditVehicalView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import SwiftUI

@MainActor
final class EditVehicalViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    let vehical: Vehical

    init(dataService:any ProductionDataServiceProtocol, vehical: Vehical){
        self.dataService = dataService
        self.vehical = vehical
    }
    @Published private(set) var selectedTerms: [ContractTerms] = []
    @Published var editableTerms: [ContractTerms] = []
        
    @Published var name: String = ""
    @Published var vehicalType: VehicalType = .car
    @Published var year: String = ""
    @Published var make: String = ""
    @Published var model: String = ""
    @Published var color: String = ""
    @Published var plate: String = ""
    @Published var datePurchased: Date = Date()
    @Published var miles: String = "0"
    @Published var status: VehicalStatus = .active

    func onLoad(companyId:String?) {
        Task{
            do {
                if let companyId {
                    self.name = vehical.nickName
                    self.vehicalType = vehical.vehicalType
                    self.make = vehical.make
                    self.model = vehical.model
                    self.color = vehical.color
                    self.plate = vehical.plate
                    self.datePurchased = vehical.datePurchased
                    self.miles = String(vehical.miles)
                    self.status = vehical.status
                }
            } catch {
                print("[][] Error: \(error)")
            }
        }
    }
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func saveChanges(companyId: String?) {
        guard let companyId else {return}
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard let doubleMiles = Double(miles) else {return}

        Task {
            do {
                //Update Template Object
                let newVehicle = Vehical(id: vehical.id,
                                         nickName: trimmedName,
                                         vehicalType: vehicalType,
                                         year: year,
                                         make: make,
                                         model: model,
                                         color: color,
                                         plate: plate,
                                         datePurchased: datePurchased,
                                         miles: doubleMiles,
                                         status: status)
                try await dataService.updateVehical(companyId: companyId, vehicle: vehical, newVehical: newVehicle)


            } catch {
                // You can add error handling UI here if desired
                print("[EditTermsTemplateViewModel][saveChanges]Failed to update terms template: \(error)")
            }
        }
    }
}

struct EditVehicalView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @Environment(\.dismiss) private var dismiss

    init(dataService:any ProductionDataServiceProtocol,vehical:Vehical){
        _VM = StateObject(wrappedValue: EditVehicalViewModel(dataService: dataService,vehical: vehical))

        _vehical = State(initialValue: vehical)
    }
    @StateObject var VM: EditVehicalViewModel

    //Received
    @State var vehical : Vehical? = nil
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                HStack{
                    Button("Cancel") { dismiss() }
                    Spacer()
                    Button("Save") {
                        VM.saveChanges(companyId: masterDataManager.currentCompany?.id)
                        dismiss()
                    }
                        .disabled(!VM.canSave)
                }
                .padding(.top,20)
                Form {
                    Section(header: Text("Vehical")) {
                        TextField("Name", text: $VM.name)
                            .textInputAutocapitalization(.words)
                        Picker("", selection: $VM.vehicalType) {
                            ForEach(VehicalType.allCases,id:\.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        DatePicker("Purchase Date:", selection: $VM.datePurchased, in: ...Date(),displayedComponents: .date)
                        Picker("", selection: $VM.status) {
                            ForEach(VehicalStatus.allCases,id:\.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                    }
                    
                    Section(header: Text("Descriptions")) {
                        TextField("year", text: $VM.year)
                            .textInputAutocapitalization(.words)
                        TextField("make", text: $VM.make)
                            .textInputAutocapitalization(.words)
                        TextField("model", text: $VM.model)
                            .textInputAutocapitalization(.words)
                        TextField("color", text: $VM.color)
                            .textInputAutocapitalization(.words)
                        TextField("plate", text: $VM.plate)
                            .textInputAutocapitalization(.words)
                    }
                    Section(header: Text("Statistics")) {
                        MilesField("Distance", text: $VM.miles)
                    }
                }
            }
        }
        .onAppear(perform: {
            VM.onLoad(companyId: masterDataManager.currentCompany?.id)
        })
    }
}

