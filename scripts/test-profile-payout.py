#!/usr/bin/env python3
"""Run the actual profile payout presentation model without Firebase or UI."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'DripDrop/Modules/Profile/ProfileView.swift').read_text()
model = source[source.index('private func profilePayoutMoney('):].replace('private ', '')
stubs = r'''
import Foundation
enum PayCalculationStatus { case pending, calculated, needsReview, approved, adjusted, paid, voided }
enum PayStatementStatus { case approved, paid, voided }
enum RateType { case flatPerStop, flatPerTask, hourly, perBodyOfWater, perServiceLocation, percentage, manual }
enum PayQuantityUnit { case each, hours, minutes, bodyOfWater, serviceLocation, percent }
enum PayLineItemSource { case serviceStop, serviceStopTask, manualAdjustment }
struct TechnicianPayLineItem {
    var id: String
    var totalAmountCents = 2500
    var completedDate = Date(timeIntervalSince1970: 1_790_000_000)
    var calculationStatus = PayCalculationStatus.calculated
    var paidAt: Date?
    var voidedAt: Date?
    var payStatementId: String?
    var taskName: String?
    var workTypeName: String?
    var serviceStopTypeName: String?
    var displayTitle: String?
    var customerName: String?
    var serviceLocationAddress: String?
    var displaySubtitle: String?
    var source = PayLineItemSource.serviceStop
    var rateType = RateType.flatPerStop
    var rateAmountCents = 2500
    var quantity = 1.0
    var quantityUnit = PayQuantityUnit.each
}
struct TechnicianPayStatement {
    var id: String
    var status = PayStatementStatus.paid
    var endDate = Date(timeIntervalSince1970: 1_791_000_000)
    var paidAt: Date?
    var lineItemIds: [String] = []
}
'''
checks = r'''
var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String) { precondition(condition(), message); checks += 1 }
var old = TechnicianPayLineItem(id: "old")
var approved = TechnicianPayLineItem(id: "approved"); approved.calculationStatus = .approved
var adjustment = TechnicianPayLineItem(id: "adjusted"); adjustment.calculationStatus = .adjusted; adjustment.totalAmountCents = -500; adjustment.source = .manualAdjustment
var paid = TechnicianPayLineItem(id: "paid"); paid.calculationStatus = .paid; paid.paidAt = Date()
var paidAt = TechnicianPayLineItem(id: "timestamp"); paidAt.paidAt = Date()
var voided = TechnicianPayLineItem(id: "voided"); voided.calculationStatus = .voided
var voidedAt = TechnicianPayLineItem(id: "voided-at"); voidedAt.voidedAt = Date()
let snapshot = ProfilePayoutSnapshot(lineItems: [old, approved, adjustment, paid, paidAt, voided, voidedAt], statements: [])
check(snapshot.owedCents == 4500, "Retain old unpaid work and negative adjustments after newer payments")
check(snapshot.paidCents == 5000, "Paid status and timestamp both indicate paid")
check(snapshot.unpaidItems.count == 3 && snapshot.paidItems.count == 2, "Exclude voided records")
check(snapshot.lastPayoutDate != nil, "Last payment date")
check(snapshot.unpaidItems.first?.id == "adjusted", "Stable date/id sorting")
check(snapshot.unpaidItems.first?.rateDescription == "Pay adjustment", "Adjustment label")
var zeros = [PayCalculationStatus.calculated, .approved, .adjusted, .paid].enumerated().map { index, status in
    var item = TechnicianPayLineItem(id: "zero-\(index)"); item.totalAmountCents = 0; item.calculationStatus = status; return item
}
var missing = TechnicianPayLineItem(id: "missing"); missing.totalAmountCents = 0; missing.calculationStatus = .needsReview
var pending = TechnicianPayLineItem(id: "pending"); pending.totalAmountCents = 10000; pending.calculationStatus = .pending
let review = ProfilePayoutSnapshot(lineItems: zeros + [old, missing, pending], statements: [])
check(review.owedCents == 2500 && review.paidCents == 0, "Unresolved estimates excluded from confirmed totals")
check(review.reviewCount == 2 && review.unpaidItems.count == 3, "Hide normal zero lines but retain unresolved work")
check(review.unpaidItems.first?.id == "missing", "Prioritize review")
check(review.unpaidItems.first?.statusLabel == "Pay needs review", "Review wording")
var byStatement = TechnicianPayLineItem(id: "by-statement"); byStatement.payStatementId = "paid"
var byList = missing; byList.id = "by-list"; byList.totalAmountCents = 2500
var unpaidStatement = old; unpaidStatement.payStatementId = "approved"
var voidLink = old; voidLink.id = "void-link"; voidLink.payStatementId = "void"
let linked = ProfilePayoutSnapshot(lineItems: [byStatement, byList, unpaidStatement, voidLink], statements: [
    TechnicianPayStatement(id: "paid", lineItemIds: ["by-list"]),
    TechnicianPayStatement(id: "approved", status: .approved),
    TechnicianPayStatement(id: "void", status: .voided, paidAt: Date(), lineItemIds: ["void-link"])
])
check(linked.paidCents == 5000 && linked.owedCents == 5000, "Paid statement references and legacy line lists")
check(linked.reviewCount == 0, "Paid statement resolves a stale line status")
check(linked.lastPayoutDate == TechnicianPayStatement(id: "paid").endDate, "Legacy paid statement end-date fallback and void exclusion")
var hourly = old; hourly.taskName = "Clean filter"; hourly.workTypeName = "Maintenance"; hourly.customerName = "Rivera Pool"
hourly.rateType = .hourly; hourly.quantityUnit = .minutes; hourly.quantity = 90; hourly.rateAmountCents = 3000
let work = ProfilePayoutWork(lineItem: hourly, isPaid: false)
check(work.title == "Clean filter" && work.customer == "Rivera Pool", "Work first and customer context")
check(work.rateDescription == "1.5 hr × $30.00/hr", "Convert minutes before displaying hourly calculation")
var fallback = old; fallback.customerName = " "; fallback.serviceLocationAddress = "123 Pool St"; fallback.workTypeName = "Route"
check(ProfilePayoutWork(lineItem: fallback, isPaid: false).customer == "123 Pool St", "Trim empty customer names")
check(ProfilePayoutWork(lineItem: fallback, isPaid: false).title == "Route", "Legacy/canonical decoded pay name")
var percentage = old; percentage.rateType = .percentage; percentage.rateAmountCents = 1500
check(ProfilePayoutWork(lineItem: percentage, isPaid: false).rateDescription == "15% rate", "Percentage rate")
var custom = old; custom.rateType = .manual
check(ProfilePayoutWork(lineItem: custom, isPaid: false).rateDescription == "Custom pay", "A custom amount is distinct from an adjustment")
check(ProfilePayoutSnapshot.empty.unpaidItems.isEmpty && ProfilePayoutSnapshot.empty.paidCents == 0 && ProfilePayoutSnapshot.empty.lastPayoutDate == nil, "Empty history")
check(ProfilePayoutWork(lineItem: old, isPaid: false).statusLabel == "Unpaid", "Unpaid wording")
check(ProfilePayoutWork(lineItem: approved, isPaid: false).statusLabel == "Approved · unpaid", "Approval is not payment")
check(ProfilePayoutWork(lineItem: paid, isPaid: true).statusLabel == "Marked paid", "Recorded payment wording")
print("\(checks) actual native profile payout checks passed")
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-profile-payout-') as directory:
    fixture = Path(directory) / 'main.swift'
    fixture.write_text(stubs + model + checks)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-profile-modules', str(fixture)], check=True)
