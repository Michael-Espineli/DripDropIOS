//
//  EditBodyOfWaterView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct EditBodyOfWaterView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var bodyOfWater:BodyOfWater
    @StateObject var bodyofWaterVM : BodyOfWaterViewModel
    
    init(dataService:any ProductionDataServiceProtocol,bodyOfWater:BodyOfWater){
        _bodyofWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _bodyOfWater = State(wrappedValue: bodyOfWater)
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
            HStack{
                Button(action: {

                }, label: {
                    Image(systemName: "trash")
                        .foregroundColor(Color.red)
                        .font(.title)
                })
                Spacer()
                submitButton
            }
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 5, trailing: 10))
            bodyOfWaterView
            submitButton
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            name = bodyOfWater.name
            gallons = bodyOfWater.gallons
            material = bodyOfWater.material
            notes = bodyOfWater.notes ?? ""
            shape = bodyOfWater.shape ?? ""
            if let lengthArray = bodyOfWater.length {
                if lengthArray.count == 0 {
                } else if lengthArray.count == 1 {
                    length1 = lengthArray[0]
                } else if lengthArray.count == 2 {
                    length1 = lengthArray[0]
                    length2 = lengthArray[1]
                    
                }
            }
            if let depthArray = bodyOfWater.depth {
                if depthArray.count == 0 {
                } else if depthArray.count == 1 {
                    depth1 = depthArray[0]
                } else if depthArray.count == 2 {
                    depth1 = depthArray[0]
                    depth2 = depthArray[1]
                    
                }
            }
            if let widthArray = bodyOfWater.width {
                if widthArray.count == 0 {
                } else if widthArray.count == 1 {
                    width1 = widthArray[0]
                } else if widthArray.count == 2 {
                    width1 = widthArray[0]
                    width2 = widthArray[1]
                    
                }
            }
        }
    }
}

extension EditBodyOfWaterView {
    var bodyOfWaterView: some View {
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
                       try await bodyofWaterVM.editBOWToLocationWithValidation(companyId: company.id, bodyOfWater: bodyOfWater, bodyOfWaterId: bodyOfWater.id, name: name, gallons: gallons, material: material, notes: notes, shape: shape, length: [length1,length2], depth: [depth1,depth2], width: [width1,width2])

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
