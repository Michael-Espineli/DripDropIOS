//
//  AddBodyOfWaterView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//


//
//  AddServiceLocationView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct AddBodyOfWaterView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var serviceLocation:ServiceLocation
    @StateObject var bodyofWaterVM : BodyOfWaterViewModel
    init(dataService:any ProductionDataServiceProtocol,serviceLocation:ServiceLocation){
        _bodyofWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _serviceLocation = State(wrappedValue: serviceLocation)
    }
    
//Body Of Water
    @State var shapes:[String] = ["Square","Rectangle","Kidney","Circular"]

    @State var name:String = "Body 1"
    @State var gallons:String = ""
    @State var material:String = ""
    @State var notes:String = ""
    @State var shape:String = ""
    
    @State var length1:String = ""
    @State var depth1:String = ""
    @State var width1:String = ""
    
    @State var length2:String = ""
    @State var depth2:String = ""
    @State var width2:String = ""
    //Alerts
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    @State var showBodyOfWaterSheet:Bool = false
    
    @State var showTreeSheet:Bool = false
    @State var showBushSheet:Bool = false
    @State var showOtherSheet:Bool = false

    var body: some View {
        VStack{
            ScrollView{
                bodyOfWater
                submitButton
            }
            .padding()
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

extension AddBodyOfWaterView {
    var bodyOfWater: some View {
        VStack{
            HStack{
                Text("Add First Body Of Water")
            }
            VStack{
                HStack{
                    Text("name")
                        .bold(true)
                    TextField(
                        "name",
                        text: $name
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("gallons")
                        .bold(true)
                    TextField(
                        "gallons",
                        text: $gallons
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("Shape")
                        .bold(true)
                    Picker("Shape", selection: $shape) {
                        ForEach(shapes,id: \.self){ shape in
                            Text(shape).tag(shape)
                        }
                    }
                }
                if shape == "Kidney" {
                    VStack{
                        HStack{
                            Text("length 1")
                                .bold(true)
                            TextField(
                                "length 1",
                                text: $length1
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                        }
                        HStack{
                            Text("length 2")
                                .bold(true)
                            TextField(
                                "length 2",
                                text: $length2
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                        }
                        HStack{
                            Text("depth 1")
                                .bold(true)
                            TextField(
                                "depth 1",
                                text: $depth1
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                        }
                        HStack{
                            Text("depth 2")
                                .bold(true)
                            TextField(
                                "depth 2",
                                text: $depth2
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                        }
                        HStack{
                            Text("width 1")
                                .bold(true)
                            TextField(
                                "width 1",
                                text: $width1
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                        }
                        HStack{
                            Text("width 2")
                                .bold(true)
                            TextField(
                                "width 2",
                                text: $width2
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                        }
                        
                    }
                }

                HStack{
                    Text("material")
                        .bold(true)
                    TextField(
                        "material",
                        text: $material
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("notes")
                        .bold(true)
                    TextField(
                        "notes",
                        text: $notes
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
            }

        }
    }
    var submitButton: some View {
        VStack{
           Button(action: {
               Task{
                   do {
                       guard let company = masterDataManager.selectedCompany else {
                           return
                       }
                       
                       try await bodyofWaterVM.addBOWToLocationWithValidation(serviceLocation: serviceLocation,
                                                                              companyId: company.id,
                                                                              name: name,
                                                                              gallons: gallons,
                                                                              material: material,
                                                                              customerId: serviceLocation.customerId,
                                                                              serviceLocationId: serviceLocation.id,
                                                                              notes: notes,
                                                                              shape: shape,
                                                                              length: [length1,length2],
                                                                              depth: [depth1,depth2],
                                                                              width: [width1,width2])
                       alertMessage = "Successfully Updated"
                       print(alertMessage)
                       showAlert = true
                       dismiss()
                   } catch BodyOfWaterError.invalidCustomerId{
                       alertMessage = "Invalid Customer Selected"
                       print(alertMessage)
                       showAlert = true
                   } catch  {
                       alertMessage = "Invalid Something"
                       print(alertMessage)
                       showAlert = true
                   }
               }
           }, label: {
               Text("Submit")
           })
        }
    }
}
