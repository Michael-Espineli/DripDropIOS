//
//  ReportDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/17/24.
//

import SwiftUI
enum oneReportType:String, CaseIterable {
    case detail = "Detail"
    case summary = "Summary"
}
enum induvidualReportDisplay:String, CaseIterable {
    case customer = "Customer"
    case company = "Company"
    case user = "User"
    
}
struct ReportDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var reportVM : ReportViewModel
    init(dataService: any ProductionDataServiceProtocol) {
        _reportVM = StateObject(wrappedValue: ReportViewModel(dataService: dataService))
    }
    @State var startDate:Date = (Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
    @State var endDate:Date = Date()
    
    @State var reportTypeList:[oneReportType] = [.detail,.summary]
    @State var reportType:oneReportType = .summary
    
    @State var orderList:[induvidualReportDisplay] = [.customer,.company]
    @State var order:induvidualReportDisplay = .customer
    
    @State var wasteTypeList:[induvidualReportDisplay] = [.user,.company]
    @State var wasteType:induvidualReportDisplay = .user
    
    @State var pnlTypeList:[induvidualReportDisplay] = [.user,.company,.company]
    @State var pnlType:induvidualReportDisplay = .customer
    
    @State var chemicalTypeList:[induvidualReportDisplay] = [.user,.company,.customer]
    @State var chemicalType:induvidualReportDisplay = .user
    
    @State var purchaseTypeList:[induvidualReportDisplay] = [.user,.company,.customer]
    @State var purchaseType:induvidualReportDisplay = .user
    
    @State var isLoading:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        VStack{
                            if let report = masterDataManager.selectedReport {
                                switch  report {
                                case .chemicals:
                                    chemicalReport
                                case .waste:
                                    wasteReport
                                case .users:
                                    usersReport
                                case .purchases:
                                    purchasesReport
                                case .pnl:
                                    pnlReport
                                case .job:
                                    jobReport
                                }
                            }
                        }
                        .padding(.horizontal,16)
                    }, header: {
                        if UIDevice.isIPhone{
                            reportPicker
                        }
                    })
                })
                .padding(.top,20)
                .clipped()
            }
        }
        .onAppear(perform: {
            if let report = masterDataManager.selectedReport {
                print("Report Selected \(report.title)")
            } else {
                masterDataManager.selectedReport = .purchases
            }
        })
        .toolbar{
            ToolbarItem{
                Button(action: {
                    Task{
                        
                        isLoading = true
                        
                        if let report = masterDataManager.selectedReport, let company = masterDataManager.selectedCompany {
                            switch  report {
                            case .chemicals:
                                do {
                                    try await reportVM.getChemicalReport(companyId: company.id, type: reportType,order: chemicalType, startDate: startDate, endDate: endDate)
                                } catch {
                                    print("")
                                    print(error)
                                    print("Failed to Generate Chemical Report")
                                    print("")
                                }
                            case .waste:
                                do {
                                    try await reportVM.getWasteReport(companyId: company.id, type: reportType, wasteType: wasteType, startDate: startDate, endDate: endDate)
                                } catch {
                                    print("")
                                    print("error Creating Waste Report")
                                    print(error)
                                    print("")

                                }
                            case .users:
                                print("Generate users Report")
                            case .purchases:
                                try await reportVM.getPurchaseReport(companyId: company.id, type: reportType, orderString: purchaseType, startDate: startDate, endDate: endDate)
                            case .pnl:
                                do {
                                    try await reportVM.getPNLReport(companyId: company.id, type: reportType, PNLType: pnlType, startDate: startDate, endDate: endDate)
                                } catch {
                                    print("")
                                    print("Error Creating PNL Repprt")
                                    print(error)
                                    print("")

                                }
                            case .job:
                                print("Generate job Report")
                            }
                        }
                        isLoading = false
                        
                    }
                }, label: {
                    Text("Generate")
                })
                .foregroundColor(Color.poolGreen)
            }
            ToolbarItem{
                Button(action: {
                    
                }, label: {
                    HStack{
                        Text("Export")
                        Image(systemName: "square.and.arrow.up")
                    }
                })
                .foregroundColor(Color.poolBlue)
            }
        }
    }
}

struct ReportDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ReportDetailView(dataService: MockDataService())
    }
}

extension ReportDetailView {
    var reportPicker: some View {
        ScrollView(.horizontal,showsIndicators: false){
            HStack{
                ForEach(ReportType.allCases){ report in
                    Button(action: {
                        masterDataManager.selectedReport = report
                    }, label: {
                        Text("\(report.title)")
                            .padding(8)
                            .background( masterDataManager.selectedReport == report ? Color.poolBlue :Color.darkGray)
                            .cornerRadius(8)
                            .foregroundColor(Color.white)
                    })
                }
            }
        }
    }
    var chemicalReport: some View {
        VStack{
            chemicalReportTitle
            chemicalReportDetail
        }
        
    }
    var chemicalReportTitle: some View {
        VStack {
            Picker("Type", selection: $reportType, content: {
                ForEach(reportTypeList,id:\.self){
                    Text($0.rawValue).tag($0)
                }
            })
            .pickerStyle(.segmented)
            Picker("Order By", selection: $chemicalType, content: {
                ForEach(chemicalTypeList,id:\.self){
                    Text($0.rawValue).tag($0)
                }
            })
            .pickerStyle(.segmented)
            HStack{
                Text("Start Date: ")
                DatePicker(selection: $startDate, displayedComponents: .date) {
                }
            }
            HStack{
                Text("End Date: ")
                
                DatePicker(selection: $endDate, displayedComponents: .date) {
                }
            }
            
            
        }
    }
    var chemicalReportDetail: some View {
        VStack{
            if let report = masterDataManager.selectedReport{
                
                ScrollView{
                    VStack{
                        Divider()
                        VStack{
                            if reportType == .detail{
                                switch chemicalType {
                                case .customer:
                                    Group{
                                        ForEach(Array(reportVM.customerDict.keys)){ key in
                                            Text("Customer: \(key.firstName) \(key.lastName)")
                                                .font(.headline)
                                            if let stops = reportVM.customerDict[key] {
                                                ScrollView(.horizontal) {
                                                    ChemicalHeaderRow(readingTemplates: reportVM.listOfReadingTemplates, dosageTemplates: reportVM.listOfDosageTemplates)
                                                    ForEach(stops){ data in
                                                        ChemicalRow(stopData: data, readingTemplates: reportVM.listOfReadingTemplates, dosageTemplate: reportVM.listOfDosageTemplates)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                case .user:
                                   Text("User")
                                    Group{
                                        if reportVM.userReportSummaryDictionary.count == 0 {
                                            Text("No Results")
                                        } else {
                                            VStack{
                                                ForEach(Array(reportVM.userReportSummaryDictionary.keys)){ key in
                                                    Rectangle()
                                                        .frame(height: 4)
                                                    Text("User: \(key.userName)")
                                                        .font(.headline)
                                                    Rectangle()
                                                        .frame(height: 1)
                                                    VStack{
                                                        if let templates = reportVM.userReportSummaryDictionary[key] {
                                                            ForEach(Array(templates.keys)){ data in
                                                                
                                                                HStack{
                                                                    Text("\(data.name ?? "NA") - ")
                                                                    Spacer()
                                                                    Text("\(String(templates[data] ?? 0)) \(data.UOM ?? "") ")
                                                                    Spacer()
                                                                    Text("\((templates[data] ?? 0) * (Double(data.rate ?? "0") ?? 1), format: .currency(code: "USD").precision(.fractionLength(0)))")
                                                                    
                                                                    Spacer()
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .padding(.leading,16)
                                                }
                                            }
                                        }
                                    }
                                case .company:
                                    Text("Company")
                                    
                                }
                            } else { //Summary
                                switch chemicalType {
                                case .customer:
                                    Group{
                                        Text(String(reportVM.customerSummaryDosageDict.count))
                                        if reportVM.customerSummaryDosageDict.count == 0 {
                                            Text("NO Results")
                                        } else {
                                            VStack{
                                                ForEach(Array(reportVM.customerSummaryDosageDict.keys)){ key in
                                                    
                                                    Text("Customer: \(key.firstName) \(key.lastName)")
                                                        .font(.title)
                                                    if let templates = reportVM.customerSummaryDosageDict[key] {
                                                        ForEach(Array(templates.keys)){ data in
                                                            
                                                            HStack{
                                                                Text("\(data.name ?? "NA") - \(String(templates[data] ?? 0))")
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                case .user:
                                    Group{
                                        if reportVM.userReportSummaryDictionary.count == 0 {
                                            Text("No Results")
                                        } else {
                                            VStack{
                                                ForEach(Array(reportVM.userReportSummaryDictionary.keys)){ key in
                                                    Rectangle()
                                                        .frame(height: 4)
                                                    Text("User: \(key.userName)")
                                                        .font(.headline)
                                                    Rectangle()
                                                        .frame(height: 1)
                                                    VStack{
                                                        if let templates = reportVM.userReportSummaryDictionary[key] {
                                                            ForEach(Array(templates.keys)){ data in
                                                                
                                                                HStack{
                                                                    Text("\(data.name ?? "NA") - ")
                                                                    Spacer()
                                                                    Text("\(String(templates[data] ?? 0)) \(data.UOM ?? "") ")
                                                                    Spacer()
                                                                    Text("\((templates[data] ?? 0) * (Double(data.rate ?? "0") ?? 1), format: .currency(code: "USD").precision(.fractionLength(0)))")
                                                                    
                                                                    Spacer()
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .padding(.leading,16)
                                                }
                                            }
                                        }
                                    }
                                case .company:
                                    Text("Company")
                                default:
                                    Text("Invalid Order Selected")
                                    ForEach(reportVM.listOfStopData){ data in
                                        ChemicalRow(stopData: data, readingTemplates: reportVM.listOfReadingTemplates, dosageTemplate: reportVM.listOfDosageTemplates)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                Spacer()
            }
        }
    }
    var wasteReport: some View {
        VStack{
            wasteReportTitle
            wasteReportDetail
        }
        
    }
    var wasteReportTitle: some View {
        VStack{
            Picker("Type", selection: $reportType, content: {
                ForEach(reportTypeList,id:\.self){
                    Text($0.rawValue).tag($0)
                }
            })
            .pickerStyle(.segmented)
            Picker("Type: ", selection: $wasteType, content: {
                ForEach(wasteTypeList,id:\.self){
                    Text($0.rawValue).tag($0)
                }
            })
            .pickerStyle(.segmented)
            HStack{
                Text("Start Date: ")
                DatePicker(selection: $startDate, displayedComponents: .date) {
                }
            }
            HStack{
                Text("End Date: ")
                DatePicker(selection: $endDate, displayedComponents: .date) {
                }
            }
            
            
        }
    }
    var wasteReportDetail: some View {
        VStack{
            if let report = masterDataManager.selectedReport{
                VStack{
                    Divider()
                    if reportType == .detail{
                        switch wasteType {
                        case .user:
                            Group{
                                if reportVM.userReportSummaryDictionary.count == 0 {
                                    Text("No Results")
                                } else {
                                    VStack{
                                        ForEach(Array(reportVM.userReportSummaryDictionary.keys)){ key in
                                            Rectangle()
                                                .frame(height: 4)
                                            Text("User: \(key.userName)")
                                                .font(.headline)
                                            Rectangle()
                                                .frame(height: 1)
                                            VStack{
                                                if let templates = reportVM.userReportSummaryDictionary[key] {
                                                    
                                                    HStack{
                                                        Spacer()
                                                        HStack{
                                                            Text("Used")
                                                        }
                                                        .frame(width: 100)
                                                        HStack{
                                                            Text("Purchased")
                                                        }
                                                        .frame(width: 100)
                                                        HStack{
                                                            Text("%")
                                                        }
                                                        .frame(width: 50)
                                                    }
                                                    Rectangle()
                                                        .frame(height: 1)
                                                    ForEach(Array(templates.keys)){ data in
                                                        VStack{
                                                            HStack{
                                                                Text("\(data.name ?? "")")
                                                                    .font(.headline)
                                                                Text(" - \((templates[data] ?? 0) * (Double(data.rate ?? "0") ?? 1), format: .currency(code: "USD").precision(.fractionLength(0)))")
                                                                Spacer()
                                                            }
                                                            HStack{
                                                                Spacer()
                                                                HStack{
                                                                    if let amount = templates[data] {
                                                                        Text("\(String(format:"%0.f",amount))")
                                                                        Text("\(data.UOM ?? "")")
                                                                            .font(.footnote)
                                                                    }
                                                                }
                                                                .frame(width: 100)
                                                                HStack{
                                                                    Text("3")
                                                                }
                                                                .frame(width: 100)
                                                                HStack{
                                                                    Text("75%")
                                                                }
                                                                .frame(width: 50)
                                                                
                                                            }
                                                            HStack{
                                                                
                                                                Spacer()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(.leading,16)
                                        }
                                    }
                                }
                            }
                        case .company:
                            Text("Company")
                        default:
                            Text("Invalid Query")
                            
                        }
                    } else { //Sumary
                        switch wasteType {
                        case .user:
                            if reportVM.wasteReportLoading {
                                VStack{
                                    Text("Loading... ")
                                    ProgressView()
                                    ProgressView("\(reportVM.wasteReportLoadingLabel)", value: Double(reportVM.wasteReportLoadingValue), total: Double(reportVM.wasteReportLoadingTotal))
                                }
                            } else {
                                Group{
                                    if reportVM.wasteReportItemDict.count == 0 {
                                        Text("No Results")
                                    } else {
                                        VStack{
                                            ForEach(Array(reportVM.wasteReportItemDict.keys)){ key in
                                                Rectangle()
                                                    .frame(height: 4)
                                                Text("User: \(key.userName)")
                                                    .font(.headline)
                                                Rectangle()
                                                    .frame(height: 1)
                                                VStack{
                                                    if let wasteReportItem = reportVM.wasteReportItemDict[key] {
                                                        
                                                        HStack{
                                                            Spacer()
                                                            HStack{
                                                                Text("Used")
                                                            }
                                                            .frame(width: 100)
                                                            HStack{
                                                                Text("Purchased")
                                                            }
                                                            .frame(width: 100)
                                                            HStack{
                                                                Text("%")
                                                            }
                                                            .frame(width: 50)
                                                        }
                                                        Rectangle()
                                                            .frame(height: 1)
                                                        ForEach(Array(wasteReportItem)){ data in
                                                            VStack{
                                                                HStack{
                                                                    Text("\(data.dosageTemplateName)")
                                                                        .font(.headline)
                                                                    Text(" - \(Double(data.amountUsed) * (Double(data.price)), format: .currency(code: "USD").precision(.fractionLength(0)))")
                                                                    Spacer()
                                                                }
                                                                HStack{
                                                                    Spacer()
                                                                    HStack{
                                                                        Text("\(String(data.amountUsed))")
                                                                        Text("\(data.UOM)")
                                                                            .font(.footnote)
                                                                        
                                                                    }
                                                                    .frame(width: 100)
                                                                    HStack{
                                                                        Text("\(String(data.amountPurchased))")
                                                                        Text("\(data.UOM)")
                                                                            .font(.footnote)
                                                                        
                                                                    }
                                                                    .frame(width: 100)
                                                                    if data.amountPurchased != 0{
                                                                        HStack{
                                                                            Text("\(String(format:"%2.f",Double(((data.amountPurchased - data.amountUsed)/(data.amountPurchased))*100)))%")
                                                                        }
                                                                        .frame(width: 50)
                                                                    } else {
                                                                        HStack{
                                                                            Text("NA")
                                                                        }
                                                                        .frame(width: 50)
                                                                    }
                                                                    
                                                                }
                                                                HStack{
                                                                    
                                                                    Spacer()
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(.leading,16)
                                            }
                                        }
                                    }
                                }
                            }
                        case .company:
                            Text("Company")
                        default:
                            Text("Invalid Order Selected")
                        }
                    }
                }
                
            } else {
                Spacer()
            }
        }
    }
    var usersReport: some View {
        VStack{
            userReportTitle
            userReportDetail
        }
        
    }
    var userReportTitle: some View {
        VStack{
            Picker("Type", selection: $reportType, content: {
                ForEach(reportTypeList,id:\.self){
                    Text($0.rawValue).tag($0)
                }
            })
            .pickerStyle(.segmented)
            Picker("Order By", selection: $order, content: {
                ForEach(orderList,id:\.self){
                    Text($0.rawValue).tag($0)
                }
            })
            .pickerStyle(.segmented)
            
            HStack{
                Text("Start Date: ")
                DatePicker(selection: $startDate, displayedComponents: .date) {
                }
            }
            HStack{
                Text("End Date: ")
                
                DatePicker(selection: $endDate, displayedComponents: .date) {
                }
            }
            
        }
    }
    var userReportDetail: some View {
        VStack{
            if let report = masterDataManager.selectedReport{
                ScrollView{
                    VStack{
                        HStack{
                            Text("\(report.title)")
                        }
                        Divider()
                    }
                }
            } else {
                Spacer()
            }
            
        }
    }
    var jobReport: some View {
        VStack{
            jobReportTitle
            jobReportDetail
        }
        
    }
    var jobReportTitle: some View {
        VStack{
            Picker("Type", selection: $reportType, content: {
                ForEach(reportTypeList,id:\.self){
                    Text($0.rawValue).tag($0)
                }
            })
            .pickerStyle(.segmented)
            Picker("Order By", selection: $order, content: {
                ForEach(orderList,id:\.self){
                    Text($0.rawValue).tag($0)
                }
            })
            .pickerStyle(.segmented)
            HStack{
                Text("Start Date: ")
                DatePicker(selection: $startDate, displayedComponents: .date) {
                }
            }
            HStack{
                
                Text("End Date: ")
                
                DatePicker(selection: $endDate, displayedComponents: .date) {
                }
            }
            
        }
    }
    var jobReportDetail: some View {
        VStack{
            if let report = masterDataManager.selectedReport{
                
                
                ScrollView{
                    VStack{
                        HStack{
                            Text("\(report.title)")
                        }
                        Divider()
                    }
                }
            } else {
                Spacer()
            }
        }
    }
    
    var purchasesReport: some View {
        VStack{
            purchasesReportTitle
            purchasesReportDetail
        }
        
    }
    var purchasesReportTitle: some View {
        VStack(spacing: 16){
            Picker("Type", selection: $reportType, content: {
                ForEach(reportTypeList,id:\.self){
                    Text($0.rawValue).tag($0)
                }
            })
            .pickerStyle(.segmented)
            
            
            Picker("Order By", selection: $purchaseType, content: {
                ForEach(purchaseTypeList,id:\.self){
                    Text($0.rawValue).tag($0)
                }
            })
            .pickerStyle(.segmented)
            
            HStack{
                Text("Start Date: ")
                Spacer()
                DatePicker(selection: $startDate, displayedComponents: .date) {
                }
            }
            HStack{
                Text("End Date: ")
                Spacer()
                DatePicker(selection: $endDate, displayedComponents: .date) {
                }
            }
        }
    }
    var purchasesReportDetail: some View {
        VStack{
            if let report = masterDataManager.selectedReport{
                HStack{
                    Text("\(report.title)")
                }
                Divider()
                switch reportType {
                case .detail:
                    switch purchaseType {
                    case .company:
                        ForEach(Array(reportVM.companyPurchaseDetail.keys)) { datum in
                            VStack{
                                HStack{
                                    Text("\(datum.dataBaseItemName)")
                                    Spacer()
                                    if let value = reportVM.companyPurchaseDetail[datum] {
                                        Text("Total: \(value, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                    }
                                }
                                Rectangle()
                                    .frame(height: 1)
                            }
                            .padding(.leading,16)
                        }
                    case .customer:
                        Text("Customer")
                    case .user:
                        ForEach(Array(reportVM.purchaseDetailReport.keys)){ reportUser in
                            Rectangle()
                                .frame(height: 4)
                            HStack{
                                Text("\(reportUser.userName)")
                                    .font(.headline)
                                Spacer()
                                if let value = reportVM.purchaseDetailReport[reportUser]{
                                    Text("Total: \(reportVM.getPurchase(array:value), format: .currency(code: "USD").precision(.fractionLength(2)))")
                                }
                            }
                            Rectangle()
                                .frame(height: 1)
                            if let value = reportVM.purchaseDetailReport[reportUser]{
                                ForEach(Array(value.keys)) { key in
                                    HStack{
                                        Text("\(key.dataBaseItemName)")
                                        if let amount = value[key] {
                                            Spacer()
                                            Text(String(format:"%2.f",amount))
                                            Text(" X ")
                                            Text("$ \(String(format:"%2.f",amount * key.price))")
                                        }
                                    }
                                    Divider()
                                }
                            }
                        }
                        
                    }
                case .summary:
                    switch purchaseType {
                    case .company:
                        Text("Company Summary")
                        HStack{
                            Spacer()
                            if let value = reportVM.companyPurchaseSummary {
                                Text("Total: \(value, format: .currency(code: "USD").precision(.fractionLength(2)))")
                            }
                        }
                        
                    case .customer:
                        Text("Customer Summary")
                    case .user:
                        ForEach(Array(reportVM.purchaseSummaryReport.keys)){ reportUser in
                            Rectangle()
                                .frame(height: 4)
                            HStack{
                                Text("\(reportUser.userName)")
                                    .font(.headline)
                                Spacer()
                                if let value = reportVM.purchaseSummaryReport[reportUser]{
                                    Text("Total: \(value, format: .currency(code: "USD").precision(.fractionLength(0)))")
                                }
                            }
                            Rectangle()
                                .frame(height: 1)
                            VStack{
                                HStack{
                                    Text("Chemicals")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(69, format: .currency(code: "USD").precision(.fractionLength(0)))")
                                    
                                }
                                HStack{
                                    Text("Parts")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(69, format: .currency(code: "USD").precision(.fractionLength(0)))")
                                    
                                }
                                HStack{
                                    Text("Equipment")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(69, format: .currency(code: "USD").precision(.fractionLength(0)))")
                                    
                                }
                            }
                            .padding(.leading,16)
                        }
                    }
                }
            } else {
                Spacer()
            }
        }
    }
    var pnlReport: some View {
        VStack{
            pnlReportTitle
            pnlReportDetail
        }
        
    }
    var pnlReportTitle: some View {
        VStack{
            Picker("Type", selection: $reportType, content: {
                ForEach(reportTypeList,id:\.self){
                    Text($0.rawValue).tag($0)
                }
            })
            .pickerStyle(.segmented)
            Picker("Order By", selection: $pnlType, content: {
                ForEach(pnlTypeList,id:\.self){
                    Text($0.rawValue).tag($0)
                }
            })
            .pickerStyle(.segmented)
            
            
            HStack{
                Text("Start Date: ")
                DatePicker(selection: $startDate, displayedComponents: .date) {
                }
            }
            HStack{
                
                Text("End Date: ")
                
                DatePicker(selection: $endDate, displayedComponents: .date) {
                }
            }
            
        }
    }
    var pnlReportDetail: some View {
        VStack{
            if let report = masterDataManager.selectedReport{
                
                ScrollView{
                    VStack{
                        HStack{
                            Text("\(report.title)")
                        }
                        Divider()
                        Group{
                            if reportType == .detail{
                                switch pnlType {
                                case .customer:
                                    Text("Customer")
                                case .user:
                                    Text("User")
                                case .company:
                                    Text("Company")
                                    
                                }
                            } else {
                                switch order {
                                case .customer:
                                    Group{
                                        Text(String(reportVM.pnlSummaryReport.count))
                                        if reportVM.pnlSummaryReport.count == 0 {
                                            Text("NO Results")
                                        } else {
                                            VStack{
                                                ForEach(Array(reportVM.pnlSummaryReport.keys)){ key in
                                                    
                                                    Text("Customer: \(key.firstName) \(key.lastName)")
                                                        .font(.title)
                                                    if let contracts = reportVM.pnlSummaryReport[key] {
                                                        ForEach(Array(contracts.keys)){ data in
                                                            HStack{
                                                                Text("\(data.customerName) - ")
                                                                Text("\((contracts[data] ?? 0), format: .currency(code: "USD").precision(.fractionLength(0)))")
                                                                    .foregroundColor((contracts[data] ?? 0) > 0 ? Color.green : Color.red)
                                                                Spacer()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                case .user:
                                    Text("User")
                                case .company:
                                    Text("Company")
                                }
                            }
                        }
                    }
                }
            } else {
                Spacer()
            }
        }
    }
    var titleRow: some View {
        HStack{
            Text("00-00-0000")
                .foregroundColor(Color.clear)
                .overlay(Text("Date"))
            HStack{
                ForEach(reportVM.listOfDosageTemplates){ template in
                    Text("\(template.chemType)")
                        .frame(minWidth: 35)
                }
            }
            Spacer()
        }
    }
}
