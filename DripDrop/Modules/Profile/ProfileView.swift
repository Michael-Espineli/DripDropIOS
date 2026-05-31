//
//  ProfileView.swift
//  ClientSide
//
//  Created by Michael Espineli on 11/30/23.
//

import SwiftUI
import PhotosUI
import Charts
struct ProfileView: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject private var VM : AuthenticationViewModel
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var userAccessVM = UserAccessViewModel()

    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
    }
    
    @State private var selectedPhoto:PhotosPickerItem? = nil
    #if os(iOS)
    @State private var displayImage:UIImage? = nil
    #endif
    @State private var displayURL:URL? = nil
    @State private var urlDisplayString:String? = nil

    @State var level:Int = 0
    @State var percentage:Double = 0
    @State var expToNext:Double = 0
    @State var showUserSettings:Bool  = false
    @State var showEditUser:Bool = false

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders]) {
                    Section {
                        VStack(spacing: 12) {
                            Divider().opacity(0)
                                // ----------------------------------------
                                // Add Back in During Roll out of Phase 2
                                // ----------------------------------------
                            
//                              recentActivity
                                // rateSheet
                                // sendInvoice
                                // chartStuff
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                        .foregroundStyle(.poolBlack)
                    } header: {
                        VStack(spacing: 12) {
//                            toolBar
                            profile
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                    }
                }
                .background(Color.listColor.ignoresSafeArea())
            }
        }
        .navigationTitle("\(masterDataManager.user?.firstName ?? "First Name") \(masterDataManager.user?.lastName ?? "Last Name")")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let user = masterDataManager.user {
                print("Arrived at Profile Page")
                do {
                    try await profileVM.loadCurrentUser()
                } catch {
                    print(error)
                }
                do {
                    try await userAccessVM.getAllUserAvailableCompanies(userId: user.id)
                } catch {
                    print(error)
                }
                print("Calculating Exp")
                let thing = calculateLevel(exp: user.exp)
                level = thing.level
                percentage = thing.percentage
                expToNext = thing.expToNextlevel
            }
        }
        .onChange(of: selectedPhoto) { newValue in
            if let user = masterDataManager.user, let newValue {
                Task {
                    print("Save Profile Image")
                    profileVM.saveProfileImage(user: user, item: newValue)
                }
            }
        }
    }
}

#Preview {
    ProfileView(dataService: MockDataService())
        .environmentObject(NavigationStateManager())
        .environmentObject(MasterDataManager(dataService: ProductionDataService()))
        .environmentObject(ProductionDataService())
}

extension ProfileView {
    var toolBar: some View {
        HStack {
            Spacer(minLength: 0)
            if let user = masterDataManager.user {
                NavigationLink(value: Route.editUser(user: user, dataService: dataService)) {
                    Label("Edit", systemImage: "pencil")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.12))
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityLabel("Edit Profile")
            }
        }
    }

    var rateSheet: some View {
        VStack{
            if let user = masterDataManager.user {
                HStack{
                    Spacer()
             
                        NavigationLink(value: Route.rateSheet(user: user, dataService: dataService), label: {

                        HStack{
                            Text("Rate Sheet")
                            Image(systemName: "chevron.right")
                        }
                        .modifier(BlueButtonModifier())
                    })
                }
            }
        }
    }
    var recentActivityEmployee: some View {
        VStack{
            
            HStack{
                Spacer()
                Button(action: {
                    navigationManager.routes.append(Route.recentActivity(dataService: dataService))
                }, label: {
                    HStack{
                        Text("Recent Activity")
                        Image(systemName: "chevron.right")
                    }
                    .modifier(BlueButtonModifier())
                })
            }
        }
    }
    var recentActivity: some View {
        VStack{
            
            HStack{
                Spacer()
                    NavigationLink(value: Route.workLogList(dataService: dataService), label: {
                    HStack{
                        Text("Recent Activity")
                        Image(systemName: "chevron.right")
                    }
                    .modifier(BlueButtonModifier())
                })
            }
        }
    }
    var chartStuff: some View {
        mockChart(numbers: [1,4,7,3,6,8,3,4,9,3,5,7,1,3,7,4,7])
    }
    var sendInvoice: some View {
        VStack{
            
            HStack{
                Spacer()
      
                    NavigationLink(value: Route.compileInvoice(dataService: dataService), label: {

                    HStack{
                        Text("Send Invoice")
                        Image(systemName: "chevron.right")
                    }
                    .modifier(BlueButtonModifier())
                })
            }
        }
    }
    var image: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 100, height: 100)

                if let urlString = profileVM.imageUrlString, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 100)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: "person.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.white.opacity(0.7))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

            PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.basicFontText)
                    .padding(6)
                    .background(.black.opacity(0.6), in: Circle())
            }
            .padding(4)
            .accessibilityLabel("Change profile photo")
        }
        .frame(width: 120, height: 120)
        .padding(.top, 8)
    }
    var profile: some View {
        VStack(spacing: 12) {
            if let user = masterDataManager.user {
                VStack(alignment: .leading, spacing: 12) {
                    HStack{
                        Text("\(user.firstName) \(user.lastName)")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(Color.basicFontText)
                        if let user = masterDataManager.user {
                            NavigationLink(value: Route.editUser(user: user, dataService: dataService)) {
                                Label("Edit", systemImage: "pencil")
                                    .labelStyle(.titleAndIcon)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.white.opacity(0.12))
                            .foregroundColor(Color.basicFontText)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .accessibilityLabel("Edit Profile")
                        }
                    }
                    HStack(alignment: .center, spacing: 16) {
                        image

                        // Level ring
                        ZStack {
                            Circle()
                                .stroke(Color.reverseFontText.opacity(0.4), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 56, height: 56)
                            Circle()
                                .trim(from: 0, to: calculateLevel(exp: user.exp).percentage)
                                .stroke(Color.poolGreen, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 56, height: 56)
                            Text("\(calculateLevel(exp: user.exp).level)")
                                .font(.headline.weight(.bold))
                                .foregroundColor(Color.basicFontText)
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(.white))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Level \(calculateLevel(exp: user.exp).level)")
                    }

                    bio
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
    var bio: some View {
        Group {
            if let user = masterDataManager.user {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Email:").bold()
                        Spacer()
                    }
                    Text(user.email)
                        .foregroundColor(Color.basicFontText)
                        .textSelection(.enabled)
                    HStack {
                        Text("Phone Number:").bold()
                        Spacer()
                        Text(user.phoneNumber ?? "Not Set")
                            .foregroundColor(Color.basicFontText)
                    }
                    HStack {
                        Text("Date Created:").bold()
                        Spacer()
                        Text(fullDate(date: user.dateCreated))
                            .foregroundColor(Color.basicFontText)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bio:").bold()
                        Text(user.bio ?? "")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                }
                .foregroundColor(Color.basicFontText)
            }
        }
    }
}

