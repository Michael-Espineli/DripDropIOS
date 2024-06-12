//
//  ServiceLocationStartUpView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/15/24.
//

import SwiftUI

struct ServiceLocationStartUpView: View {
    init(dataService: any ProductionDataServiceProtocol,serviceLocation:ServiceLocation) {
        _serviceLocation = State(wrappedValue: serviceLocation)
    }
    @State var serviceLocation: ServiceLocation
    @State var selectedBOW:BodyOfWater = BodyOfWater(
        id: UUID().uuidString,
        name: "Main Pool",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        notes: "",
        shape: "",
        length: [],
        depth: [],
        width: []
    )
    @State var bodyOfWaterList:[BodyOfWater] = []
    @State var material:BodyOfWaterMaterial = .plaster
    @State var gallons:String = "0"
    @State var shape:String = ""
    @State var showDimensions:Bool = false
    @State var shapes:[String] = ["Square","Rectangle","Kidney","Circular"]
    @State var length1:String = ""
    @State var depth1:String = ""
    @State var width1:String = ""
    
    @State var length2:String = ""
    @State var depth2:String = ""
    @State var width2:String = ""
    
    //Equipment
    @State var equipmentList:[Equipment] = []
    @State var selectedEquipment:Equipment = Equipment(id: "", name: "Main Pump", category: .pump, make: "", model: "", dateInstalled: Date(), status: .operational, needsService: false, cleanFilterPressure: 15, currentPressure: 20, lastServiceDate: Date(), serviceFrequency: "", serviceFrequencyEvery: "", nextServiceDate: Date(), notes: "", customerName: "", customerId: "", serviceLocationId: "", bodyOfWaterId: "")
    @State var name:String = ""

    @State var make:String = ""
    @State var model:String = ""
    @State var dateInstalled:Date = Date()
    @State var status:EquipmentStatus = .operational
    @State var notes:String = ""
    
    @State var needsService:Bool = false
    @State var lastServiced:Date = Date()
    @State var lastServicedOptional:Date? = Date()

    @State var serviceFrequency:String? = ""
    @State var serviceFrequencyEvery:String? = ""
   //Photos
    @State var showPhotoSelectionOptions:Bool = false
    @State var pickerType:photoPickerType? = nil
    @State var selectedNewPicker:photoPickerType? = nil
    @State var selectedImage:UIImage? = nil
    @State var images:[UIImage] = []
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        VStack{
                            serviceLocationStartUp
                            bodyOfWaterStartUp
                            equipmentStartUp
                        }
                            .padding(.horizontal,16)

                    }, header: {
                        bodyOfWaterPicker
                    })
                })
                .padding(.top,16)
                .clipped()
            }
        }
        .onAppear(perform: {
            bodyOfWaterList.append(selectedBOW)
            equipmentList.append(
                contentsOf: [
                    Equipment(
                        id: UUID().uuidString,
                        name: "Main Pump",
                        category: .pump,
                        make: "",
                        model: "",
                        dateInstalled: Date(),
                        status: .operational,
                        needsService: false,
                        cleanFilterPressure: 15,
                        currentPressure: 20,
                        lastServiceDate: Date(),
                        serviceFrequency: "",
                        serviceFrequencyEvery: "",
                        nextServiceDate: Date(),
                        notes: "",
                        customerName: "",
                        customerId: "",
                        serviceLocationId: "",
                        bodyOfWaterId: ""
                    ),
                    Equipment(
                        id: UUID().uuidString,
                        name: "Main Filter",
                        category: .filter,
                        make: "",
                        model: "",
                        dateInstalled: Date(),
                        status: .operational,
                        needsService: false,
                        cleanFilterPressure: 15,
                        currentPressure: 20,
                        lastServiceDate: Date(),
                        serviceFrequency: "",
                        serviceFrequencyEvery: "",
                        nextServiceDate: Date(),
                        notes: "",
                        customerName: "",
                        customerId: "",
                        serviceLocationId: "",
                        bodyOfWaterId: ""
                    )
                ]
            )
        })
        .onChange(of: gallons, perform: { gallon in
            if gallon  != "" && !gallon.isNumber {
                    gallons.removeLast()
                }
            
        })
    }
}

#Preview {
    ServiceLocationStartUpView(dataService: MockDataService(), serviceLocation: MockDataService.mockServiceLocation)
}
extension ServiceLocationStartUpView {
    var serviceLocationStartUp: some View {
        VStack{
            Text("Service Location Start Up")
        }
    }
    var bodyOfWaterPicker: some View {
        ScrollView(.horizontal){
            HStack(spacing:16){
                Button(action: {
                    
                }, label: {
                    ZStack{
                        Image(systemName: "plus.app.fill")
                            .font(.title)
                            .foregroundColor(Color.poolBlue)
                        Image(systemName: "plus.app")
                            .font(.title)
                            .foregroundColor(Color.poolWhite)
                    }
                })
                ForEach(bodyOfWaterList){ BOW in
                    Button(action: {
                        selectedBOW = BOW
                    }, label: {
                        Text("\(BOW.name)")
                            .padding(8)
                            .background(selectedBOW == BOW ? Color.poolBlue : Color.darkGray)
                            .foregroundColor(Color.white)
                            .cornerRadius(8)
                    })
                    
                }
            }
        }
    }
    var bodyOfWaterStartUp: some View {
        VStack{
            ScrollView(.horizontal, showsIndicators: false) {
                HStack{
                    VStack{
                        Button(action: {
                            showPhotoSelectionOptions.toggle()
                        }, label: {
                            ZStack{
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.poolGreen)
                            }
                            
                        })
                        .confirmationDialog("Select Type", isPresented: self.$showPhotoSelectionOptions, actions: {
                            Button(action: {
                                self.pickerType = .album
                                self.selectedNewPicker = .album
                            }, label: {
                                Text("Album")
                            })
                            Button(action: {
                                self.pickerType = .camera
                                self.selectedNewPicker = .camera
                                
                            }, label: {
                                Text("Camera")
                            })
                            
                        })
                        .sheet(item: self.$pickerType,onDismiss: {
                            
                        }){ item in
                            switch item {
                            case .album:
                                NavigationView{
                                    VStack{
                                        HStack{
                                            Spacer()
                                            Button(action: {
                                                pickerType = nil
                                            }, label: {
                                                Text("Done")
                                            })
                                            .padding(16)
                                        }
                                        ImagePicker(image: self.$selectedImage)
                                    }
                                }
                            case .camera:
                                NavigationView{
                                    accessCameraView(selectedImage: self.$selectedImage)
                                }
                            }
                            
                        }
                    }
                    if images.isEmpty {
                        if let selectedImage{
                            Image(uiImage: selectedImage)
                                .resizable()
                                .frame(width: 100)
                                .scaledToFit()
                        } else {
                            Button(action: {
                                showPhotoSelectionOptions = true
                                print("add New Photo")
                            }, label: {
                                Image(systemName: "photo.fill")
                                    .resizable()
                                    .frame(width: 100)
                                    .scaledToFit()
                                
                                    .foregroundColor(Color.blue)
                            })
                        }
                    } else {
                        ForEach(images,id:\.self){image in
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 100)
                                    .scaledToFit()
                        }
                    }
                }
                .frame(height: 100)
            }
            Picker("Pool Material", selection: $material, content: {
                ForEach(BodyOfWaterMaterial.allCases,id:\.self){ material in
                    Text(material.rawValue).tag(material)
                }
            })
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
                Text("Gallons: ")
                TextField("Gallons", text: $gallons, prompt: Text("Gallons"), axis: .vertical)
                Button(action: {
                    showDimensions.toggle()
                }, label: {
                    Text("Add Dimensions")
                })
            }
            if showDimensions {
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
            }

        }
    }
    var equipmentStartUp: some View {
        VStack{
            Text("Equipment Start Up")
            Rectangle()
                .frame(height: 4)
            filterStartUp
            pumpStartUp
            heaterStartUp
            controlSystemStartUp

            cleanerStartUp
            autoClorinatorsStartUp
        }
    }
    var filterStartUp: some View {
        VStack{
            Text("Filter")
            Rectangle()
                .frame(height: 1)
            ScrollView(.horizontal){
                HStack{
                    Button(action: {
                        
                    }, label: {
                        ZStack{
                            Image(systemName: "plus.app.fill")
                                .font(.title)
                                .foregroundColor(Color.poolBlue)
                            Image(systemName: "plus.app")
                                .font(.title)
                                .foregroundColor(Color.poolWhite)
                        }
                    })
                    ForEach(equipmentList.filter({$0.category == .filter})) { filter in
                        Button(action: {
                            selectedEquipment = filter
                        }, label: {
                            Text("\(filter.name)")
                                .padding(8)
                                .background(selectedEquipment == filter ? Color.poolBlue : Color.darkGray)
                                .foregroundColor(Color.white)
                                .cornerRadius(8)
                        })
                    }
                }
            }
            //Detail View
            if selectedEquipment.category == .filter {
                    VStack{
                        Text("Detail")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack{
                                VStack{
                                    Button(action: {
                                        showPhotoSelectionOptions.toggle()
                                    }, label: {
                                        ZStack{
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 50, height: 50)
                                            Image(systemName: "plus.circle.fill")
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(Color.poolGreen)
                                        }
                                        
                                    })
                                    .confirmationDialog("Select Type", isPresented: self.$showPhotoSelectionOptions, actions: {
                                        Button(action: {
                                            self.pickerType = .album
                                            self.selectedNewPicker = .album
                                        }, label: {
                                            Text("Album")
                                        })
                                        Button(action: {
                                            self.pickerType = .camera
                                            self.selectedNewPicker = .camera
                                            
                                        }, label: {
                                            Text("Camera")
                                        })
                                        
                                    })
                                    .sheet(item: self.$pickerType,onDismiss: {
                                        
                                    }){ item in
                                        switch item {
                                        case .album:
                                            NavigationView{
                                                VStack{
                                                    HStack{
                                                        Spacer()
                                                        Button(action: {
                                                            pickerType = nil
                                                        }, label: {
                                                            Text("Done")
                                                        })
                                                        .padding(16)
                                                    }
                                                    ImagePicker(image: self.$selectedImage)
                                                }
                                            }
                                        case .camera:
                                            NavigationView{
                                                accessCameraView(selectedImage: self.$selectedImage)
                                            }
                                        }
                                        
                                    }
                                }
                                if images.isEmpty {
                                    if let selectedImage{
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .frame(width: 100)
                                            .scaledToFit()
                                    } else {
                                        Button(action: {
                                            showPhotoSelectionOptions = true
                                            print("add New Photo")
                                        }, label: {
                                            Image(systemName: "photo.fill")
                                                .resizable()
                                                .frame(width: 100)
                                                .scaledToFit()
                                            
                                                .foregroundColor(Color.blue)
                                        })
                                    }
                                } else {
                                    ForEach(images,id:\.self){image in
                                            Image(uiImage: image)
                                                .resizable()
                                                .frame(width: 100)
                                                .scaledToFit()
                                    }
                                }
                            }
                            .frame(height: 100)
                        }

                        VStack{
                            HStack{
                                Text("Name")
                                    .bold(true)
                                TextField(
                                    "Name",
                                    text: $name
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                            }
                            HStack{
                                Text("Make")
                                    .bold(true)
                                TextField(
                                    "make",
                                    text: $make
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                            }
                            HStack{
                                Text("Model")
                                    .bold(true)
                                TextField(
                                    "model",
                                    text: $model
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                            }
                            HStack{
                                Text("Date Installed")
                                    .bold(true)
                                DatePicker(selection: $dateInstalled, displayedComponents: .date) {
                                }
                            }
                            HStack{
                                Text("Status")
                                    .bold(true)
                                Picker("Status", selection: $status) {
                                    ForEach(EquipmentStatus.allCases,id:\.self) { category in
                                        Text("\(category.rawValue)").tag(category)
                                    }
                                }
                            }
                            HStack{
                                Text("Notes")
                                    .bold(true)
                                TextField(
                                    "notes",
                                    text: $notes,
                                    axis: .vertical
                                )
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                            }
                        }
                        VStack{
                            Toggle(isOn: $needsService, label: {
                                Text("Needs Regular Service")
                            })
                            if needsService {
                                HStack{
                                    Text("Last Serviced")
                                        .bold(true)
                                    DatePicker(selection: $lastServiced, displayedComponents: .date) {
                                    }
                                }
                                HStack{
                                    Picker("Every", selection: $serviceFrequencyEvery) {
                                        Text("Every")
                                        ForEach(0...100,id:\.self) {
                                            Text(String($0)).tag(String($0))
                                        }
                                    }
                                    Picker("Frequency", selection: $serviceFrequency) {
                                        Text("Day").tag("Day")
                                        Text("Week").tag("Week")
                                        Text("Month").tag("Month")
                                        Text("Year").tag("Year")

                                    }
                                }
                            }
                        }
                    }
                
            }
        }
    }
    var pumpStartUp: some View {
        VStack{
            Text("Pump")
            Rectangle()
                .frame(height: 1)
            ScrollView(.horizontal){
                HStack{
                    Button(action: {
                        
                    }, label: {
                        ZStack{
                            Image(systemName: "plus.app.fill")
                                .font(.title)
                                .foregroundColor(Color.poolBlue)
                            Image(systemName: "plus.app")
                                .font(.title)
                                .foregroundColor(Color.poolWhite)
                        }
                    })
                    ForEach(equipmentList.filter({$0.category == .pump})) { pump in
                        Button(action: {
                            selectedEquipment = pump
                        }, label: {
                            Text("\(pump.name)")
                                .padding(8)
                                .background(selectedEquipment == pump ? Color.poolBlue : Color.darkGray)
                                .foregroundColor(Color.white)
                                .cornerRadius(8)
                        })
                
                    }
                }
            }
        }
    }
    var heaterStartUp: some View {
        VStack{
            Text("Heater")
            Rectangle()
                .frame(height: 1)
            ScrollView(.horizontal){
                HStack{
                    Button(action: {
                        
                    }, label: {
                        ZStack{
                            Image(systemName: "plus.app.fill")
                                .font(.title)
                                .foregroundColor(Color.poolBlue)
                            Image(systemName: "plus.app")
                                .font(.title)
                                .foregroundColor(Color.poolWhite)
                        }
                    })
                    ForEach(equipmentList.filter({$0.category == .heater})) { heater in
                        Button(action: {
                            selectedEquipment = heater
                        }, label: {
                            Text("\(heater.name)")
                                .padding(8)
                                .background(selectedEquipment == heater ? Color.poolBlue : Color.darkGray)
                                .foregroundColor(Color.white)
                                .cornerRadius(8)
                        })
                
                    }
                }
            }
        }
    }
    var cleanerStartUp: some View {
        VStack{
            Text("Cleaner")
            Rectangle()
                .frame(height: 1)
            ScrollView(.horizontal){
                HStack{
                    Button(action: {
                        
                    }, label: {
                        ZStack{
                            Image(systemName: "plus.app.fill")
                                .font(.title)
                                .foregroundColor(Color.poolBlue)
                            Image(systemName: "plus.app")
                                .font(.title)
                                .foregroundColor(Color.poolWhite)
                        }
                    })
                    ForEach(equipmentList.filter({$0.category == .cleaner})) { cleaner in
                        Button(action: {
                            selectedEquipment = cleaner
                        }, label: {
                            Text("\(cleaner.name)")
                                .padding(8)
                                .background(selectedEquipment == cleaner ? Color.poolBlue : Color.darkGray)
                                .foregroundColor(Color.white)
                                .cornerRadius(8)
                        })
                
                    }
                }
            }
        }
    }
    var autoClorinatorsStartUp: some View {
        VStack{
            Text("Auto Clorinator")
            Rectangle()
                .frame(height: 1)
            ScrollView(.horizontal){
                HStack{
                    Button(action: {
                        
                    }, label: {
                        ZStack{
                            Image(systemName: "plus.app.fill")
                                .font(.title)
                                .foregroundColor(Color.poolBlue)
                            Image(systemName: "plus.app")
                                .font(.title)
                                .foregroundColor(Color.poolWhite)
                        }
                    })
                    ForEach(equipmentList.filter({$0.category == .pump})) { pump in
                        Button(action: {
                            selectedEquipment = pump
                        }, label: {
                            Text("\(pump.name)")
                                .padding(8)
                                .background(selectedEquipment == pump ? Color.poolBlue : Color.darkGray)
                                .foregroundColor(Color.white)
                                .cornerRadius(8)
                        })
                
                    }
                }
            }
        }
    }
    var controlSystemStartUp: some View {
        VStack{
            Text("ControlSystem")
            Rectangle()
                .frame(height: 1)
            ScrollView(.horizontal){
                HStack{
                    Button(action: {
                        
                    }, label: {
                        ZStack{
                            Image(systemName: "plus.app.fill")
                                .font(.title)
                                .foregroundColor(Color.poolBlue)
                            Image(systemName: "plus.app")
                                .font(.title)
                                .foregroundColor(Color.poolWhite)
                        }
                    })
                    ForEach(equipmentList.filter({$0.category == .pump})) { pump in
                        Button(action: {
                            selectedEquipment = pump
                        }, label: {
                            Text("\(pump.name)")
                                .padding(8)
                                .background(selectedEquipment == pump ? Color.poolBlue : Color.darkGray)
                                .foregroundColor(Color.white)
                                .cornerRadius(8)
                        })
                
                    }
                }
            }
        }
    }
    
}
