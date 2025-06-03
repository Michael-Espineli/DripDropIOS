//
//  CustomerDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//

enum customerDetailViewEnum: Int, CaseIterable, Identifiable {
    var id: Int { rawValue }
    case profile
    case location
    case upcomingWork
    case billing
    case serviceHistory
}

extension customerDetailViewEnum {
    
    var title: String {
        switch self {
        case .profile:
            return "Profile"
        case .location:
            return "Location"
        case .upcomingWork:
            return "Jobs"
        case .serviceHistory:
            return "History"
        case .billing:
            return "Billing"
        
        }
    }
    
    var systemImage: String {
        switch self {
        case .profile:
            return "person.circle.fill"
        case .location:
            return "house.fill"
        case .upcomingWork:
            return "wrench.adjustable.fill"
        case .billing:
            return "dollarsign.circle.fill"
        case .serviceHistory:
            return "doc.text"
        }
    }
    var color: Color {
        switch self {
        case .profile:
            return Color.red
        case .location:
            return Color.blue
        case .upcomingWork:
            return Color.purple
        case .billing:
            return Color.green
        case .serviceHistory:
            return Color.brown
        }
    }
}

import SwiftUI

struct CustomerDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    let customer:Customer
    @State var selectedCustomer:Customer? = nil
    @State var isLoading:Bool = false
    @State var showEditView:Bool = false
    @State var viewType:customerDetailViewEnum = .profile
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                LazyVStack(alignment: .center,
                           pinnedViews: [.sectionHeaders],
                           content: {
                    Section(content: {
                        VStack{
                            switch viewType{
                            case .profile:
                                CustomerProfileView(
                                    customer: customer
                                )
                            case .location:
                                CustomerLocationView(
                                    dataService: dataService,
                                    customer: customer
                                )
                            case .upcomingWork:
                                CustomerUpcomingWork(
                                    dataService: dataService,
                                    customer: customer
                                )
                            case .billing:
                                CustomerBillingView(
                                    dataService: dataService,
                                    customer: customer
                                )
                            case .serviceHistory:
                                CustomerStopDataDetailView(
                                    dataService: dataService,
                                    customerId: customer.id
                                )
                                //Developer Figure out whats better
//                                CustomerServiceHistoryView(
//                                    dataService: dataService,
//                                    customer: customer
//                                )
                            }
                        }
                        .padding(.horizontal,8)
                    },
                    header: {
                        sectionTitles
                            .padding(8)
                            .background(Color.listColor)
                    })
                })
            }
            .clipped()
        }
        .navigationTitle("\(customer.firstName) \(customer.lastName)")
        .font(.system(.body , design: .rounded))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackground()
        .task{
                selectedCustomer = customer
            
        }
        .onChange(of: masterDataManager.selectedCustomer, perform: { cus in
            print("Selected Customer Changed \(cus)")
            Task{
                isLoading = true
                guard let selectedCustomer1 = cus else {
                    print("Error")
                    return
                }
                selectedCustomer = selectedCustomer1
                isLoading = false
            }
        })
    }
}

struct CustomerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSignInView: Bool = false
        CustomerDetailView(
            customer: Customer(
                id: UUID().uuidString,
                firstName: "Ron",
                lastName: "Palace",
                email: "Email@gmail.com",
                billingAddress: Address(
                    streetAddress: "6160 Broadmoor Dr ",
                    city: "La Mesa",
                    state: "Ca",
                    zip: "91942",
                    latitude: 32.790086,
                    longitude: -116.991113
                ),
                active: true,
                displayAsCompany: false,
                hireDate: Date(),
                billingNotes: "",
                linkedInviteId: UUID().uuidString
            )
        )
    }
}
extension CustomerDetailView {
    var sectionTitles:some View {
        VStack{
            ScrollView(.vertical, showsIndicators: false){
                HStack(spacing: 0){
                    Button(action: {
                        viewType = .profile
                    }, label: {
                        if viewType == .profile {
                            HStack{
                                Text(customerDetailViewEnum.profile.title)
                            }
                            .modifier(BlueButtonModifier())
                        } else {
                            HStack{
                                Text(customerDetailViewEnum.profile.title)
                            }
                            .modifier(ListButtonModifier())
                        }
                    })
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack{
                            ForEach(customerDetailViewEnum.allCases){ screen in
                                if screen != viewType {
                                    Button(action: {
                                        viewType = screen
                                    }, label: {
                                        if viewType == screen {
                                            HStack{
                                                Text(screen.title)
                                            }
                                            .modifier(BlueButtonModifier())
                                        } else {
                                            HStack{
                                                Text(screen.title)
                                            }
                                            .modifier(ListButtonModifier())
                                        }
                                    })
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 0))
                    }
                    .padding(.leading,8)
                    .overlay(
                        HStack{
                            LinearGradient(colors: [
                                Color.listColor,
                                Color.listColor.opacity(0.5),
                                Color.clear
                            ],
                                           startPoint: .leading,
                                           endPoint: .trailing)
                            .frame(width: 20)
                            Spacer()
                        }
                    )
                }
            }
            Rectangle()
                .frame(height: 1)
        }
    }
    var viewController: some View {
        Picker("", selection: $viewType) {
            ForEach(customerDetailViewEnum.allCases){
                Text($0.title).tag($0)
            }
        }
        .pickerStyle(.segmented)
        .padding(5)
        .background(Color.white)
        .cornerRadius(5)
        .shadow(color: Color.basicFontText, radius: 5)
    }
    var viewController2: some View {
        HStack{
            Spacer()
            ForEach(customerDetailViewEnum.allCases) { category in
                VStack{
                    Button(action: {
                        viewType = category
                    }, label: {
                                Image(systemName: category.systemImage)
                                    .font(viewType == category ? .largeTitle : .title)
                                    .foregroundColor(viewType == category ? Color.poolGreen : Color.basicFontText)
                                    .padding(5)
                    })
                    Text(category.title)
                        .underline(viewType == category,color: Color.accentColor)
                }
                Spacer()
            }
        }
        .padding(5)
        .background(Color.poolBlue)
    }
}
