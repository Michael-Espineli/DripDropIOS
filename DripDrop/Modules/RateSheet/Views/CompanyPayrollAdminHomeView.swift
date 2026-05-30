//
//  CompanyPayrollAdminHomeView.swift
//  DripDrop
//

import SwiftUI

struct CompanyPayrollAdminHomeView: View {

    let companyId: String
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        NavigationStack {
            List {
                setupSection
                payrollSection
                futureSetupSection
            }
            .navigationTitle("Payroll")
        }
    }

    private var setupSection: some View {
        Section("Setup") {
            NavigationLink {
                CompanyPaySettingsView(
                    companyId: companyId,
                    dataService: dataService
                )
            } label: {
                PayrollAdminNavRow(
                    iconName: "gearshape",
                    title: "Pay Settings",
                    subtitle: "Company payroll rules, hourly settings, and approval behavior"
                )
            }

            NavigationLink {
                PayrollComingSoonView(
                    title: "Service Stop Types",
                    message: "This page will let companies create types like Weekly Route, Route + Spa, Job Visit, Commercial Route, Startup, and Estimate."
                )
            } label: {
                PayrollAdminNavRow(
                    iconName: "mappin.and.ellipse",
                    title: "Service Stop Types",
                    subtitle: "Connect ServiceStop.typeId to real company-defined stop types"
                )
            }

            NavigationLink {
                PayrollComingSoonView(
                    title: "Company Work Types",
                    message: "This page will define payroll work rows like Routes, Spa Add-On, Clean Filter, Service Call, Commercial Base, and Install."
                )
            } label: {
                PayrollAdminNavRow(
                    iconName: "list.bullet.rectangle",
                    title: "Company Work Types",
                    subtitle: "The payroll rows that technicians can have rates for"
                )
            }

            NavigationLink {
                PayrollComingSoonView(
                    title: "Work Type Mappings",
                    message: "This page will map ServiceStop types and JobTaskType values to payroll work types."
                )
            } label: {
                PayrollAdminNavRow(
                    iconName: "arrow.triangle.branch",
                    title: "Work Type Mappings",
                    subtitle: "Map route/job/task data to payroll work types"
                )
            }

            NavigationLink {
                PayrollComingSoonView(
                    title: "Technician Rate Matrix",
                    message: "This page will look like your Excel sheet: work types down the side and technicians across the top."
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

    private var payrollSection: some View {
        Section("Payroll") {
            NavigationLink {
                CompanyPayrollReviewQueueView(companyId: companyId)
            } label: {
                PayrollAdminNavRow(
                    iconName: "checklist",
                    title: "Payroll Review Queue",
                    subtitle: "Review outstanding, approved, and paid line items"
                )
            }

            NavigationLink {
                PayrollComingSoonView(
                    title: "Pay Statements",
                    message: "This page will group approved line items into contractor invoices, employee statements, CSV exports, and future QuickBooks exports."
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

    private var futureSetupSection: some View {
        Section("Later") {
            NavigationLink {
                PayrollComingSoonView(
                    title: "Rate History",
                    message: "This page will show raises, previous rates, last increase date, and pay scale movement."
                )
            } label: {
                PayrollAdminNavRow(
                    iconName: "clock.arrow.circlepath",
                    title: "Rate History",
                    subtitle: "Track technician pay increases over time"
                )
            }

            NavigationLink {
                PayrollComingSoonView(
                    title: "Payroll Exports",
                    message: "This page will export CSVs and eventually support QuickBooks, Gusto, ADP, and other payroll providers."
                )
            } label: {
                PayrollAdminNavRow(
                    iconName: "square.and.arrow.up",
                    title: "Exports",
                    subtitle: "CSV, QuickBooks, and payroll-provider exports"
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