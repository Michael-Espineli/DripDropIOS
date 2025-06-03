//
//  EditBodyOfWaterView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class EditBodyOfWaterViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var shapes:[String] = ["Square","Rectangle","Kidney","Circular"]
    @Published var name:String = "Body 1"
    @Published var gallons:String = ""
    @Published var material:String = ""
    @Published var notes:String = ""
    @Published var shape:String = ""
    
    @Published var length1:String = ""
    @Published var depth1:String = ""
    @Published var width1:String = ""
    
    @Published var length2:String = ""
    @Published var depth2:String = ""
    @Published var width2:String = ""
    //Alerts
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = ""
    @Published var showBodyOfWaterSheet:Bool = false
    
    @Published var showTreeSheet:Bool = false
    @Published var showBushSheet:Bool = false
    @Published var showOtherSheet:Bool = false
    func onLoad(companyId:String,bodyOfWater:BodyOfWater) async throws {
        
    }
    func editBOWToLocationWithValidation(companyId: String,bodyOfWater:BodyOfWater) async throws {
        
        let id = UUID().uuidString
        if bodyOfWater.name == name  {
            print("Did not Update Body Of Water Name, it was the same")
        } else {
            try await dataService.editBodyOfWaterName(companyId: companyId, bodyOfWater: bodyOfWater, name: name)
        }
        if bodyOfWater.gallons == gallons  {
            print("Did not Update Body Of Water gallons, it was the same")
        } else {
            try await  dataService.editBodyOfWaterGallons(companyId: companyId, bodyOfWater: bodyOfWater, gallons: gallons)
        }
        if bodyOfWater.material == material  {
            print("Did not Update Body Of Water material, it was the same")
        } else {
            try await  dataService.editBodyOfWaterMaterial(companyId: companyId, bodyOfWater: bodyOfWater, material: material)
        }
        if bodyOfWater.notes == notes  {
            print("Did not Update Body Of Water notes, it was the same")
        } else {
            try  await dataService.editBodyOfWaterNotes(companyId: companyId, bodyOfWater: bodyOfWater, notes: notes)
        }
        if bodyOfWater.shape == shape  {
            print("Did not Update Body Of Water Shape, it was the same")
        } else {
            try  await dataService.editBodyOfWaterShape(companyId: companyId, bodyOfWater: bodyOfWater, shape: shape)
        }
//        if bodyOfWater.length == length  {
//            print("Did not Update Body Of Water length, it was the same")
//        } else {
//            try  await dataService.editBodyOfWaterLength(companyId: companyId, bodyOfWater: bodyOfWater, length: length)
//        }
//        if bodyOfWater.depth == depth  {
//            print("Did not Update Body Of Water Depth, it was the same")
//        } else {
//            try  await dataService.editBodyOfWaterDepth(companyId: companyId, bodyOfWater: bodyOfWater, depth: depth)
//        }
//        if bodyOfWater.width == width  {
//            print("Did not Update Body Of Water Width, it was the same")
//        } else {
//            try  await dataService.editBodyOfWaterWidth(companyId: companyId, bodyOfWater: bodyOfWater, width: width)
//        }
    }
    func delete(companyId:String,bodyOfWaterId:String) async throws {
        try await dataService.deleteBodyOfWater(companyId: companyId, bodyOfWaterId: bodyOfWaterId)
        self.alertMessage = "Successfully Deleted"
        self.showAlert.toggle()
    }
}
struct EditBodyOfWaterView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var bodyOfWater:BodyOfWater
    @StateObject var bodyofWaterVM : BodyOfWaterViewModel
    @StateObject var VM : EditBodyOfWaterViewModel

    init(dataService:any ProductionDataServiceProtocol,bodyOfWater:BodyOfWater){
        _bodyofWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _VM = StateObject(wrappedValue: EditBodyOfWaterViewModel(dataService: dataService))
        _bodyOfWater = State(wrappedValue: bodyOfWater)
    }
//Body Of Water


    var body: some View {
        ScrollView{
            HStack{
                Button(action: {
                    Task{
                        if let currentCompany = masterDataManager.currentCompany {
                            do {
                                try await VM.delete(companyId: currentCompany.id, bodyOfWaterId: bodyOfWater.id)
                                dismiss()
                            } catch {
                                print(error)
                            }
                        }
                    }
                }, label: {
                    Image(systemName: "trash")
                        .foregroundColor(Color.red)
                        .font(.title)
                })
                Spacer()
                submitButton
            }
            bodyOfWaterView
            submitButton
        }
        .padding(8)
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            VM.name = bodyOfWater.name
            VM.gallons = bodyOfWater.gallons
            VM.material = bodyOfWater.material
            VM.notes = bodyOfWater.notes ?? ""
            VM.shape = bodyOfWater.shape ?? ""
            if let lengthArray = bodyOfWater.length {
                if lengthArray.count == 0 {
                } else if lengthArray.count == 1 {
                    VM.length1 = lengthArray[0]
                } else if lengthArray.count == 2 {
                    VM.length1 = lengthArray[0]
                    VM.length2 = lengthArray[1]
                    
                }
            }
            if let depthArray = bodyOfWater.depth {
                if depthArray.count == 0 {
                } else if depthArray.count == 1 {
                    VM.depth1 = depthArray[0]
                } else if depthArray.count == 2 {
                    VM.depth1 = depthArray[0]
                    VM.depth2 = depthArray[1]
                    
                }
            }
            if let widthArray = bodyOfWater.width {
                if widthArray.count == 0 {
                } else if widthArray.count == 1 {
                    VM.width1 = widthArray[0]
                } else if widthArray.count == 2 {
                    VM.width1 = widthArray[0]
                    VM.width2 = widthArray[1]
                }
            }
        }
    }
}

extension EditBodyOfWaterView {
    var bodyOfWaterView: some View {
        VStack{
            HStack{
                Text("Edit")
            }
            VStack{
                HStack{
                    Text("Name")
                        .bold(true)
                    TextField(
                        "name",
                        text: $VM.name
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("Gallons")
                        .bold(true)
                    TextField(
                        "gallons",
                        text: $VM.gallons
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("Shape")
                        .bold(true)
                    Picker("Shape", selection: $VM.shape) {
                        ForEach(VM.shapes,id: \.self){ shape in
                            Text(shape).tag(shape)
                        }
                    }
                }
                HStack{
                    Text("Material")
                        .bold(true)
                    TextField(
                        "material",
                        text: $VM.material
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                if VM.shape == "Kidney" {
                    VStack{
                        HStack{
                            Text("length 1")
                                .bold(true)
                            TextField(
                                "length 1",
                                text: $VM.length1
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
                                text: $VM.length2
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
                                text: $VM.depth1
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
                                text: $VM.depth2
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
                                text: $VM.width1
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
                                text: $VM.width2
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
                        text: $VM.notes
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
                       guard let company = masterDataManager.currentCompany else {
                           return
                       }
                       try await VM.editBOWToLocationWithValidation(companyId: company.id, bodyOfWater: bodyOfWater)

                       VM.alertMessage = "Successfully Updated"
                       print(VM.alertMessage)
                       VM.showAlert = true
                       dismiss()
                   } catch BodyOfWaterError.invalidCustomerId{
                       VM.alertMessage = "Invalid Customer Selected"
                       print(VM.alertMessage)
                       VM.showAlert = true
                   } catch  {
                       VM.alertMessage = "Invalid Something"
                       print(VM.alertMessage)
                       VM.showAlert = true
                   }
               }
           }, label: {
               Text("Submit")
                   .modifier(SubmitButtonModifier())

           })
        }
    }
}
