//
//  AddNewLaborContract.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/10/24.
//

import SwiftUI

struct AddNewLaborContract: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,isPresented:Binding<Bool>,isFullScreen:Bool){
        _VM = StateObject(wrappedValue: BuisnessViewModel(dataService: dataService))
        self._isPresented = isPresented
        _isFullScreen = State(wrappedValue: isFullScreen)
    }
    @Binding var isPresented:Bool
    @State var isFullScreen:Bool
    
    //Objects
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject var VM : BuisnessViewModel
    
    @State var showPicker:Bool = false
    @State var associatedBusiness:AssociatedBusiness = AssociatedBusiness(id: "", companyId: "", companyName: "")
    @State var companyUser:CompanyUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .subContractor)

    @State var businessType:String = "Techs"

    //Form
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                if isFullScreen {
                    HStack{
                        Spacer()
                        Button(action: {
                            isPresented.toggle()
                        }, label: {
                            Image(systemName: "xmark")
                                .modifier(DismissButtonModifier())
                        })
                    }
                }
                if associatedBusiness.id == "" {
                    VStack{
                        HStack{
                            Picker("Type", selection: $businessType) {
                                Text("Techs").tag("Techs")
                                Text("Company").tag("Company")
                            }
                            .pickerStyle(.segmented)
                        }
                        switch businessType {
                        case "Techs":
                            associatedBusinesses
                        case "Company":
                            newBusinesses
                        default:
                            associatedBusinesses
                        }
                    }
                } else {
                    HStack{
                        Button(action: {
                            associatedBusiness = AssociatedBusiness(id: "", companyId: "", companyName: "")
                        }, label: {
                            HStack{
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .modifier(DismissButtonModifier())
                        })
                        Spacer()
                    }
                    AddNewLaborContractFromAssociatedBusiness(dataService: dataService, associatedBusiness: associatedBusiness, isPresented:$isPresented, isFullScreen: false)
                }
            }
            .padding(8)
            Text("")
                .sheet(isPresented: $VM.findNewBusiness, onDismiss: {
                    Task{
                        if let selectedCompany = masterDataManager.currentCompany {
                            do {
                                try await VM.getAssociatedBuisnesses(companyId: selectedCompany.id)
                            } catch {
                                print(error)
                            }
                        }
                    }
                }, content: {
                    FindBusinesses(dataService: dataService)
                })
        }
        .task {
            if let selectedCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoadAddNewLaborContractView(companyId: selectedCompany.id)
                } catch {
                    print(error)
                }
            }
        }
    }
}

extension AddNewLaborContract {
    var newBusinesses: some View {
        VStack{
            if VM.buisnessList.isEmpty {
                Button(action: {
                    VM.findNewBusiness.toggle()
                }, label: {
                    Text("Find Business")
                        .modifier(AddButtonModifier())
                })
                .padding(32)
            } else {
                ForEach(VM.buisnessList){ business in
                    Button(action: {
                        associatedBusiness = business
                    }, label: {
                        Text("\(business.companyName)")
                            .modifier(ListButtonModifier())
                    })
                    Divider()
                }
            }
        }
    }
    var associatedBusinesses: some View {
        VStack{
            ForEach(VM.companyUsers){ user in
                Button(action: {
                    if user.linkedCompanyId != nil && user.linkedCompanyName != nil {
                        associatedBusiness = AssociatedBusiness(companyId: user.linkedCompanyId! , companyName: user.linkedCompanyName! )
                    }
                }, label: {
                    Text("\(user.userName)")
                        .modifier(ListButtonModifier())
                })
                .disabled(user.linkedCompanyId == nil)
                .opacity(user.linkedCompanyId == nil ? 0.6 : 1)
                Divider()
            }
        }
    }
}
