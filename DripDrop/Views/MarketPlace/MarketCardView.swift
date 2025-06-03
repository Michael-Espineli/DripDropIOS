//
//  MarketCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/3/24.
//

import SwiftUI

struct MarketCardView: View {
    let job : Job 
    @State private var cardFrame: CGRect = .zero
    //Developer Add a way to store and pull these
    @State var descriptors:[JobDescriptors] = [
        JobDescriptors(text: "Super Hello"),
        JobDescriptors(text: "Super Hello"),
        JobDescriptors(text: "Super Hello"),
        JobDescriptors(text: "Super Hello")

            ]
    var body: some View {
        ScrollView(.vertical){
            LazyVStack(spacing: 0){
                headerCell
                    .frame(height: 700)
                aboutMeSection
                    .padding(.horizontal,24)
                    .padding(.vertical,24)
                descriptorView
                    .padding(.horizontal,24)
                    .padding(.vertical,24)
                icons
                    .padding(.top, 60)
                    .padding(.bottom, 60)
                    .padding(.horizontal,32)
            }
            .scrollIndicators(.hidden)
            .background(Color.lightBlue)
            .overlay(
                superLike
                .padding(24)
                , alignment: .bottomTrailing
            )
            .cornerRadius(32)
            .readingFrame{ frame in
                cardFrame = frame
            }
        }
    }
    private func sectionTitle(title:String) -> some View{
        Text(title)
            .font(.body)
            .foregroundColor(Color.gray)
        
    }
    private var superLike: some View {
        Image(systemName: "hexagon.fill")
            .foregroundColor(Color.poolBlue)
            .font(.system(size: 60))
            .overlay(
                Image(systemName: "star.fill")
                    .foregroundColor(Color.listColor)
                    .font(.system(size: 30,weight: .medium))
            )
            .onTapGesture {
                
            }
    }
    private var icons: some View {
        VStack(spacing:24){
            HStack(spacing:0){
                Circle()
                    .fill(Color.poolBlue)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.title)
                            .fontWeight(.semibold)
                    )
                    .frame(width: 60,height: 60)
                    .onTapGesture {
                        
                    }
                Spacer(minLength: 0)
                Circle()
                    .fill(Color.poolBlue)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.title)
                            .fontWeight(.semibold)
                    )
                    .frame(width: 60,height: 60)
                    .onTapGesture {
                        
                    }
            }
            Text("Hide and Report")
                .font(.headline)
                .foregroundColor(Color.gray)
                .padding(8)
                .background(Color.black.opacity(0.001))
                .onTapGesture {
                    
                }
        }
    }
    private var descriptorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8){
                sectionTitle(title: "Descriptors")
                DetailsGridView(jobDescriptors: descriptors)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    private var aboutMeSection: some View {
        VStack(alignment: .leading, spacing: 12){
            sectionTitle(title: "About Me")
            
            Text("User is about me")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(Color.listColor)
            HStack(spacing:0){
                WrenchMessage()
                Text("Send A Message")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding([.horizontal,.trailing],8)
            .foregroundColor(Color.white)
            .background(Color.poolBlue)
            .cornerRadius(32)
        }
        .frame(maxWidth: .infinity,alignment:.leading)
        .padding(.horizontal, 24)
    }
    private var headerCell: some View {
        ZStack(alignment: .bottomLeading){
            Image("zenitsu")
                .resizable()
            VStack(alignment: .leading,spacing: 8){
                Text("\(job.customerName)")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                HStack(spacing:4){
                    Image(systemName: "suitcase")
                    Text("Work")
                }
                HStack(spacing:4){
                    Image(systemName: "graduationcap")
                    Text("Education")
                }
                WrenchMessage()
            }
            .padding(24)
            .font(.callout)
            .fontWeight(.medium)
            .foregroundColor(Color.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [
                    .black.opacity(0.1),
                    .black.opacity(0.8)
                ],
                               startPoint: .top,
                               endPoint: .bottom)
            )
        }
    }
}

struct MarketCardView_Previews: PreviewProvider {
    static var previews: some View {
        MarketCardView(
            job: Job(
                id: "",
                internalId: "J",
                type: "",
                dateCreated: Date(),
                description: "",
                operationStatus: .estimatePending,
                billingStatus: .draft,
                customerId: "",
                customerName: "Bob Holiday",
                serviceLocationId: "",
                serviceStopIds: [],
                laborContractIds: [],
                adminId: "",
                adminName: "",
                rate: 160,
                laborCost: 40,
                otherCompany: false,
                receivedLaborContractId: "",
                receiverId: "",
                senderId : "",
                dateEstimateAccepted: nil,
                estimateAcceptedById: nil,
                estimateAcceptType: nil,
                estimateAcceptedNotes: nil,
                invoiceDate: nil,
                invoiceRef: nil,
                invoiceType: nil,
                invoiceNotes: nil
            )
        )
    }
}
