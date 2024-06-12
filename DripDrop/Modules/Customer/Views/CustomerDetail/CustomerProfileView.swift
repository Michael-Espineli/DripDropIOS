//
//  CustomerProfileView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI
import MapKit

struct CustomerProfileView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    let customer:Customer
    @State var showEditView:Bool = false
    var body: some View {
        ZStack{
            ScrollView(showsIndicators: false){
                image
                info
            }
        }
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing){
                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("16") {
                        HStack{
                            Spacer()
                            Button(action: {
                                showEditView.toggle()
                            }, label: {
                               Text("Edit")
                            })
                        }
                        .padding(5)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showEditView, content: {
            ZStack{
                VStack{
                    HStack{
                        Spacer()
                        Button(action: {
                            showEditView = false
                        }, label: {
                            Image(systemName: "xmark")
                        })
                    }
                    .padding(16)
                    CustomerProfileEditView(dataService: dataService, customer: customer)

                }
            }
        })
    }
}
extension CustomerProfileView {
    var info: some View {
        VStack{
            VStack{
                if customer.displayAsCompany {
                    VStack{
                        HStack{
                            Text("Company: ")
                                .bold(true)
                            Spacer()
                        }
                        HStack{
                            Text("\(customer.company ?? "")")
                                .font(.headline)
                            Spacer()
                        }
                    }
                } else {
                        HStack{
                            Text("Customer: ")
                                .bold(true)
                            Spacer()
                      
                            Text("\(customer.firstName) \(customer.lastName)")
                            if customer.firstName == "" {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color.yellow)
                            }
                        }
                    
                }
                HStack{
                    Text("Email: ")
                        .bold(true)
                    Spacer()
                    Text("\(customer.email)")
                    if customer.email == "" {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.yellow)
                    }
                }
                HStack{
                    Text("Phone Number: ")
                        .bold(true)
                    Spacer()
                    Text("\(customer.phoneNumber ?? "")")
                    if customer.phoneNumber == "" {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.yellow)
                    }
                }
                HStack{
                    Text("Phone Label: ")
                        .bold(true)
                    Spacer()
                    Text("\(customer.phoneLabel ?? "")")
                    if customer.phoneLabel == "" {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.yellow)
                    }
                }
                HStack{
                    Text("Active: ")
                        .bold(true)
                    Spacer()
                    Text("\(String(customer.active))")
                }
                HStack{
                    Text("Rate: ")
                        .bold(true)
                    Spacer()
                    Text("$\(String(customer.rate ?? 0))")
                }
            }
            HStack{
                Text("Billing Address: ")
                    .bold(true)
                Spacer()
                VStack{
                    HStack{
                        Text("\(customer.billingAddress.streetAddress)")
                        if customer.billingAddress.streetAddress == "" {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color.yellow)
                        }
                    }
                    HStack{
                        Text("\(customer.billingAddress.city)")
                        if customer.billingAddress.city == "" {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color.yellow)
                        }
                        Text("\(customer.billingAddress.state)")
                        if customer.billingAddress.state == "" {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color.yellow)
                        }
                        Text("\(customer.billingAddress.zip)")
                        if customer.billingAddress.zip == "" {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color.yellow)
                        }

                    }
                }
            }
            VStack{
                HStack{
                    Text("Fire Category: ")
                        .bold(true)
                    Spacer()
                    Text("\(customer.fireCategory ?? "")")
                    
                }
                HStack{
                    Text("Fire Reason: ")
                        .bold(true)
                    Spacer()
                    Text("\(customer.fireReason ?? "")")
                    
                }
                HStack{
                    Text("Billing Notes: ")
                        .bold(true)
                    Spacer()
                    Text("\(customer.billingNotes)")
                    
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
    }
    var image: some View {
        ZStack{
            VStack{
                BackGroundMapView(coordinates: CLLocationCoordinate2D(latitude: customer.billingAddress.latitude, longitude: customer.billingAddress.longitude))
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
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
        }
    }
}
//struct CustomerProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        @State var showSignInView: Bool = false
//
//        CustomerProfileView(showSignInView: $showSignInView, user: DBUser(id: UUID().uuidString,firstName: "Michael",lastName: "Espineli"), company: Company(id:"1"), customer: Customer(id: UUID().uuidString, firstName: "Ron", lastName: "Palace", email: "Email@gmail.com", billingAddress: Address(streetAddress: "6160 Broadmoor Dr ", city: "La Mesa", state: "Ca", zip: "91942", latitude: 32.790086, longitude: -116.991113), active: true, displayAsCompany: false, hireDate: Date(), billingNotes: ""))
//
//    }
//}

