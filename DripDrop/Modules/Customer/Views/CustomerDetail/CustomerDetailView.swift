//
//  CustomerDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//

enum customerDetailViewEnum: Int, CaseIterable, Identifiable {
    var id: Int { rawValue }
    case location
    case upcomingWork
    case profile
    case serviceHistory
    case billing
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
        case .billing:
            return "Billing"
        case .serviceHistory:
            return "History"
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
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        VStack{
                            switch viewType{
                            case .profile:
                                CustomerProfileView(customer: customer)
                            case .location:
                                CustomerLocationView(dataService: dataService, customer: customer)
                            case .upcomingWork:
                                CustomerUpcomingWork(dataService: dataService,customer: customer)
                            case .billing:
                                CustomerBillingView(dataService: dataService, customer: customer)
                            case .serviceHistory:
                                CustomerServiceHistoryView(dataService: dataService,customer: customer)
                            }
                        }
                    }, header: {
                        sectionTitles
                            .padding(.leading,8)
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
        CustomerDetailView(customer: Customer(id: UUID().uuidString, firstName: "Ron", lastName: "Palace", email: "Email@gmail.com", billingAddress: Address(streetAddress: "6160 Broadmoor Dr ", city: "La Mesa", state: "Ca", zip: "91942", latitude: 32.790086, longitude: -116.991113), active: true, displayAsCompany: false, hireDate: Date(), billingNotes: ""))
    }
}
extension CustomerDetailView {
    var sectionTitles:some View {
        ScrollView(.vertical, showsIndicators: false){
            HStack(spacing: 0){
                Button(action: {
                    viewType = .profile
                }, label: {
                    HStack{
                        Text(customerDetailViewEnum.profile.title)
                    }
                    .frame(minWidth: 50,maxHeight: 30)
                    .font(.footnote)
                    .foregroundColor(Color.poolWhite)
                    .padding(10)
                    .background(viewType == .profile ? Color.poolBlue : Color.darkGray)
                    .frame(minWidth: 50,maxHeight: 30)
                    .clipShape(Capsule())
                })
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack{
                        ForEach(customerDetailViewEnum.allCases){ screen in
                            if screen != .profile {
                                Button(action: {
                                    viewType = screen
                                }, label: {
                                    HStack{
                                        Text(screen.title)
                                    }
                                    .frame(minWidth: 50,maxHeight: 30)
                                    .font(.footnote)
                                    .foregroundColor(Color.poolWhite)
                                    .padding(10)
                                    .background(viewType == screen ? Color.poolBlue : Color.darkGray)
                                    .frame(minWidth: 50,maxHeight: 30)
                                    .clipShape(Capsule())
                                })
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 0))
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
                .padding(.leading,8)
            }
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
