//
//  CustomerSetUpSchedule.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/13/24.
//

import SwiftUI

struct CustomerLocationSetUpSchedule: View {
    let customer:Customer
    let location:ServiceLocation?
    var body: some View {
        VStack{
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
    }
}

#Preview {
    CustomerLocationSetUpSchedule(customer: MockDataService.mockCustomer, location: MockDataService.mockServiceLocation)
}
