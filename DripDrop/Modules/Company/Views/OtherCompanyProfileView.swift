//
//  OtherCompanyProfileView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import SwiftUI
import MapKit
import CoreLocation

struct OtherCompanyProfileView: View {
    @StateObject var VM : OtherCompanyProfileViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    init( dataService:any ProductionDataServiceProtocol,company:Company){
        _VM = StateObject(wrappedValue: OtherCompanyProfileViewModel(dataService: dataService,company: company))
        _company = State(wrappedValue: company)
    }
    @State var company: Company

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    actionBar
                    servicesSection
                    reviewsSection
                    serviceAreaSection
                }
                .padding(12)
            }
        }
        .navigationTitle(company.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let user = masterDataManager.user {
                do {
                    if let currentCompany = masterDataManager.currentCompany {
                        try await VM.getAssociatedBuisnesses(companyId: currentCompany.id)
                    } else {
                        try await VM.getSavedCompanies(userId: user.id)
                    }
                } catch {
                    print("[OtherCompanyProfileView][task] Error")
                    print(error)
                }
            }
        }
    }
}

extension OtherCompanyProfileView {
    @ViewBuilder
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(company.name)
                .font(.largeTitle).bold()
                .foregroundColor(.primary)
            // Add additional metadata or logo if available using company.photoUrl
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    var actionBar: some View {
        HStack {
            // Internal Chat navigation template
            NavigationLink(value: Route.initiateChat(dataService: dataService, userId: company.ownerId), label: {
                Text("Internal Chat")
                    .font(.subheadline).bold()
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
            })

            Spacer()

            Button {
                Task {
                    do {
                        if let user = masterDataManager.user {
                            if let currentCompany = masterDataManager.currentCompany {
                                //If there is a company selected Saved info to Company
                                if let business = VM.buisnessList.first(where: { $0.companyId == company.id }) {
                                    try await VM.deleteAssociatedBusinessToCompany(
                                        companyId: currentCompany.id,
                                        businessId: business.id
                                    )
                                } else {
                                    try await VM.saveAssociatedBusinessToCompany(
                                        companyId: currentCompany.id,
                                        business: AssociatedBusiness(
                                            companyId: company.id,
                                            companyName: company.name
                                        )
                                    )
                                }
                                try await VM.getAssociatedBuisnesses(companyId: currentCompany.id)
                            } else {
                                //If there is not a company selected Save into to User
                                if let business = VM.savedBuisnessList.first(where: { $0.companyId == company.id }) {
                                    try await VM.deleteAssociatedBusinessToCompany(
                                        userId: user.id,
                                        businessId: business.id
                                    )
                                } else {
                                    try await VM.saveAssociatedBusinessToUser(
                                        userId: user.id,
                                        business: AssociatedBusiness(
                                            companyId: company.id,
                                            companyName: company.name
                                        )
                                    )
                                }
                                try await VM.getSavedCompanies(userId: user.id)
                            }
                        }
                    } catch {
                        print("[OtherCompanyProfileView][Button on action Bar] Associate toggle error: \(error)")
                    }
                    
                }
            } label: {
                if masterDataManager.currentCompany != nil{
                    let isAssociated = VM.buisnessList.contains(where: { $0.companyId == company.id })
                    Text(isAssociated ? "Unsave Associate Buisness" : "Save As Associate")
                        .font(.subheadline).bold()
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(isAssociated ? Color.red : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    let isAssociated = VM.savedBuisnessList.contains(where: { $0.companyId == company.id })
                    Text(isAssociated ? "Unsave Buisness" : "Save Business")
                        .font(.subheadline).bold()
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(isAssociated ? Color.red : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services")
                .font(.title3).bold()
                .foregroundColor(.primary)

            if !company.services.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(company.services, id: \.self) { service in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(Color.gray.opacity(0.4)).frame(width: 6, height: 6).padding(.top, 7)
                            Text(service).foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("No services listed.")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reviews")
                .font(.title3).bold()
                .foregroundColor(.primary)

            if VM.isLoadingReviews {
                ProgressView().padding(.vertical)
            } else if VM.reviews.isEmpty {
                Text("No reviews yet.")
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(VM.reviews) { review in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(review.reviewerName).bold()
                                Spacer()
                                Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            HStack(spacing: 4) {
                                ForEach(0..<5, id: \.self) { idx in
                                    Image(systemName: idx < Int(round(review.rating)) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                                Spacer()
                                if review.verified {
                                    Text("Verified").font(.caption2).padding(4).background(Color.green.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            Text(review.description).foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .task {
            await VM.loadReviewsIfNeeded()
        }
    }

    @ViewBuilder
    var serviceAreaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Service Area")
                .font(.title3).bold()
                .foregroundColor(.primary)

            if let geocodeError = VM.geocodeError {
                Text(geocodeError).foregroundColor(.red)
            }

            Map(coordinateRegion: $VM.mapRegion, annotationItems: VM.mapLocations) { loc in
                MapMarker(coordinate: loc.coordinate, tint: .blue)
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .task {
            await VM.geocodeServiceZipCodes()
        }
    }



}
