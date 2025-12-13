//
//  TestData+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/11/25.
//

import Foundation

extension TestDataViewModel {
    let mockCustomerList:[Customer] =  [
        Customer(
            id: "1",
            firstName: "Aphrodite",
            lastName: "Love, Sex and Beauty",
            email: "HotSex@hotmail.com",
            billingAddress: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            phoneNumber: "Aphrodite",
            phoneLabel: "619-555-6969",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "2",
            firstName: "Athena",
            lastName: "Reason, Wisdom and War",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "3",
            firstName: "Artemis",
            lastName: "Hunt",
            email: "HotSex@hotmail.com",
            billingAddress: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            phoneNumber: "Aphrodite",
            phoneLabel: "619-555-6969",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "4",
            firstName: "Aries",
            lastName: "Bloodlust and War",
            email: "HotSex@hotmail.com",
            billingAddress: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            phoneNumber: "Aphrodite",
            phoneLabel: "619-555-6969",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "5",
            firstName: "Apollo",
            lastName: "Son of Zeus",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "6",
            firstName: "Demeter",
            lastName: "Agriculture",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "7",
            firstName: "Dionysus",
            lastName: "Drunken Wine",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "8",
            firstName: "Hades",
            lastName: "Ruler of the Underworld",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "9",
            firstName: "Hera",
            lastName: "Hearth",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "10",
            firstName: "Poseidon",
            lastName: "Ocean, Horses and Earthquakes",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "11",
            firstName: "Zeus",
            lastName: "King of the Gods",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        )
    ]

}
