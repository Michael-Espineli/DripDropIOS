#!/usr/bin/env python3
"""Exercise the production payroll queue with a controlled data service."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'DripDrop/Modules/RateSheet/Views/CompanyPayrollReviewQueueView.swift').read_text()
production = source[source.index('extension TechnicianPayLineItem {'):source.index('struct CompanyPayrollReviewQueueView: View {')]
stubs = r'''
import Foundation
import Combine
enum WorkerTypeEnum { case notAssigned }
enum PayLineItemSource { case serviceStop, serviceStopTask, manualAdjustment }
enum PayCalculationStatus { case pending, calculated, needsReview, adjusted, approved, paid, voided }
enum PayLineItemVoidReason { case adminVoided }
struct TechnicianPayLineItem {
    var id: String
    var companyId = "company"
    var technicianId = "tech"
    var technicianName = "Alex"
    var workerType = WorkerTypeEnum.notAssigned
    var source = PayLineItemSource.serviceStopTask
    var totalAmountCents = 0
    var calculationStatus = PayCalculationStatus.calculated
    var completedDate = Date()
    var approvedAt: Date?
    var approvedByUserId: String?
    var paidAt: Date?
    var paidByUserId: String?
    var payStatementId: String?
    var exportBatchId: String?
    var voidedAt: Date?
    var voidedByUserId: String?
    var voidReason: PayLineItemVoidReason?
    var adminReviewNotes: String?
}
enum PayrollDateFormatter { static func shortDate(_ date: Date) -> String { "today" } }
@MainActor protocol ProductionDataServiceProtocol {
    func fetchTechnicianPayLineItems(companyId: String, startDate: Date, endDate: Date) async throws -> [TechnicianPayLineItem]
    func updateTechnicianPayLineItem(_ item: TechnicianPayLineItem) async throws
    func clearZeroDollarPayrollTasks(companyId: String, lineItemIds: [String]) async throws
}
@MainActor final class Service: ProductionDataServiceProtocol {
    var saved: [TechnicianPayLineItem] = []
    var cleared: [[String]] = []
    var fail = false
    func fetchTechnicianPayLineItems(companyId: String, startDate: Date, endDate: Date) async throws -> [TechnicianPayLineItem] { [] }
    func updateTechnicianPayLineItem(_ item: TechnicianPayLineItem) async throws { saved.append(item) }
    func clearZeroDollarPayrollTasks(companyId: String, lineItemIds: [String]) async throws {
        if fail { throw NSError(domain: "changed amount", code: 1) }
        cleared.append(lineItemIds)
    }
}
'''
checks = r'''
@main struct Check {
    @MainActor static func main() async {
        let service = Service()
        let vm = CompanyPayrollReviewQueueViewModel(companyId: "company", currentUserId: "owner", dataService: service)
        let zero = TechnicianPayLineItem(id: "zero")
        var review = zero; review.id = "review"; review.calculationStatus = .needsReview
        var positive = zero; positive.id = "positive"; positive.totalAmountCents = 5000
        var attached = zero; attached.id = "attached"; attached.payStatementId = "statement"
        var exported = zero; exported.id = "exported"; exported.exportBatchId = "batch"
        var paid = zero; paid.id = "paid"; paid.paidAt = Date()
        var adjusted = zero; adjusted.id = "adjusted"; adjusted.calculationStatus = .adjusted
        var stop = zero; stop.id = "stop"; stop.source = .serviceStop
        assert(zero.canClearZeroDollarTask && review.canClearZeroDollarTask)
        assert(!positive.canClearZeroDollarTask && !attached.canClearZeroDollarTask && !exported.canClearZeroDollarTask)
        assert(!paid.canClearZeroDollarTask && !adjusted.canClearZeroDollarTask && !stop.canClearZeroDollarTask)
        vm.lineItems = [zero, review, positive, attached, exported, adjusted]
        assert(vm.clearableZeroTasks.map(\.id) == ["zero", "review"])
        await vm.approveAllVisible()
        assert(service.cleared == [["zero"]])
        assert(service.saved.map(\.id) == ["positive"])
        assert(vm.lineItems.first { $0.id == "zero" }?.calculationStatus == .voided)
        assert(vm.lineItems.first { $0.id == "review" }?.calculationStatus == .needsReview)
        assert(vm.filteredLineItems.map(\.id).contains("review") && !vm.filteredLineItems.map(\.id).contains("zero"))
        await vm.approve(review)
        await vm.markPaid(review)
        await vm.markPaid(zero)
        assert(service.saved.count == 1 && vm.showAlert)
        service.fail = true
        await vm.clearZeroTasks([review])
        assert(vm.lineItems.first { $0.id == "review" }?.calculationStatus == .needsReview)
        service.fail = false
        await vm.clearZeroTasks([review])
        assert(vm.clearableZeroTasks.isEmpty && service.cleared.last == ["review"])
        vm.selectedFilter = .all
        assert(vm.filteredLineItems.contains { $0.id == "review" && $0.voidReason == .adminVoided && $0.voidedByUserId == "owner" })
        var approved = zero; approved.id = "approved"; approved.calculationStatus = .approved; approved.approvedAt = Date()
        assert(approved.canClearZeroDollarTask)
        await vm.void(approved)
        assert(service.cleared.last == ["approved"] && service.saved.count == 1)
        vm.lineItems = (0..<201).map { TechnicianPayLineItem(id: "item-\($0)") }
        await vm.clearZeroTasks(vm.clearableZeroTasks)
        assert(service.cleared.suffix(2).map(\.count) == [200, 1])
        assert(!vm.isSaving && vm.clearableZeroTasks.isEmpty)
        print("Passed 17 production payroll zero-task queue checks")
    }
}
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-zero-task-') as directory:
    path = Path(directory)
    (path / 'main.swift').write_text(stubs + production + checks)
    subprocess.run(['swiftc', '-parse-as-library', '-module-cache-path', str(path / 'cache'), str(path / 'main.swift'), '-o', str(path / 'checks')], check=True)
    subprocess.run([str(path / 'checks')], check=True)
