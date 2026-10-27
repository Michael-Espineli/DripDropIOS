    //
    //  WorkLogIn.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 12/11/24.
    //

import SwiftUI
import MapKit

@MainActor
final class WorkLogInViewModel: ObservableObject {
    private let dataService: any ProductionDataServiceProtocol
    init(dataService: any ProductionDataServiceProtocol) { self.dataService = dataService }
    @Published var isLoading = true
    @Published var workLogSheet: [WorkLog] = []
    @Published var currentLog: WorkLog?
    @Published var currentShiftId: String?
    @Published var duration = 0
    @Published var totalShiftDuration = 0
    @Published var showDetails = false
    @Published var errorMessage = ""
    @Published var availableOffers: [WorkOffer] = []
    @Published var selectedOfferId = ""
    func onLoad(company: Company, user: DBUser) { Task { await load(company: company, user: user) } }
    private func load(company: Company, user: DBUser) async {
        do {
            let state = try await FunctionsManager.shared.technicianWorkflow("manageTechnicianClock", payload: ["companyId":company.id,"action":"status"])
            if let shiftId = state["shiftId"] as? String, !shiftId.isEmpty {
                currentShiftId = shiftId
                workLogSheet = try await dataService.getWorkLogByShift(companyId: company.id, shiftId: shiftId, userId: user.id)
                currentLog = workLogSheet.first { $0.current }
            } else { currentShiftId = nil; currentLog = nil; workLogSheet = [] }
            availableOffers = try await dataService.fetchAcceptedWorkOffersForUser(companyId:company.id,userId:user.id).filter { offer in offer.id == currentLog?.workOfferId || (offer.claims ?? []).contains { $0.workerId == user.id && ["Accepted", "Scheduled", "In Progress"].contains($0.status) } }
            selectedOfferId = currentLog?.workOfferId ?? selectedOfferId
            tick()
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
    func tick() {
        duration = currentLog.map { max(0, Int(Date().timeIntervalSince($0.startTime))) } ?? 0
        totalShiftDuration = workLogSheet.filter { $0.type == .working }.reduce(0) { total, log in
            total + max(0, Int((log.endTime ?? Date()).timeIntervalSince(log.startTime)))
        }
    }
    private func transition(_ action: String, company: Company, user: DBUser) {
        guard !isLoading else { return }
        isLoading = true; errorMessage = ""
        Task {
            do {
                _ = try await FunctionsManager.shared.technicianWorkflow("manageTechnicianClock", payload: ["companyId": company.id, "action": action, "requestId": UUID().uuidString, "offerId": selectedOfferId])
                await load(company: company, user: user)
            } catch { errorMessage = error.localizedDescription; isLoading = false }
        }
    }
    func clockIn(company: Company, user: DBUser) { transition("clockIn", company: company, user: user) }
    func clockOut(company: Company, user: DBUser, newType: WorkLogType?) { transition("clockOut", company: company, user: user) }
    func updateCurrentShift(company: Company, user: DBUser, newType: WorkLogType?) {
        transition(newType == .working ? "working" : newType == .onBreak ? "break" : "lunch", company: company, user: user)
    }
}
struct WorkLogIn: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : WorkLogInViewModel
    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: WorkLogInViewModel(dataService: dataService))
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                VStack{
                    form
                    if VM.showDetails {
                        ScrollView{
                            list
                        }
                    }
                }
                .padding(8)
                .disabled(VM.isLoading)
                .opacity(VM.isLoading ? 0.75 : 1)
            }
            if VM.isLoading {
                ProgressView()
            }
        }
        .task{
            if let user = masterDataManager.user, let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(company : currentCompany, user: user)
            }
        }
        .onReceive(timer) { time in
            if !VM.isLoading {
                VM.tick()
            }
        }
    }
}
    //
    //#Preview {
    //    WorkLogIn()
    //}

extension WorkLogIn {
    var form: some View {
        VStack{
            if !VM.errorMessage.isEmpty { Text(VM.errorMessage).foregroundStyle(.red) }
            Picker("Work allocation", selection: $VM.selectedOfferId) {
                Text("General shift / route work").tag("")
                ForEach(VM.availableOffers) { offer in Text(offer.title).tag(offer.id) }
            }
            if VM.currentLog != nil {
                Button("Switch Work Allocation") {
                    if let company = masterDataManager.currentCompany, let user = masterDataManager.user { VM.updateCurrentShift(company:company,user:user,newType:.working) }
                }.font(.caption)
            }
            if let currentLog = VM.currentLog {
                HStack{
                    Text(currentLog.companyName)
                    Spacer()
                }
                HStack{
                    switch currentLog.type {
                    case .working:
                        Text(currentLog.type.rawValue)
                            .modifier(SubmitButtonModifier())
                    case .onBreak:
                        Text(currentLog.type.rawValue)
                            .modifier(YellowButtonModifier())
                    case .onLunch:
                        Text(currentLog.type.rawValue)
                            .modifier(YellowButtonModifier())
                    }
                    Spacer()
                }
                .lineLimit(1)
                HStack{
                    Text("Start : \(time(date: currentLog.startTime))")
                    if let endTime = currentLog.endTime {
                        Text("End : \(time(date: endTime)) (\(displayNumberAsMinAndHourAndSecond(seconds: timeBetweenAsSeconds(start: currentLog.startTime, end: endTime))))")
                    } else {
                        Text("(\(displayNumberAsMinAndHourAndSecond(seconds: VM.duration)))")
                    }
                    Spacer()
                }
                .lineLimit(1)
                switch currentLog.type {
                case .working:
                    Button(action: {
                        if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                            VM.updateCurrentShift(company: currentCompany, user: user, newType: .onBreak)
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Go On Break")
                            Spacer()
                        }
                        .modifier(AddButtonModifier())
                    })
                    Button(action: {
                        if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                            VM.updateCurrentShift(company: currentCompany, user: user, newType: .onLunch)
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Go On Lunch")
                            Spacer()
                        }
                        .modifier(AddButtonModifier())
                    })
                    Button(action: {
                        if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                            VM.clockOut(company: currentCompany, user: user, newType: nil)
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Clock Out")
                            Spacer()
                        }
                        .modifier(DismissButtonModifier())
                    })
                    
                case .onBreak, .onLunch:
                    Button(action: {
                        if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                            VM.updateCurrentShift(company: currentCompany, user: user, newType: .working)
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Back To Work")
                            Spacer()
                        }
                        .modifier(SubmitButtonModifier())
                    })
                }
                HStack{
                    Text("Total : (\(displayNumberAsMinAndHourAndSecond(seconds: VM.totalShiftDuration)))")
                    Spacer()
                    Button(action: {
                        VM.showDetails.toggle()
                    }, label: {
                        if VM.showDetails {
                            Text("Collapse")
                                .modifier(DismissButtonModifier())
                        } else {
                            Text("Expand")
                                .modifier(AddButtonModifier())
                        }
                    })
                }
            } else {
                if let company = masterDataManager.currentCompany {
                    HStack{
                        Text(company.name)
                        Spacer()
                    }
                    Button(action: {
                        if let user = masterDataManager.user {
                            VM.clockIn(company: company, user: user)
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            Text("Clock in")
                            Spacer()
                        }
                        .modifier(SubmitButtonModifier())
                    })
                }
            }
        }
        .modifier(ListButtonModifier())
        
    }
    var list: some View {
        VStack{
            ForEach(VM.workLogSheet){ log in
                WorkLogCardView(workLog: log)
            }
        }
    }
}
