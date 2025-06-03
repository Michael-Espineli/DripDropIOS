//
//  JobPostCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import SwiftUI

struct JobPostCardView: View {
    @State var jobPost : JobPost

    var body: some View {
        VStack{
            HStack{
                Text(jobPost.ownerName)
                switch jobPost.ownerType {
                case .company:
                    Image(systemName: "person.crop.square.fill")
                case .client:
                    Image(systemName: "building.columns.fill")
                }
                Spacer()
                switch jobPost.status {
                case .open:
                    Text(jobPost.status.rawValue)

                case .closed:
                    Text(jobPost.status.rawValue)
                        .modifier(DismissButtonModifier())
                case .inProgress:
                    Text(jobPost.status.rawValue)

                }

            }
            HStack{
                
                Text(jobPost.jobType.rawValue)
                Spacer()
                Text(shortDate(date: jobPost.datePosted))
            }
            HStack{
                
                Text(jobPost.rateType.rawValue) // Rate Type
                Spacer()
                switch jobPost.rateType {
                case .negotiable:
                    Text("\(Double(jobPost.rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                case .takingEstimates:
                    Text("")
                case .nonNegotiable:
                    Text("\(Double(jobPost.rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                }
            }
            ScrollView(.horizontal){
                HStack{
                    ForEach(jobPost.tags,id: \.self) { tag in
                        Text(tag)
                            .modifier(AddButtonModifier())
                    }
                }
            }
        }
        .modifier(ListButtonModifier())
    }
}
struct JobPostCardViewSquare: View {
    @State var jobPost : JobPost

    var body: some View {
        VStack{
            HStack{
                Text(jobPost.ownerName)
                switch jobPost.ownerType {
                case .company:
                    Image(systemName: "person.crop.square.fill")
                case .client:
                    Image(systemName: "building.columns.fill")
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
                
                Text(jobPost.jobType.rawValue)
                Spacer()
                Text(shortDate(date: jobPost.datePosted))
            }
            HStack{
                
                Text(jobPost.rateType.rawValue) // Rate Type
                Spacer()
                switch jobPost.rateType {
                case .negotiable:
                    Text("\(Double(jobPost.rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                case .takingEstimates:
                    Text("")
                case .nonNegotiable:
                    Text("\(Double(jobPost.rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                }
            }
            HStack{
                Spacer()
                MessageBadge(count: 69)
            }
        }
        .frame(width: 200, height: 175)
        .modifier(ListButtonModifier())
    }
}

//#Preview {
//    JobPostCardView()
//}
