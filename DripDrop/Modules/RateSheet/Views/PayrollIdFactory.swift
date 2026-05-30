//
//  PayrollIdFactory.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/26.
//


import Foundation

enum PayrollIdFactory {
    
    static func companyServiceStopTypeId() -> String {
        "comp_ss_type_" + UUID().uuidString
    }
    
    static func companyWorkTypeId() -> String {
        "comp_work_type_" + UUID().uuidString
    }
    
    static func workTypeMappingId() -> String {
        "comp_work_map_" + UUID().uuidString
    }
    
    static func companyRatePlanId() -> String {
        "comp_rate_plan_" + UUID().uuidString
    }
    
    static func technicianRateId() -> String {
        "comp_tech_rate_" + UUID().uuidString
    }
    
    static func technicianPayStatementId() -> String {
        "comp_pay_stmt_" + UUID().uuidString
    }
}
enum PayrollLineItemIdFactory {
    
    static func serviceStopPayLineId(
        serviceStopId: String,
        technicianId: String,
        workTypeId: String?
    ) -> String {
        [
            "comp_pay_line",
            "ss",
            serviceStopId,
            technicianId,
            workTypeId ?? "no_work_type"
        ].joined(separator: "_")
    }
    
    static func serviceStopTaskPayLineId(
        serviceStopId: String,
        serviceStopTaskId: String,
        technicianId: String,
        workTypeId: String?
    ) -> String {
        [
            "comp_pay_line",
            "ss_task",
            serviceStopId,
            serviceStopTaskId,
            technicianId,
            workTypeId ?? "no_work_type"
        ].joined(separator: "_")
    }
    
    static func activeRoutePayLineId(
        activeRouteId: String,
        technicianId: String
    ) -> String {
        [
            "comp_pay_line",
            "act_route",
            activeRouteId,
            technicianId
        ].joined(separator: "_")
    }
    
    static func manualAdjustmentPayLineId() -> String {
        "comp_pay_line_manual_" + UUID().uuidString
    }
}
