//
//  GenerateRouteFromLaborContract.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/13/24.
//

import SwiftUI

struct GenerateRouteFromLaborContract: View {
    //Init
    init(dataService:any ProductionDataServiceProtocol,laborContract:RepeatingLaborContract,isPresented:Binding<Bool>,isFullScreenCover:Bool){
        _VM = ObservedObject(wrappedValue: GenerateRouteFromLaborContractViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
        self._isPresented = isPresented
        _isFullScreenCover = State(wrappedValue: isFullScreenCover)
    }
    
    //Objects
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @ObservedObject var VM : GenerateRouteFromLaborContractViewModel
    
    //Formatting
    @Binding var isPresented:Bool
    @State var isFullScreenCover:Bool
    
    //Form
    @State var laborContract:RepeatingLaborContract
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                form
            }
            .padding(8)
            .foregroundColor(Color.basicFontText)
        }
        .environmentObject(VM)
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    VM.selectedLaborContract = laborContract
                    try await VM.onLoadGenerateRouteFromLaborContract(companyId: currentCompany.id, laborContractId: laborContract.id)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    GenerateRouteFromLaborContract(dataService: MockDataService(), laborContract: MockDataService.mockLaborContracts.first!)
//}
extension GenerateRouteFromLaborContract {
    var form: some View {
        VStack{
            HStack{
                Spacer()
                Text("Generate Labor")
                Spacer()
                if isFullScreenCover {
                    Button(action: {
                        isPresented.toggle()
                    }, label: {
                        Image(systemName: "xmark")
                            .modifier(DismissButtonModifier())
                    })
                }
            }
            ScrollView(.horizontal,showsIndicators: false){
                HStack{
                    ForEach(VM.laborContractRecurringWorkList){ work in
                        if work.routeSetUp {
                            Button(action: {
                                VM.selectedRecurringWork = work
                            }, label: {
                                Text("\(work.customerName)")
                                    .padding(8)
                                    .background(VM.selectedRecurringWork == work ? Color.poolGreen : Color.poolWhite)
                                    .cornerRadius(8)
                                    .foregroundColor(VM.selectedRecurringWork == work ? Color.poolWhite : Color.darkGray)
                                    .fontDesign(.monospaced)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.poolGreen, lineWidth: 4)
                                    )
                                    .padding(4)
                            })
                        } else {
                            Button(action: {
                                VM.selectedRecurringWork = work
                            }, label: {
                                Text("\(work.customerName)")
                                    .padding(8)
                                    .background(VM.selectedRecurringWork == work ? Color.poolRed : Color.poolWhite)
                                    .cornerRadius(8)
                                    .foregroundColor(VM.selectedRecurringWork == work ? Color.poolWhite : Color.darkGray)
                                    .fontDesign(.monospaced)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.poolRed, lineWidth: 4)
                                    )
                                    .padding(4)
                            })
                        }
                    }
                }
            }
            if VM.selectedRecurringWork.id != "" {
                VStack{
                    HStack{
                        Text("Customer Name:")
                            .fontWeight(.semibold)
                        Text("\(VM.selectedRecurringWork.customerName)")
                        Spacer()
                    }
                    HStack{
                        Text("Service Location Name:")
                            .fontWeight(.semibold)
                        Text("\(VM.selectedRecurringWork.serviceLocationName)")
                        Spacer()
                    }
                    HStack{
                        Text("Rate:")
                            .fontWeight(.semibold)
                        Text("\(String(VM.selectedRecurringWork.rate))")
                        Spacer()
                    }
                    VStack{
                        HStack{
                            Text("Required:")
                                .fontWeight(.semibold)
                            Text("\(String(VM.selectedRecurringWork.timesPerFrequency)) per \(VM.frequency.rawValue)")
                            Spacer()
                        }
                        HStack{
                            Text("Set Up:")
                                .fontWeight(.semibold)
                            Text("\(String(VM.selectedRecurringWork.timesPerFrequencySetUp)) / \(String(VM.selectedRecurringWork.timesPerFrequency))")
                            Spacer()
                        }
                    }
                    NewRecurringServiceStopFromLaborContract(dataService: dataService, laborContract: laborContract, recurringWork: $VM.selectedRecurringWork)
                }
            }
        }
    }
    var submitButton: some View {
        VStack{
            Button(action: {
                Task{
                    if let company = masterDataManager.currentCompany{
                        do {
                            try await VM.generateRecurringStopFromRecurringWork(companyId: company.id)
                        } catch {
                            print(error)
                        }
                    }
                }
            }, label: {
                Text("Submit Button")
                    .modifier(SubmitButtonModifier())
            })
        }
    }
}
