//
//  CompanyPayrollAdminHomeView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/26.
//


import SwiftUI

struct CompanyPayrollAdminHomeView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager

//    let companyId: String
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        List {
                setupSection
                payrollSection
            futureSetupSection
        }
        .navigationTitle("Payroll")
         
    }

    private var setupSection: some View {
        Section("Setup") {
            if let currentCompany = masterDataManager.currentCompany {
                NavigationLink {
                    CompanyPaySettingsView(
                        dataService: dataService
                    )
                } label: {
                    PayrollAdminNavRow(
                        iconName: "gearshape",
                        title: "Pay Settings",
                        subtitle: "Company payroll rules, hourly settings, and approval behavior"
                    )
                }
                if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                    NavigationLink {
                        CompanyServiceStopTypesView(
                            companyId: currentCompany.id,
                            currentUserId: user.id,
                            dataService: dataService
                        )
                    } label: {
                        PayrollAdminNavRow(
                            iconName: "mappin.and.ellipse",
                            title: "Service Stop Types",
                            subtitle: "Choose the payroll work types each scheduled stop should use"
                        )
                    }
                }
                NavigationLink {
                    CompanyWorkTypesView(
                        dataService: dataService
                    )
                } label: {
                    PayrollAdminNavRow(
                        iconName: "list.bullet.rectangle",
                        title: "Payroll Work Types",
                        subtitle: "The payroll rows that technicians can have rates for"
                    )
                }
                
                NavigationLink {
                    WorkTypeMappingsView(
                        dataService: dataService
                    )
                } label: {
                    PayrollAdminNavRow(
                        iconName: "arrow.triangle.branch",
                        title: "Task & Source Mappings",
                        subtitle: "Map payable task types and fallback stop sources to payroll work"
                    )
                }
                if let user = masterDataManager.user {
                    NavigationLink {
                        TechnicianRateMatrixView(
                            currentUserId: user.id,
                            dataService: dataService
                        )
                    } label: {
                        PayrollAdminNavRow(
                            iconName: "tablecells",
                            title: "Technician Rate Matrix",
                            subtitle: "Set each technician's rate for each work type"
                        )
                    }
                }
            }
        }
    }

    private var payrollSection: some View {
        Section("Payroll") {
            if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                
                NavigationLink {
                    CompanyPayrollReviewQueueView(
                        companyId: currentCompany.id,
                        currentUserId: user.id,
                        dataService: dataService
                    )
                } label: {
                    PayrollAdminNavRow(
                        iconName: "checklist",
                        title: "Payroll Review Queue",
                        subtitle: "Review outstanding, approved, and paid line items"
                    )
                }
                NavigationLink {
                    CompanyPayStatementsView(
                        companyId: currentCompany.id,
                        currentUserId: user.id,
                        dataService: dataService
                    )
                } label: {
                    PayrollAdminNavRow(
                        iconName: "doc.text",
                        title: "Pay Statements",
                        subtitle: "Create contractor invoices and employee pay summaries"
                    )
                }
            }
        }
    }

    private var futureSetupSection: some View {
        Section("Reports & Exports") {
            if let currentCompany = masterDataManager.currentCompany {
                NavigationLink {
                    PayrollRateHistoryView(
                        companyId: currentCompany.id,
                        dataService: dataService
                    )
                } label: {
                    PayrollAdminNavRow(
                        iconName: "clock.arrow.circlepath",
                        title: "Rate History",
                        subtitle: "Track technician pay increases over time"
                    )
                }

                if let user = masterDataManager.user {
                    NavigationLink {
                        PayrollExportsView(
                            companyId: currentCompany.id,
                            currentUserId: user.id,
                            dataService: dataService
                        )
                    } label: {
                        PayrollAdminNavRow(
                            iconName: "square.and.arrow.up",
                            title: "Payroll Exports",
                            subtitle: "CSV, QuickBooks, and payroll-provider exports"
                        )
                    }
                }
            } else {
                PayrollAdminNavRow(
                    iconName: "exclamationmark.triangle",
                    title: "Missing Company",
                    subtitle: "Select a company before viewing payroll reports."
                )
            }
        }
    }
}

struct PayrollAdminNavRow: View {
    var iconName: String
    var title: String
    var subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PayrollComingSoonView: View {
    var title: String
    var message: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: "hammer",
            description: Text(message)
        )
        .navigationTitle(title)
    }
}
