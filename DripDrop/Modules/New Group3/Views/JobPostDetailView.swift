//
//  JobPostDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import SwiftUI
import MapKit
@MainActor
final class JobPostDetailViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var publicJobBoards : [JobBoard] = []
    @Published private(set) var jobBoards : [JobBoard] = []
    @Published private(set) var owenedJobs : [JobPost] = []
    @Published private(set) var postedCompany : Company? = nil

    func onLoad(companyId:String,jobPost:JobPost) async throws {
        self.postedCompany = try await dataService.getCompany(companyId: jobPost.companyId)
    }
}

struct JobPostDetailView: View {
    init(dataService: any ProductionDataServiceProtocol, jobPost:JobPost){
        _VM = StateObject(wrappedValue: JobPostDetailViewModel(dataService: dataService))
        _jobPost = State(wrappedValue: jobPost)
    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : JobPostDetailViewModel
    @State var jobPost : JobPost
    @State var isSaved : Bool = false
    var body : some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            if let user = masterDataManager.user {
                if user.id == jobPost.ownerId {
                    ownerInfo
                } else {
                    publicInfo
                }
            }
        }
        .navigationTitle("Job Post Details")
        .toolbar{
            Button(action: {
                isSaved.toggle()
            }, label: {
                Image(systemName: "heart.fill")
                    .foregroundColor(isSaved ? Color.red : Color.white)
                    .padding(.horizontal,8)
                    .padding(.vertical,4)
                    .background(Color.gray)
                    .cornerRadius(4)
                    .foregroundColor(Color.white)
                    .fontDesign(.monospaced)
            })
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, jobPost: jobPost)
                } catch {
                    print("Error  - [JobPostDetailView]")
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    JobPostDetailView()
//}
extension JobPostDetailView {
    var publicInfo : some View  {
        VStack{
            
            ScrollView{
                    VStack{
                        GeneralBackgroundMapView(coordinates: CLLocationCoordinate2D(latitude: jobPost.publicLat, longitude: jobPost.publicLng))
                            .frame(height: 150)
                    }
                    .padding(0)
                VStack{
                    VStack{
                        Text(jobPost.address.zip)
                        HStack{
                            Text("Posted: \(fullDate(date: jobPost.datePosted))")
                            Text("(\(daysBetween(start: jobPost.datePosted, end: Date()))) days since")
                                .font(.footnote)
                            Spacer()
                            
                            switch jobPost.status {
                                case .open:
                                    Text(jobPost.status.rawValue)
                                        .modifier(AddButtonModifier())
                                case .closed:
                                    Text(jobPost.status.rawValue)
                                        .modifier(DismissButtonModifier())
                                case .inProgress:
                                    Text(jobPost.status.rawValue)
                                        .modifier(YellowButtonModifier())
                            }
                        }
                        HStack{
                            VStack{
                                Text(jobPost.ownerName)

                                Text(jobPost.ownerType.rawValue)

                            }
                            Spacer()
                            if let postedCompany = VM.postedCompany {
                                NavigationLink(value: Route.companyProfile(company: postedCompany, dataService: dataService), label: {
                                    HStack{
                                        Text("See Profile")
                                        Image(systemName: "arrow.right")
                                    }
                                    .modifier(RedLinkModifier())
                                })
                            } else {
                                HStack{
                                    Text("See Profile")
                                    Image(systemName: "arrow.right")
                                }
                                .modifier(RedLinkModifier())
                                .opacity(0.6)
                            }
                        }
                    }
                    VStack{
                        
                        HStack{
                            Spacer()
                            Text("Money Info")
                                .font(.headline)
                            Spacer()
                        }
                        Divider()
                        HStack{
                            Text(jobPost.jobType.rawValue)
                            Spacer()
                        }
                        
                        HStack{
                            Text(jobPost.rateType.rawValue)
                            Spacer()
                        }
                        
                        HStack{
                            switch jobPost.rateType {
                            case .negotiable:
                                Text("\(Double(jobPost.rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                            case .takingEstimates:
                                Text("")
                            case .nonNegotiable:
                                Text("\(Double(jobPost.rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                            }
                            Spacer()
                        }
                    }
                    VStack{
                        
                        HStack{
                            Spacer()
                            Text("Job Info")
                                .font(.headline)
                            Spacer()
                        }
                        Divider()
                        VStack{
                            HStack{
                                Text(jobPost.jobType.rawValue)
                                Spacer()
                            }
                            
                            HStack{
                                Text(jobPost.name)
                                Spacer()
                            }
                            
                            HStack{
                                Text(jobPost.description)
                                Spacer()
                            }
                            
                            HStack{
                                Text("Task List")
                                Spacer()
                            }
                        }
                        Divider()
                        ScrollView(.horizontal){
                            HStack{
                                ForEach(jobPost.tags,id:\.self){ tag in
                                    HStack{
                                        Text(tag)
                                    }
                                }
                            }
                        }
                        DripDropStoredImageRow(images: jobPost.photoUrls)
                    }
                }
                .padding(8)
            }
            HStack{
                Button(action: {
                    
                }, label: {
                    Image(systemName: "message.fill")
                        .font(.headline)
                        .modifier(AddButtonModifier())
                })
                Spacer()
                Button(action: {
                    
                }, label: {
                    Text("Request Job")
                        .modifier(AddButtonModifier())
                })
                Spacer()
                Button(action: {
                    
                }, label: {
                    Image(systemName: "message.fill")
                        .font(.headline)
                        .modifier(AddButtonModifier())
                })
            }
            .padding(.leading,8)
        }

    }
    
    var ownerInfo : some View  {
        VStack{
            
            ScrollView{
                    VStack{
//                        GeneralBackgroundMapView(coordinates: CLLocationCoordinate2D(latitude: jobPost.publicLat, longitude: jobPost.publicLng))
//                            .frame(height: 150)
                        
                        Text("Private")
                            .font(.footnote)
                            .foregroundColor(Color.poolRed)
                        VStack{
                            Text(jobPost.address.streetAddress)
                            HStack{
                                Text("\(jobPost.address.city), \(jobPost.address.state) \(jobPost.address.zip)")
                            }
                        }
                    }
                    .padding(0)
                VStack{
                    VStack{
                        HStack{
                            VStack{
                                Text("Posted: \(fullDate(date: jobPost.datePosted))")
                                Text("(\(daysBetween(start: jobPost.datePosted, end: Date()))) days since")
                                    .font(.footnote)
                            }
                            Spacer()
                            switch jobPost.status {
                                case .open:
                                    Text(jobPost.status.rawValue)
                                        .modifier(AddButtonModifier())
                                case .closed:
                                    Text(jobPost.status.rawValue)
                                        .modifier(DismissButtonModifier())
                                case .inProgress:
                                    Text(jobPost.status.rawValue)
                                        .modifier(YellowButtonModifier())
                            }
                        }
                        HStack{
                            VStack{
                                Text("\(jobPost.ownerName) (you)")
                                Text(jobPost.ownerType.rawValue)
                            }
                            Spacer()
                            Button(action: {
                                
                            }, label: {
                                HStack{
                                    Text("See Profile")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.footnote)
                                .padding(3)
                                .foregroundColor(Color.poolRed)
                                .background(Color.gray.opacity(0.75))
                                .cornerRadius(5)
                            })
                        }
                    }
                    VStack{
                        
                        HStack{
                            Spacer()
                            Text("Money Info")
                                .font(.headline)
                            Spacer()
                        }
                        Divider()
                        HStack{
                            Text(jobPost.jobType.rawValue)
                            Spacer()
                        }
                        
                        HStack{
                            Text(jobPost.rateType.rawValue)
                            Spacer()
                        }
                        
                        HStack{
                            switch jobPost.rateType {
                            case .negotiable:
                                Text("\(Double(jobPost.rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                            case .takingEstimates:
                                Text("")
                            case .nonNegotiable:
                                Text("\(Double(jobPost.rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                            }
                            Spacer()
                        }
                    }
                    VStack{
                        
                        HStack{
                            Spacer()
                            Text("Job Info")
                                .font(.headline)
                            Spacer()
                        }
                        Divider()
                        HStack{
                            Text(jobPost.jobType.rawValue)
                            Spacer()
                        }
                        
                        HStack{
                            Text(jobPost.name)
                            Spacer()
                        }
                        
                        HStack{
                            Text(jobPost.description)
                            Spacer()
                        }
                        
                            
                        HStack{
                            Spacer()
                            Text("Tags")
                                .font(.headline)
                            Spacer()
                        }
                        Divider()
                        ScrollView(.horizontal){
                            HStack{
                                ForEach(jobPost.tags,id:\.self){ tag in
                                    HStack{
                                        Text(tag)
                                    }
                                }
                            }
                        }
                        DripDropStoredImageRow(images: jobPost.photoUrls)
                    }
                    Divider()
                    VStack{
                        HStack{
                            Text("Messages")
                                .font(.headline)
                            Spacer()
                            MessageBadge(count: 15)
                        }
                    }
                }
                .padding(8)
            }
            HStack{
                Button(action: {
                    
                }, label: {
                    Image(systemName: "message.fill")
                        .font(.headline)
                        .modifier(AddButtonModifier())
                })
                Spacer()
                Button(action: {
                    
                }, label: {
                    Text("Request Job")
                        .modifier(AddButtonModifier())
                })
                Spacer()
                Button(action: {
                    
                }, label: {
                    Image(systemName: "message.fill")
                        .font(.headline)
                        .modifier(AddButtonModifier())
                })
            }
            .padding(.leading,8)
        }

    }
}
