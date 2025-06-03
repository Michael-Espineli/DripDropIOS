//
//  CreateNewJobPost.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/19/25.
//

import SwiftUI
@MainActor
final class CreateNewJobPostViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published var name : String = ""
    @Published var description : String = ""    
    @Published var rate : String = ""

    @Published var tag : String = ""
    @Published var jobType : JobType = .oneTime
    @Published var tags : [String] = []
    
    func postNewJobToBoard(currentCompany:Company,user:DBUser,boardId:String) async throws {
        let userName = user.firstName + " " + user.lastName
        if let rateInt = Double(rate){
            var rateDouble = rateInt*100
            var rateCents = Int(floor(rateDouble))
            
            let jobPost = JobPost(
                boardId: boardId,
                ownerId: user.id,
                ownerName: userName,
                companyId: currentCompany.id,
                companyName: currentCompany.name,
                datePosted: Date(),
                ownerType: .company,
                name: name,
                description: description,
                jobType: jobType,
                tags: tags,
                rateType: .nonNegotiable,
                rate : rateCents,
                status: .open,
                address: Address(
                    streetAddress: "",
                    city: "",
                    state: "",
                    zip: "",
                    latitude: 32,
                    longitude: -117
                ),
                publicLat: 32.789887,
                publicLng: -116.991147,
                photoUrls: []
            )
            
                //Post
            try await dataService.createNewJobPost(jobPost: jobPost)
            
                //Clear
            self.name = ""
            self.description = ""
            self.tags = []
            self.jobType = .oneTime
            self.tag = ""
        }
    }
}

struct CreateNewJobPost: View {
    init(dataService: any ProductionDataServiceProtocol, jobBoard:JobBoard){
        _VM = StateObject(wrappedValue: CreateNewJobPostViewModel(dataService: dataService))
        _jobBoard = State(wrappedValue: jobBoard)
    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : CreateNewJobPostViewModel
    @State var jobBoard : JobBoard
    
    var body: some View {
        ZStack {
            ScrollView{
                HStack{
                    Text("Board Name: \(jobBoard.name)")
                }
                HStack{
                    Text("Name")
                    TextField(
                        "Name",
                        text: $VM.name
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("Description")
                    TextField(
                        "Description",
                        text: $VM.description
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                Picker("Type", selection: $VM.jobType) {
                    ForEach(JobType.allCases, id:\.self){ datum in
                        Text(datum.rawValue).tag(datum)
                    }
                }
                .pickerStyle(.segmented)

                
                HStack{
                    Text("Tag")
                }
                HStack{
                    TextField(
                        "Tag",
                        text: $VM.tag
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    Button(action: {
                        VM.tags.append(VM.tag)
                        VM.tag = ""
                    }, label: {
                        Text("Add")
                            .modifier(AddButtonModifier())
                    })
                }
                ForEach(VM.tags, id:\.self) { tag in
                    Button(action: {
                        VM.tags.remove(tag)
                    }, label: {
                        HStack{
                            Text(tag)
                                .padding(8)
                                .background(Color.poolBlue)
                                .cornerRadius(8)
                                .padding(8)
                            Text("X")
                                .modifier(DismissButtonModifier())
                        }
                        
                    })
                }
                HStack{
                    Button(action: {
                        Task{
                            if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                                do {
                                    try await VM.postNewJobToBoard(currentCompany: currentCompany, user: user, boardId: jobBoard.id)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }, label: {
                        Text("Submit")
                            .modifier(SubmitButtonModifier())
                    })
                }
            }
        }
    }
}

//#Preview {
//    CreateNewJobPost()
//}
