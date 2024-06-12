//
//  ServiceStopTaskView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/18/24.
//

import SwiftUI

struct ServiceStopTaskView: View {
    @EnvironmentObject private var VM: ServiceStopDetailViewModel
    let serviceStop:ServiceStop
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView {
                Text("Service Stop Task View")
                ForEach(serviceStop.checkList){ item in
                    HStack{
                        ZStack{
                            Image(systemName: "circle.fill")
                                .foregroundColor(Color.white)
                            Image(systemName: item.finished ? "checkmark.circle" : "circle")
                                .foregroundColor(item.finished ? Color.green : Color.red)
                        }
                        Text(item.description)
                    }
                }
            }
            .padding(.horizontal,8)
        }
    }
}

struct ServiceStopTaskView_Previews: PreviewProvider {
    static var previews: some View {
        ServiceStopTaskView(serviceStop: MockDataService.mockServicestop)
    }
}
