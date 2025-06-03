//
//  AddNewVehical.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import SwiftUI

struct AddNewVehical: View {
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject var VM : FleetViewModel

    init(dataService:ProductionDataService){
        _VM = StateObject(wrappedValue: FleetViewModel(dataService: dataService))
    }
    @FocusState private var focusedField: NewVehicalFormLabels?
//Form
    @State var nickName:String = ""
    @State var vehicalType:VehicalType = .truck
    @State var year:String = ""
    @State var make:String = ""
    @State var model:String = ""
    @State var color:String = ""
    @State var plate:String = ""
    @State var datePurchased:Date = Date()
    @State var miles:String = "0"
    @State var status:VehicalStatus = .active

    //Alert
    @State var alertMessage:String = ""
    @State var showAlert:Bool = false

    var body: some View {
        ZStack{
            ScrollView{
                form
                submitButton
            }
            .padding(8)
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

//#Preview {
//    AddNewVehical()
//}
extension AddNewVehical {
    var form: some View {
        VStack{
            HStack{
                Text("Nick Name:")
                TextField(
                    "Nick Name",
                    text: $nickName
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                .focused($focusedField, equals: .nickName)
                     .submitLabel(.next)
                Spacer()
            }
   
            Picker("", selection: $vehicalType, content: {
                Text("Car").tag(VehicalType.car)
                Text("Truck").tag(VehicalType.truck)
                Text("Van").tag(VehicalType.van)

            })
            .pickerStyle(.segmented)
            HStack{
                Text("Year:")
                TextField(
                    "Year",
                    text: $year
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                .focused($focusedField, equals: .year)
                     .submitLabel(.next)
                Spacer()
            }
            HStack{
                Text("Make:")
                TextField(
                    "Make",
                    text: $make
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                .focused($focusedField, equals: .make)
                     .submitLabel(.next)
                Spacer()
            }
            HStack{
                Text("Model:")
                TextField(
                    "Model",
                    text: $model
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                .focused($focusedField, equals: .model)
                     .submitLabel(.next)
                Spacer()
            }
            HStack{
                Text("Color:")
                TextField(
                    "Color",
                    text: $color
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                .focused($focusedField, equals: .color)
                     .submitLabel(.next)
                Spacer()
            }
            HStack{
                Text("Plate:")
                TextField(
                    "Plate",
                    text: $plate
                )
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                .focused($focusedField, equals: .plate)
                     .submitLabel(.next)
                Spacer()
            }
            HStack{
                Text("Miles:")
                TextField(
                    "Miles",
                    text: $miles
                )
                .keyboardType(.decimalPad)
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                .focused($focusedField, equals: .miles)
                     .submitLabel(.next)
                Spacer()
            }
            DatePicker("Purchase Date:", selection: $datePurchased, in: ...Date(),displayedComponents: .date)
            Picker("", selection: $status, content: {
                Text("Active").tag(VehicalStatus.active)
                Text("Retired").tag(VehicalStatus.retired)
            })
            .pickerStyle(.segmented)
        }
        .onSubmit {
               switch focusedField {
               case .nickName:
                   focusedField = .year

               case .year:
                   focusedField = .make

               case .make:
                   focusedField = .model

               case .model:
                   focusedField = .color

               case .color:
                   focusedField = .plate

               case .plate:
                   focusedField = .miles
               case .miles:
                   focusedField = nil
               default:
                   focusedField = nil

               }
           }
    }
    var submitButton: some View {
        Button(action: {
            Task{
                guard let milesNum = Double(miles) else {
                    alertMessage = "miles are not a number"
                    print(alertMessage)
                    showAlert = true
                    return
                }
                if let selectedCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.addNewVehical(
                            companyId:selectedCompany.id,
                            vehical:Vehical(
                                id: UUID().uuidString,
                                nickName: nickName,
                                vehicalType: vehicalType,
                                year: year,
                                make: make,
                                model: model,
                                color: color,
                                plate: plate,
                                datePurchased: datePurchased,
                                miles: milesNum,
                                status: status
                            )
                        )
                        alertMessage = "Successfully Added"
                        print(alertMessage)
                        showAlert = true
                        nickName = ""
                        vehicalType = .truck
                        year = ""
                        make = ""
                        model = ""
                        color = ""
                        plate = ""
                        miles = "0"
                        datePurchased = Date()
                    } catch {
                        alertMessage = "Failed"
                        print(alertMessage)
                        showAlert = true
                        print(error)
                    }
                }
            }
        },
               label: {
            Text("Submit")
                .modifier(SubmitButtonModifier())
        })
    }
}
