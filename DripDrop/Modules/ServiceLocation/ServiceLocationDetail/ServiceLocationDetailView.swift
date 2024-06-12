//
//  ServiceLocationDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//


import SwiftUI
import MapKit

struct ServiceLocationDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService

    //ViewModels
    @StateObject var bodyOfWaterVM : BodyOfWaterViewModel
    //received Variables
    @State var location:ServiceLocation
    init(dataService:any ProductionDataServiceProtocol,location:ServiceLocation){
        _bodyOfWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _location = State(wrappedValue: location)
        
    }
    //Variables for use
    @State var BOWList:[BodyOfWater] = []
    @State var selectedBOW:BodyOfWater? = nil
    @State var showEditSheet:Bool = false
    @State var showAddSheet:Bool = false
    @State var isLoading:Bool = false
    
    @State var showLocationSetUp:Bool = false
    var body: some View {
        ZStack{
            if isLoading {
                ProgressView()
            } else {
                VStack{
                    edit
                    Button(action: {
                        showLocationSetUp.toggle()
                    }, label: {
                        Text("Show Location Set Up")
                            .padding(8)
                            .background(Color.pink)
                            .foregroundColor(Color.black)
                            .cornerRadius(8)
                    }).sheet(isPresented: $showLocationSetUp, content: {
                        ServiceLocationStartUpView(dataService: dataService, serviceLocation: location) //DEVELOPER MOVE THIS TO A JOB
                    })
                    info
                    bodiesOfWater
                }
            }
        }
        .onChange(of: masterDataManager.selectedServiceLocation, perform: { loc in
            Task{
                isLoading = true
                do {
                    if let location = loc {
                        try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: masterDataManager.selectedCompany!.id, serviceLocation: location)
                        BOWList = bodyOfWaterVM.bodiesOfWater
                        if BOWList.count != 0 {
                            selectedBOW = BOWList.first!
                            masterDataManager.selectedBodyOfWater = BOWList.first!

                        }
                    }
                } catch{
                    print("Error")
                }
                isLoading = false
            }
        }
                  
        )
        .task{
            isLoading = true
            do {
                if let location = masterDataManager.selectedServiceLocation {
                    try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: masterDataManager.selectedCompany!.id, serviceLocation: location)
                    BOWList = bodyOfWaterVM.bodiesOfWater
                    if BOWList.count != 0 {
                        selectedBOW = BOWList.first!
                        masterDataManager.selectedBodyOfWater = BOWList.first!

                    }
                }
            } catch{
                print("Error")
            }
            isLoading = false
        }
    }
}
extension ServiceLocationDetailView {
    var edit: some View {
        HStack{

            Spacer()
            if let location = masterDataManager.selectedServiceLocation {
                
                Button(action: {
                    showEditSheet = true
                }, label: {
                    Text("Edit")
                        .padding(8)
                        .foregroundColor(Color.basicFontText)
                        .background(Color.poolBlue)
                        .cornerRadius(8)
                })
                .sheet(isPresented: $showEditSheet, content: {
                    EditServiceLocationView(dataService: dataService, serviceLocation: location)
                })
            }
        }
        .padding()
    }
    var info: some View {
        VStack(alignment: .leading){
            if let location = masterDataManager.selectedServiceLocation {
                HStack{
                    Text("Customer: \(location.customerName)")
                    Spacer()
                }
                HStack{

                Text("Nick Name: \(location.nickName)")
                    Spacer()
                }
                HStack{
                Text("Gate Code: \(location.gateCode)")
                    Spacer()
                }
                HStack{
                Text("Street: \(location.address.streetAddress)")
                    Spacer()
                }
            }
        }
        .padding(.horizontal,8)
    }
    var bodiesOfWater: some View {
        VStack{
            Divider()
            Text("Bodies Of Water Detail View")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false){
                HStack{
                    Button(action: {
                        showAddSheet = true
                    }, label: {
                        Image(systemName: "plus.square.on.square")
                            .font(.headline)
                            .foregroundColor(Color.basicFontText)
                            .padding(8)
                            .background(Color.poolBlue)
                            .cornerRadius(8)
                    })
                    .sheet(isPresented: $showAddSheet, content: {
                        if let location = masterDataManager.selectedServiceLocation {
                            AddBodyOfWaterView(dataService: dataService, serviceLocation: location)
                        }
                    })
                if BOWList.count == 0 {
                    Button(action: {
                        
                    }, label: {
                        Text("Add First Body Of Water")
                    })
                } else {
                    ForEach(BOWList){ BOW in
                        Button(action: {
                            selectedBOW = nil
                            selectedBOW = BOW
                            masterDataManager.selectedBodyOfWater = BOW
                        }, label: {
                            Text(BOW.name)
                        })
                        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                    }
                    
    
                }
                }
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            if selectedBOW == nil {
                Text("Please select a Body of Water")
            } else {
        
                    BodyOfWaterDetailView(dataService: dataService, bodyOfWater: selectedBOW!)
                
            }
        }
        .padding(.horizontal,8)
        
    }
    var image: some View {
        ZStack{
            VStack{
                BackGroundMapView(coordinates: CLLocationCoordinate2D(latitude: location.address.latitude, longitude: location.address.longitude))
                    .frame(height: 150)
            }
            .padding(0)
            VStack{
                ZStack{
                    Circle()
                        .fill(Color.realYellow)
                        .frame(maxWidth:100 ,maxHeight:100)
                    
                    Image(systemName:"person.circle")
                        .resizable()
                        .foregroundColor(Color.white)
                        .frame(maxWidth:90 ,maxHeight:90)
                        .cornerRadius(75)
                }
                //                .frame(maxWidth: 150,maxHeight:150)
                .padding(EdgeInsets(top: 125, leading: 10, bottom: 0, trailing: 10))
            }
        }
    }
}
struct ServiceLocationDetailView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        @State var showSignInView: Bool = false
        
        ServiceLocationDetailView(
            dataService: dataService,
            location: MockDataService.mockServiceLocation
        )
    }
}


