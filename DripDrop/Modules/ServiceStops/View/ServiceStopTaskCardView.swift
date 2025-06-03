//
//  ServiceStopTaskCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/4/24.
//

import SwiftUI
@MainActor
final class ServiceStopTaskCardViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var showAlert : Bool = false
    @Published var alertMessage:String = ""
    func finishServiceStopTask(companyId:String, serviceStopId: String, taskId: String, status: JobTaskStatus)async throws {
        try await dataService.updateServiceStopTaskStatus(companyId: companyId, serviceStopId: serviceStopId, taskId: taskId, status: status)
    }
}
struct ServiceStopTaskCardView: View {
    @EnvironmentObject var masterDataService : MasterDataManager
    @StateObject var VM : ServiceStopTaskCardViewModel

    init(dataService:any ProductionDataServiceProtocol,task:Binding<ServiceStopTask>,serviceStop:ServiceStop) {
        _VM = StateObject(wrappedValue: ServiceStopTaskCardViewModel(dataService: dataService))
        self._task = task
        _serviceStop = State(wrappedValue: serviceStop)
    }

    @State var serviceStop : ServiceStop
    @Binding var task : ServiceStopTask
    @State var finished:Bool = false
    @State var timeFinished:Date? = nil
    var body: some View {
        HStack{
            Image(systemName: task.status == .finished ? "checkmark.circle.fill":"circle")
                .font(.headline)
                .foregroundColor(task.status == .finished ? Color.poolGreen : Color.black)
                .padding(3)
            
            VStack(alignment:.leading){
                Text(task.name)
                    .lineLimit(1)
                HStack{
                    Spacer()
                    Text(task.type.rawValue)
                        .lineLimit(1)
                        .font(.footnote)
                }
                if let timeFinished {
                    HStack{
                        Spacer()
                        Text("Finished : \(time(date: timeFinished))")
                            .lineLimit(1)
                            .font(.footnote)
                    }
                }
            }
        }
        .modifier(ListButtonModifier())
        .opacity(task.status == .finished  ? 0.75 : 1)
        .padding(.horizontal,4)
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}
//#Preview {
//    ServiceStopTaskCardView()
//}
