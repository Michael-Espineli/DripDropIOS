//
//  ChangeUserEmailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/3/24.
//

import SwiftUI

struct ChangeUserEmailView: View {
    @StateObject private var VM : AuthenticationViewModel
    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
    }
    
    @State var firstEmail:String = ""
    @State var confirmationEmail:String = ""

    var body: some View {
        VStack{
            HStack{
                Text("Change Email ")
            }
            TextField(
                "Email",
                text: $firstEmail
            )
            if firstEmail != confirmationEmail {
                Text("Passwords Do Not Match")
                    .foregroundColor(Color.red)
            }
            TextField(
                "Confirm Email",
                text: $confirmationEmail
            )
            Button(action: {
                Task{
                    do {
                        try VM.updateEmail(email: firstEmail, confimationEmail: confirmationEmail)
                    } catch {
                        print("Error")
                    }
                }
            }, label: {
                Text("Submit")
                    .modifier(SubmitButtonModifier())

            })
        }
        .padding()
    }
}

struct ChangeUserEmailView_Previews: PreviewProvider {
    static let dataService = MockDataService()
    static var previews: some View {
        ChangeUserEmailView(dataService:dataService)
    }
}
