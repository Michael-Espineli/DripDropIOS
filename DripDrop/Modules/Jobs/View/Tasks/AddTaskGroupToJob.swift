//
//  AddTaskGroupToJob.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/4/24.
//

import SwiftUI

struct AddTaskGroupToJob: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var VM : AddNewTaskToJobViewModel
    @State var jobId:String
    @State var taskTypes:[String]
    @State var customerId:String
    @State var serviceLocationId:String

    init(dataService:any ProductionDataServiceProtocol,jobId:String,taskTypes:[String],customerId:String,serviceLocationId:String){
        _VM = StateObject(wrappedValue: AddNewTaskToJobViewModel(dataService: dataService))

        _jobId = State(wrappedValue: jobId)
        _taskTypes = State(wrappedValue: taskTypes)
        _customerId = State(wrappedValue: customerId)
        _serviceLocationId = State(wrappedValue: serviceLocationId)

    }
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    AddTaskGroupToJob()
}
