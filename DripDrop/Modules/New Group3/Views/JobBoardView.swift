//
//  JobBoardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import SwiftUI

@MainActor
final class JobBoardViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var jobPosts : [JobPost] = []
    @Published var showNewJobPost : Bool = false
    @Published var showNewJobFilter : Bool = false

    func onLoad(companyId:String,boardId:String) async throws {
        self.jobPosts = try await dataService.getJobPostsByBoard(boardId: boardId)
    }
}
struct JobBoardView: View {
    init(dataService: any ProductionDataServiceProtocol, jobBoard:JobBoard){
        _VM = StateObject(wrappedValue: JobBoardViewModel(dataService: dataService))

        _jobBoard = State(wrappedValue: jobBoard)
    }    
    @EnvironmentObject var dataService : ProductionDataService

    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var jobBoard : JobBoard
    @StateObject var VM : JobBoardViewModel

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                ScrollView{
                    ForEach(VM.jobPosts) { jobPost in
                        NavigationLink(value: Route.jobPost(dataService: dataService, jobPost: jobPost), label: {
                            JobPostCardView(jobPost: jobPost)
                        })
                    }
                }
                HStack{
                    Button(action: {
                        VM.showNewJobPost.toggle()
                    }, label: {
                        Text("Post")
                            .modifier(ListButtonModifier())
                    })
                    .fullScreenCover(isPresented: $VM.showNewJobPost,onDismiss: {
                        Task{
                            if let currentCompany = masterDataManager.currentCompany {
                                do {
                                    try await VM.onLoad(companyId: currentCompany.id, boardId: jobBoard.id)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }, content: {
                        VStack{
                            HStack{
                                Spacer()
                                Button(action: {
                                    VM.showNewJobPost.toggle()
                                }, label: {
                                    Text("X")
                                        .modifier(DismissButtonModifier())
                                })
                            }
                            CreateNewJobPost(dataService: dataService, jobBoard: jobBoard)
                        }
                        .padding(8)
                    })
                    Spacer()
                    Button(action: {
                        VM.showNewJobFilter.toggle()
                    }, label: {
                        Text("Filter")
                            .modifier(ListButtonModifier())
                    })
                    .fullScreenCover(isPresented: $VM.showNewJobFilter, content: {
                        VStack{
                            HStack{
                                Spacer()
                                Button(action: {
                                    VM.showNewJobFilter.toggle()
                                }, label: {
                                    Text("X")
                                        .modifier(DismissButtonModifier())
                                })
                            }
                            Text("Show New Job Filter")
                        }
                        .padding(8)
                    })
                }
            }
            .padding(8)
        }
        .navigationTitle(jobBoard.name)
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, boardId: jobBoard.id)
                } catch {
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    JobBoardView()
//}
