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
            return "Operation"
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
        case .serviceHistory:
            return Color.brown
        }
    }
}

import SwiftUI

struct CustomerRouteView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var VM : CustomerListViewModel
    private var customer: Customer? {
        VM.customers.first { $0.id == customerId }
    }
    let customerId: String
    @State var selectedCustomer:Customer? = nil
    @State var isLoading:Bool = false
    @State var showEditView:Bool = false
    @State var viewType:customerDetailViewEnum = .location
    

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                if let customer{
                    LazyVStack(alignment: .center,
                               pinnedViews: [.sectionHeaders],
                               content: {
                        Section(content: {
                            VStack{
                                switch viewType{
                                case .profile:
                                    CustomerProfileView(
                                        customerId: customerId
                                    )
                                case .location:
                                    CustomerLocationView(
                                        dataService: dataService,
                                        customerId: customerId
                                    )
                                case .upcomingWork:
                                    CustomerUpcomingWork(
                                        dataService: dataService,
                                        customerId: customerId
                                    )
                                case .serviceHistory:
                                    CustomerStopDataDetailView(
                                        dataService: dataService,
                                        customerId: customerId
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
                } else {
                    Text("No Customer")
                }
            }
            .clipped()
        }
        .navigationTitle("\(customer?.firstName ?? "") \(customer?.lastName ?? "")")
        .font(.system(.body , design: .rounded))
        .navigationBarTitleDisplayMode(.inline)
//        .navigationBarBackground()
//        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct CustomerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSignInView: Bool = false
        CustomerRouteView(
            customerId: ""
        )
    }
}
extension CustomerRouteView {
    var sectionTitles:some View {
        VStack{
            ScrollView(.vertical, showsIndicators: false){
                HStack(spacing: 0){
                    
                    Button(action: {
                        viewType = .profile
                    }, label: {
                        if viewType == .profile {
                            Image(systemName: "person.circle")
                                .modifier(BlueButtonModifier())
                        } else {
                            Image(systemName: "person.circle")
                                .modifier(ListButtonModifier())
                        }
                    })
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack{
                            ForEach(customerDetailViewEnum.allCases){ screen in
                                if screen != .profile {
                                    if screen != viewType {
                                        Button(action: {
                                            viewType = screen
                                        }, label: {
                                            HStack{
                                                Text(screen.title)
                                            }
                                            .modifier(ListButtonModifier())
                                        })
                                    } else {
                                        Button(action: {
                                            viewType = screen
                                        }, label: {
                                            HStack{
                                                Text(screen.title)
                                            }
                                            .modifier(BlueButtonModifier())
                                        })
                                    }
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
