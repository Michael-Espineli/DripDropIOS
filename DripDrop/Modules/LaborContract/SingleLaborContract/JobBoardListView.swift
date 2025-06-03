//
//  JobBoardListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import SwiftUI

@MainActor
final class JobBoardListViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var publicJobBoards : [JobBoard] = []
    @Published private(set) var jobBoards : [JobBoard] = []
    @Published private(set) var owenedJobs : [JobPost] = []

    func onLoad(companyId:String,userId:String) async throws {
        self.publicJobBoards = try await dataService.getPublicJobBoards()
        self.owenedJobs = try await dataService.getJobPostsByUserId(userId: userId )
    }
}

struct JobBoardListView: View {
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: JobBoardListViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : JobBoardListViewModel
    @State var selectedScreen : String = "Boards"
    @State var screenOptions : [String] = ["Boards","Jobs"]
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Picker("Type", selection: $selectedScreen) {
                    ForEach(screenOptions, id:\.self){ datum in
                        Text(datum).tag(datum)
                    }
                }
                .pickerStyle(.segmented)
                switch selectedScreen {
                case "Boards" :
                    boardView
                default:
                    jobPostView
                }
            }
        }
        .navigationTitle("Job Boards")
        .navigationBarTitleDisplayMode(.inline)
        .task{
            if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, userId: user.id)
                } catch {
                    print("Error - [LaborContractListView]")
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    JobBoardListView()
//}
extension JobBoardListView {
    var boardView : some View  {
        VStack{
            
            Text("Saved")
                .bold()
            Divider()
            
            Text("Access")
                .bold()
            Divider()
            
            Text("Owned")
                .bold()
            Divider()
            
            Text("Public Regionally")
                .bold()
            Divider()
            ScrollView(.horizontal){
                HStack {
                    ForEach(VM.publicJobBoards) { board in
                        NavigationLink(value: Route.jobBoard(dataService: dataService, jobBoard: board), label: {
                                JobBoardCardView(jobBoard: board)
                        })
                        .padding(.horizontal,8)
                    }
                }
            }
        }
        .padding(8)
    }
    var jobPostView : some View  {
        VStack{
            Text("Saved")
                .bold()
            Divider()
            Text("Posting")
                .bold()
            Divider()
            Text("Requested")
                .bold()
            Divider()
            Text("Owner")
                .bold()
            Divider()
            ScrollView(.horizontal){
                HStack {
                    ForEach(VM.owenedJobs) { jobPost in
                        NavigationLink(value: Route.jobPost(dataService: dataService, jobPost: jobPost), label: {
                                JobPostCardViewSquare(jobPost: jobPost)
                        })
                        .padding(.horizontal,8)
                    }
                }
            }
            HStack{
                Spacer()
                Button(action: {
                    
                }, label: {
                    
                    Text("Expired ->")
                        .bold()
                })
            }
            Divider()
        }
        .padding(8)
    }
}
