//
//  TestData.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/11/25.
//


struct TestDataView: View {
    @StateObject private var VM = TestDataViewModel()

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Text("Development Data")
                    Button(action: {
                        VM.setUpTestCompany()
                    }, label: {
                        Text("Create All Company Test Data")
                            .modifier(BlueButtonModifier())
                    })
                    Rectangle()
                        .frame(height: 1)
                VStack{
                    Button(action: {
                        VM.setUpTestCustomers()
                        
                    }, label: {
                        Text("Customer Test Data")
                            .modifier(BlueButtonModifier())
                    })
                    Button(action: {
                        VM.setUpTestCompanyUsers()
                        
                    }, label: {
                        Text("Company User Test Data")
                            .modifier(BlueButtonModifier())
                    })
                    
                    Button(action: {
                        VM.setUpTestRoles()
                        
                    }, label: {
                        Text("Roles Test Data")
                            .modifier(BlueButtonModifier())
                    })
                    Button(action: {
                        VM.setUpTestFleet()
                        
                    }, label: {
                        Text("Fleet Test Data")
                            .modifier(BlueButtonModifier())
                    })
                    Button(action: {
                        VM.setUpTestJobs()
                        
                    }, label: {
                        Text("Jobs Test Data")
                            .modifier(BlueButtonModifier())
                    })
                }
                
                VStack{
                    Button(action: {
                        VM.setUpTestRoutes()
                        
                    }, label: {
                        Text("Routes Test Data")
                            .modifier(BlueButtonModifier())
                    })
                    Button(action: {
                        VM.setUpTestServiceStops()
                        
                    }, label: {
                        Text("Service Stops Test Data")
                            .modifier(BlueButtonModifier())
                    })
                    Button(action: {
                        VM.setUpTestRecurringServiceStops()
                        
                    }, label: {
                        Text("Recurring Service Stops Test Data")
                            .modifier(BlueButtonModifier())
                    })
                }
            }
            .padding(8)
        }
        .fontDesign(.monospaced)
    }
}
