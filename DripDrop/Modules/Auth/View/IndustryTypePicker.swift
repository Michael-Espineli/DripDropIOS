//
//  IndustryTypePicker.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/14/23.
//

import SwiftUI

struct IndustryTypePicker: View {
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: IndustryTypePickerViewModel(dataService: dataService))
    }
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM:IndustryTypePickerViewModel
    
    //DEVELOPER INCLUDE THIS INTO CREATING THE COMPANY OR MAYBE SETTING UP THE COMPANY AFTER SIGN UP
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                services
                Divider()
                regions
            }
            .padding(8)
        }
        .fontDesign(.monospaced)
        .toolbar{
            ToolbarItem{
                NavigationLink(destination: {
                    SignUpView(dataService:dataService,services: VM.selectedIndustryTypes,serviceZipCodes: VM.selectedZipCodes)//DEVELOPER ADD PAY WALL
                    
                }, label: {
                    Text("Next")
                        .modifier(AddButtonModifier())
                })
                .disabled(VM.selectedIndustryTypes.isEmpty || VM.selectedZipCodes.isEmpty)
                .opacity(VM.selectedIndustryTypes.isEmpty || VM.selectedZipCodes.isEmpty ? 0.6 : 1.0)
            }
        }
        .onChange(of: VM.zipCode, perform: { newValue in
            Task{
                try? await VM.getCityFromZip()
                print(newValue)
            }
        })
    }
}
extension IndustryTypePicker {
    var services:some View {
        VStack{
            HStack{
                Text("Services Offered:")
                    .fontWeight(.bold)
                if VM.selectedIndustryTypes.count == 0 {
                    Text("Pick At Least 1")
                    
                } else {
                    HStack{
                        Text("\(VM.selectedIndustryTypes.count)/1 Selected")
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .foregroundColor(Color.poolGreen)
                }
                Spacer()
            }
            ScrollView(.horizontal,showsIndicators: false) {
                HStack{
                    
                    ForEach(VM.industryTypes,id:\.self) { type in
                        Button(action: {
                            if !VM.selectedIndustryTypes.contains(type) {
                                VM.selectedIndustryTypes.append(type)
                            }
                        }, label: {
                            Text(type)
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                                .background(VM.selectedIndustryTypes.contains(type) ? Color.poolBlue : Color.white)
                                .clipShape(Capsule())
                                .foregroundColor(VM.selectedIndustryTypes.contains(type) ? Color.white : Color.poolBlue)
                        })
                    }
                }
            }
        }
    }
    var regions:some View {
        VStack{
            HStack{
                Text("Regions Serviced:")
                    .fontWeight(.bold)
                if VM.selectedZipCodes.count == 0 {
                    Text("Pick At Least 1")
                    
                } else {
                    HStack{
                        Text("\(VM.selectedZipCodes.count) /1 Selected")
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .foregroundColor(Color.poolGreen)
                }
                Spacer()
            }

                HStack{
                    TextField("Zip Code:", text: $VM.zipCode, prompt: Text("Zip Code"))
                        .modifier(TextFieldModifier())
                    Button(action: {
                        Task{
                            try? await VM.addZipToList()
                        }
                    }, label: {
                        Text("Add")
                            .modifier(AddButtonModifier())
                    })
                    if let placemark = VM.placemark, let address = placemark.postalAddress{
                        Text(" \(address.city)")
                    }
                }
            
                HStack{
                    Text("Selected: ")
                        .fontWeight(.bold)
                    ScrollView(.horizontal,showsIndicators: false) {
                        HStack{
                            
                            ForEach(VM.selectedZipCodes,id:\.self) { zip in
                                HStack{
                                    Text(zip)
                                    
                                    Button(action: {
                                        if VM.selectedZipCodes.contains(zip) {
                                            VM.selectedZipCodes.remove(zip)
                                        } else {
                                            VM.selectedZipCodes.append(zip)
                                        }
                                    }, label: {
                                        Image(systemName: "xmark")
                                    })
                                }
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                                .background(VM.selectedZipCodes.contains(zip) ? Color.poolBlue : Color.white)
                                .clipShape(Capsule())
                                .foregroundColor(VM.selectedZipCodes.contains(zip) ? Color.white : Color.poolBlue)
                            }
                        }
                    }
                }
                HStack{
                    Text("Common: ")
                        .fontWeight(.bold)
                    ScrollView(.horizontal,showsIndicators: false) {
                        HStack{
                            
                            ForEach(VM.commonZipCodes,id:\.self) { zip in
                                HStack{
                                    
                                    Button(action: {
                                        if VM.selectedZipCodes.contains(zip) {
                                            VM.selectedZipCodes.remove(zip)
                                        } else {
                                            VM.selectedZipCodes.append(zip)
                                        }
                                    }, label: {
                                        Text(zip)
                                    })
                                }
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                                .background(VM.selectedZipCodes.contains(zip) ? Color.poolBlue : Color.white)
                                .clipShape(Capsule())
                                .foregroundColor(VM.selectedZipCodes.contains(zip) ? Color.white : Color.poolBlue)
                            }
                        }
                    }
                }
            if let placemark = VM.placemark , let location = placemark.location{
                MiniMapView(coordinates: location.coordinate)
            } else {
                Text("No Mini Map")
            }
        }
    }
}
