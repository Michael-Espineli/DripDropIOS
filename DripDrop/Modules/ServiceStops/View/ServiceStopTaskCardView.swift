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
    var body: some View {
        HStack{
            Image(systemName: task.status == .finished ? "checkmark.circle.fill":"circle")
                .font(.headline)
                .foregroundColor(task.status == .finished ? Color.poolGreen : Color.primary)
                .padding(3)

            Text(task.name)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
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
