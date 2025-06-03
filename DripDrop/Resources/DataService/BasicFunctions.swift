//
//  BasicFunctions.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/15/24.
//

import Foundation

final class BasicFunctions {
    static let shared = BasicFunctions()
    private init(){}
    //DEVELOPER ADD ALL MY FILTERING FUNCTIONS INTO HERE
    
    //Customer Search Function
    func filterCustomerList(searchTerm:String,customers:[Customer])->[Customer] {
            //very facncy Search Bar
            var filteredListOfCustomers:[Customer] = []
            for customer in customers {
                let phone = customer.phoneNumber ?? "0"
                let replacedPhone1 = phone.replacingOccurrences(of: ".", with: "")
                let replacedPhone2 = replacedPhone1.replacingOccurrences(of: "-", with: "")
                let replacedPhone3 = replacedPhone2.replacingOccurrences(of: " ", with: "")
                let replacedPhone4 = replacedPhone3.replacingOccurrences(of: ".", with: "")
                let replacedPhone5 = replacedPhone4.replacingOccurrences(of: "(", with: "")
                let replacedPhone6 = replacedPhone5.replacingOccurrences(of: ")", with: "")
                
                let address = (customer.billingAddress.streetAddress ) + " " + (customer.billingAddress.city ) + " " + (customer.billingAddress.state ) + " " + (customer.billingAddress.zip )
                let company:String = customer.company ?? "0"
                let fullName = customer.firstName + " " + customer.lastName
                if customer.firstName.lowercased().contains(searchTerm.lowercased()) || customer.lastName.lowercased().contains(searchTerm.lowercased()) || replacedPhone6.lowercased().contains(searchTerm.lowercased()) || customer.email.lowercased().contains(searchTerm.lowercased()) || address.lowercased().contains(searchTerm.lowercased()) || company.lowercased().contains(searchTerm.lowercased()) || fullName.lowercased().contains(searchTerm.lowercased()){
                    filteredListOfCustomers.append(customer)
                }
            }
        return filteredListOfCustomers
    }
}
