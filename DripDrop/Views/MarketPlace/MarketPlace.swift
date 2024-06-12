//
//  MarketPlaceView.swift
//  ClientSide
//
//  Created by Michael Espineli on 11/30/23.
//

import SwiftUI

struct MarketPlaceView: View {
    @StateObject var profileVM = ProfileViewModel()
    @State private var allJobs : [Job] = [
        Job(
            id: "1",
            type: "",
            dateCreated: Date(),
            description: "",
            operationStatus: .estimatePending,
            billingStatus: .draft,
            customerId: "",
            customerName: "Bob Holiday",
            serviceLocationId: "",
            serviceStopIds: [],
            adminId: "",
            adminName: "",
            jobTemplateId: "",
            installationParts: [],
            pvcParts: [],
            electricalParts: [],
            chemicals: [],
            miscParts: [],
            rate: 160,
            laborCost: 40
        ),
        Job(
            id: "2",
            type: "",
            dateCreated: Date(),
            description: "",
            operationStatus: .estimatePending,
            billingStatus: .draft,
            customerId: "",
            customerName: "Mark Bagula",
            serviceLocationId: "",
            serviceStopIds: [],
            adminId: "",
            adminName: "",
            jobTemplateId: "",
            installationParts: [],
            pvcParts: [],
            electricalParts: [],
            chemicals: [],
            miscParts: [],
            rate: 160,
            laborCost: 40
        ),
        Job(
            id: "3",
            type: "",
            dateCreated: Date(),
            description: "",
            operationStatus: .estimatePending,
            billingStatus: .draft,
            customerId: "",
            customerName: "Erin Mcormick",
            serviceLocationId: "",
            serviceStopIds: [],
            adminId: "",
            adminName: "",
            jobTemplateId: "",
            installationParts: [],
            pvcParts: [],
            electricalParts: [],
            chemicals: [],
            miscParts: [],
            rate: 160,
            laborCost: 40
        ),
        Job(
            id: "4",
            type: "",
            dateCreated: Date(),
            description: "",
            operationStatus: .estimatePending,
            billingStatus: .draft,
            customerId: "",
            customerName: "Diane Greenwood",
            serviceLocationId: "",
            serviceStopIds: [],
            adminId: "",
            adminName: "",
            jobTemplateId: "",
            installationParts: [],
            pvcParts: [],
            electricalParts: [],
            chemicals: [],
            miscParts: [],
            rate: 160,
            laborCost: 40
        ),
        Job(
            id: "5",
            type: "",
            dateCreated: Date(),
            description: "",
            operationStatus: .estimatePending,
            billingStatus: .draft,
            customerId: "",
            customerName: "Ben Shepherd",
            serviceLocationId: "",
            serviceStopIds: [],
            adminId: "",
            adminName: "",
            jobTemplateId: "",
            installationParts: [],
            pvcParts: [],
            electricalParts: [],
            chemicals: [],
            miscParts: [],
            rate: 160,
            laborCost: 40
        ),
        Job(
            id: "6",
            type: "",
            dateCreated: Date(),
            description: "",
            operationStatus: .estimatePending,
            billingStatus: .draft,
            customerId: "",
            customerName: "Steve Mcclure",
            serviceLocationId: "",
            serviceStopIds: [],
            adminId: "",
            adminName: "",
            jobTemplateId: "",
            installationParts: [],
            pvcParts: [],
            electricalParts: [],
            chemicals: [],
            miscParts: [],
            rate: 160,
            laborCost: 40
        )
    ]

    @State private var selectedIndex: Int = 0
    @State private var cardOffsets: [String:Bool] = [:]
    @State private var currentSwipeOffset: CGFloat = 0

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack(spacing: 12){
                header
                ZStack{
                    if !allJobs.isEmpty {
                        ForEach(Array(allJobs.enumerated()),id:\.offset) { (index, job) in
                            let isPrevious = (selectedIndex - 1) == index
                            let isCurrent = (selectedIndex) == index
                            let isNext = (selectedIndex + 1) == index
                            if isPrevious || isCurrent || isNext {
                                let offsetsValues = cardOffsets[job.id]
                                jobCardView(job: job, index: index)
                                    .zIndex(Double(allJobs.count - 1))
                                    .offset(x: offsetsValues == nil ? 0 : offsetsValues == true ? 900 : -900)
                            }
                        }
                    } else {
                        ProgressView()
                    }
                    overlaySwipeIndicators
                    .zIndex(9_999_999)
                }
                .frame(maxHeight: .infinity)
                .padding(4)
                .animation(.default, value: cardOffsets)
            }
        }
    }
    private func userDidSelectIndex(index: Int, isLike:Bool){
        let job = allJobs[index]
        cardOffsets[job.id] = isLike
        
        selectedIndex += 1
    }
    private var overlaySwipeIndicators: some View {
        ZStack{
            Circle()
                .fill(Color.gray.opacity(0.4))
                .overlay(
                    Image(systemName: "xmark")
                        .font(.title)
                        .fontWeight(.semibold)
                )
                .frame(width: 60, height: 60)
                .scaleEffect(abs(currentSwipeOffset) > 100 ? 1.5 : 1.0)
                .offset(x: min(-currentSwipeOffset,150))
                .frame(maxWidth: .infinity, alignment: .leading)

                .offset(x: -100)
            Circle()
                .fill(Color.gray.opacity(0.4))
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.title)
                        .fontWeight(.semibold)
                )
                .frame(width: 60, height: 60)
                .scaleEffect(abs(currentSwipeOffset) > 100 ? 1.5 : 1.0)
                .offset(x: min(-currentSwipeOffset,150))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(x: 100)
        }
        .animation(.default, value: currentSwipeOffset)
    }
    
    private var header: some View {
        VStack(spacing: 8){
            HStack(spacing:0) {
                HStack(spacing:0) {
                    Image(systemName: "line.horizontal.3")
                        .padding(8)
                        .foregroundColor(Color.white)
                        .background(Color.blue.opacity(0.001))
                        .onTapGesture {
                            
                        }
            
                    Image(systemName: "arrow.uturn.backward")
                        .padding(8)
                        .foregroundColor(Color.white)
                        .background(Color.blue.opacity(0.001))
                        .onTapGesture {
                            allJobs = [
                                Job(
                                    id: "1",
                                    type: "",
                                    dateCreated: Date(),
                                    description: "",
                                    operationStatus: .estimatePending,
                                    billingStatus: .draft,
                                    customerId: "",
                                    customerName: "Bob Holiday",
                                    serviceLocationId: "",
                                    serviceStopIds: [],
                                    adminId: "",
                                    adminName: "",
                                    jobTemplateId: "",
                                    installationParts: [],
                                    pvcParts: [],
                                    electricalParts: [],
                                    chemicals: [],
                                    miscParts: [],
                                    rate: 160,
                                    laborCost: 40
                                ),
                                Job(
                                    id: "2",
                                    type: "",
                                    dateCreated: Date(),
                                    description: "",
                                    operationStatus: .estimatePending,
                                    billingStatus: .draft,
                                    customerId: "",
                                    customerName: "Mark Bagula",
                                    serviceLocationId: "",
                                    serviceStopIds: [],
                                    adminId: "",
                                    adminName: "",
                                    jobTemplateId: "",
                                    installationParts: [],
                                    pvcParts: [],
                                    electricalParts: [],
                                    chemicals: [],
                                    miscParts: [],
                                    rate: 160,
                                    laborCost: 40
                                ),
                                Job(
                                    id: "3",
                                    type: "",
                                    dateCreated: Date(),
                                    description: "",
                                    operationStatus: .estimatePending,
                                    billingStatus: .draft,
                                    customerId: "",
                                    customerName: "Erin Mcormick",
                                    serviceLocationId: "",
                                    serviceStopIds: [],
                                    adminId: "",
                                    adminName: "",
                                    jobTemplateId: "",
                                    installationParts: [],
                                    pvcParts: [],
                                    electricalParts: [],
                                    chemicals: [],
                                    miscParts: [],
                                    rate: 160,
                                    laborCost: 40
                                ),
                                Job(
                                    id: "4",
                                    type: "",
                                    dateCreated: Date(),
                                    description: "",
                                    operationStatus: .estimatePending,
                                    billingStatus: .draft,
                                    customerId: "",
                                    customerName: "Diane Greenwood",
                                    serviceLocationId: "",
                                    serviceStopIds: [],
                                    adminId: "",
                                    adminName: "",
                                    jobTemplateId: "",
                                    installationParts: [],
                                    pvcParts: [],
                                    electricalParts: [],
                                    chemicals: [],
                                    miscParts: [],
                                    rate: 160,
                                    laborCost: 40
                                ),
                                Job(
                                    id: "5",
                                    type: "",
                                    dateCreated: Date(),
                                    description: "",
                                    operationStatus: .estimatePending,
                                    billingStatus: .draft,
                                    customerId: "",
                                    customerName: "Ben Shepherd",
                                    serviceLocationId: "",
                                    serviceStopIds: [],
                                    adminId: "",
                                    adminName: "",
                                    jobTemplateId: "",
                                    installationParts: [],
                                    pvcParts: [],
                                    electricalParts: [],
                                    chemicals: [],
                                    miscParts: [],
                                    rate: 160,
                                    laborCost: 40
                                ),
                                Job(
                                    id: "6",
                                    type: "",
                                    dateCreated: Date(),
                                    description: "",
                                    operationStatus: .estimatePending,
                                    billingStatus: .draft,
                                    customerId: "",
                                    customerName: "Steve Mcclure",
                                    serviceLocationId: "",
                                    serviceStopIds: [],
                                    adminId: "",
                                    adminName: "",
                                    jobTemplateId: "",
                                    installationParts: [],
                                    pvcParts: [],
                                    electricalParts: [],
                                    chemicals: [],
                                    miscParts: [],
                                    rate: 160,
                                    laborCost: 40
                                )
                            ]
                        }
                }
//                .frame(width: .infinity,alignment: .leading)
                Text("Market Place")
                    .font(.title)
                    .foregroundColor(Color.lightBlue)
//                    .frame(width: .infinity,alignment: .center)

                Image(systemName: "slider.horizontal.3")
                    .padding(8)
                    .foregroundColor(Color.white)
                    .background(Color.blue.opacity(0.001))
                    .onTapGesture {
                        
                    }
//                    .frame(width: .infinity,alignment: .center)
            }
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(Color.black)
        }
    }
    private func jobCardView(job: Job,index:Int) -> some View {
        MarketCardView(job: job)
            .withDragGesture(.horizontal,
                                                 minimumDistance: 15,
                             resets: true,
                                                 animation: .easeIn,
                             rotationMultiplier: 1.05,
//                                                 scaleMultiplier: 0.8,
                             onChanged: { dragOffset in
                currentSwipeOffset = dragOffset.width
            },
                             onEnded: { dragOffset in
                if dragOffset.width < -50 {
                    print("User did not Select: Please add Function")
                    userDidSelectIndex(index: index, isLike: false)

                } else if dragOffset.width > 50 {
                    print("User did Select: Please add Function")
                    userDidSelectIndex(index: index, isLike: true)
                }

            })
    }
}

struct MarketPlaceView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSignInView: Bool = false
        MarketPlaceView()
    }
}
extension MarketPlaceView {

}
