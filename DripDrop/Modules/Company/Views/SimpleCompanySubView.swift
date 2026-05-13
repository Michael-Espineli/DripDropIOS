//
//  SimpleCompanySubView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/30/25.
//

import SwiftUI

struct SimpleCompanySubView: View {
    let company : Company
    var body: some View {
        VStack{
            VStack{
                HStack{
                    Text("\(company.name)")
                        .font(.headline)
                }
            }
            Rectangle()
                .frame(height: 1)
                //Company Info
            VStack{
                Text("Company Info")
                    .font(.headline)
                    .padding(.top,16)
                Divider()
                HStack{
                    Text("Name: \(company.name)")
                    Spacer()
                }
                HStack{
                    Text("Email: \(company.email)")
                    Spacer()
                }
                HStack{
                    Text("Phone Number: \(company.phoneNumber)")
                    Spacer()
                }
                HStack{
                    Text("Date Created: \(fullDate(date:company.dateCreated))")
                    Spacer()
                }
                HStack{
                    Text("Verified: \(company.verified ? "True" : "False")")
                    Spacer()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)
                    .shadow(color: Color.darkGray.opacity(0.06), radius: 12, x: 0, y: 4)
            )
                //Service Info
            VStack{
                Text("Service Info")
                    .font(.headline)
                    .padding(.top,16)
                Divider()
                HStack{
                    Text("Services Offered:")
                        .bold()
                    Spacer()
                }
                ScrollView(.horizontal){
                    HStack{
                        ForEach(company.services,id:\.self){ tag in
                            Text(tag)
                        }
                    }
                }
                HStack{
                    Text("Regions Services:")
                        .bold()
                    Spacer()
                }
                ScrollView(.horizontal){
                    HStack{
                        ForEach(company.serviceZipCodes,id:\.self){ tag in
                            Text(tag)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)
                    .shadow(color: Color.darkGray.opacity(0.06), radius: 12, x: 0, y: 4)
            )
                //Social Media and Links
            VStack{
                Text("Social Media And Links")
                    .font(.headline)
                    .padding(.top,16)
                Divider()
                
                HStack{
                    Text("Yelp")
                        .bold()
                    Spacer()
                    
                    if let url = URL(string: company.yelpURL){
                        
                        Link(destination: url, label: {
                            Text("External Link")
                                .modifier(RedLinkModifier())
                        })
                    }
                }
                Text(company.yelpURL)
                    .font(.caption)
                    //Yelp Rating
                HStack{
                    Text("Web Site")
                        .bold()
                    Spacer()
                    if let url = URL(string: company.websiteURL){
                        
                        Link(destination: url, label: {
                            Text("External Link")
                                .modifier(RedLinkModifier())
                        })
                    }
                }
                Text(company.websiteURL)
                    .font(.caption)
                    //                HStack{
                    //                    Text("Drop Drop Rating")
                    //                        .bold()
                    //                    Spacer()
                    //                    Button(action: {
                    //
                    //                    }, label: {
                    //                        HStack{
                    //                            Text("Reviews")
                    //                            Image(systemName: "arrow.right")
                    //                        }
                    //                        .modifier(RedLinkModifier())
                    //                    })
                    //                }
                    //                HStack{
                    //                    Image(systemName: "star.fill")
                    //                        .foregroundColor(Color.poolYellow)
                    //                    Image(systemName: "star.fill")
                    //                        .foregroundColor(Color.poolYellow)
                    //                    Image(systemName: "star.fill")
                    //                        .foregroundColor(Color.poolYellow)
                    //                    Image(systemName: "star.fill")
                    //                        .foregroundColor(Color.poolYellow)
                    //                    Image(systemName: "star")
                    //                        .foregroundColor(Color.poolYellow)
                    //                    Spacer()
                    //                }
                    //
                    //                HStack{
                    //                    Text("Drop Drop Reputation")
                    //                        .bold()
                    //                    Spacer()
                    //                }
                    //                Text("Score based on completing work and paying out")
                    //                    .font(.footnote)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)
                    .shadow(color: Color.darkGray.opacity(0.06), radius: 12, x: 0, y: 4)
            )
        }
    }
}

#Preview {
    SimpleCompanySubView(company: MockDataService.mockCompany)
}
