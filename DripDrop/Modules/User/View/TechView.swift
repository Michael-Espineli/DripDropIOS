//
//  TechView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct TechView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @Binding var showSignInView: Bool
    @State var user:DBUser
    var company:Company
    var body: some View {
        ZStack{
            TechListView(dataService: dataService)
        }
    }
}
