#!/usr/bin/env python3
"""Run the actual cross-client work-offer decoders without Firebase or a device."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
pay = (root / 'DripDrop/Modules/RateSheet/Views/PaySheets.swift').read_text()
def block(marker):
    start = pay.index(marker)
    return pay[start:pay.index('\n}', start) + 2] + '\n'
stubs = '''import Foundation
struct Address: Codable, Hashable { var streetAddress: String = "" }
enum WorkerTypeEnum: String, Codable, Hashable { case employee = "Employee", contractor = "Independent Contractor", notAssigned = "Not Assigned" }
'''
for name in ['RateType', 'PayQuantityUnit', 'PayLineItemSource', 'PayCalculationStatus']:
    stubs += block('enum ' + name + ':')
source = (root / 'DripDrop/Modules/WorkOffer.swift').read_text()
checks = r'''
let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .millisecondsSince1970
func decode(_ json: String) throws -> WorkOffer { try decoder.decode(WorkOffer.self, from: Data(json.utf8)) }
let legacy = try decode(#"{"id":"old","companyId":"company"}"#)
assert(legacy.jobTaskIds.isEmpty && legacy.status == .draft && legacy.acceptedTerms == nil)
let pending = try decode(#"{"id":"pending","status":"Acceptance Pending Approval","paySource":"Technician Rate","proposedStartDate":1793030400000}"#)
assert(pending.status.rawValue == "Acceptance Pending Approval" && pending.paySource == .technicianRate)
assert(pending.proposedStartDate == Date(timeIntervalSince1970: 1793030400))
let unknown = try decode(#"{"id":"unknown","status":"Future status","paySource":"Future formula","offeredToWorkerType":"Future worker"}"#)
assert(unknown.status == .draft && unknown.paySource == .technicianRate)
let split = try decode(#"{"id":"split","status":"Posted","remainingStopIds":["two"],"routeSplitAllowed":true,"claims":[{"id":"A","workerId":"tech","workerName":"Alex","stopIds":["one"],"taskIds":[],"status":"Accepted","agreement":{"workerId":"tech","paySource":"Offered Amount","baseCents":5001,"totalCents":5502}}],"scopeSnapshot":{"tasks":[],"services":[],"products":[{"id":"part","dbItemName":"Filter","quantity":"2"}],"stops":[{"id":"one","customerName":"Site"}]}}"#)
assert(split.claims?.first?.agreement.totalCents == 5502 && split.remainingStopIds == ["two"] && split.routeSplitAllowed == true)
assert(split.scopeSnapshot?.products.first?.quantity == 2 && split.scopeSnapshot?.stops.first?.name == "Site")
let line = try decode(#"{"id":"line","estimatedPayLines":[{"id":"pay","source":"manualAdjustment","rateType":"flatPerStop","quantityUnit":"each","calculationStatus":"calculated","rateAmountCents":5000,"totalAmountCents":5000,"quantity":1,"title":"Visit"}]}"#)
assert(line.estimatedPayLines?.first?.totalAmountCents == 5000 && line.estimatedPayLines?.first?.source == .manualAdjustment)
let aliases = try decode(#"{"id":"alias","estimatedPayLines":[{"id":"pay","source":"Manual Adjustment","rateType":"Manual","quantityUnit":"Each","calculationStatus":"Calculated","rateAmountCents":2500,"totalAmountCents":2500,"quantity":1,"title":"Estimate"}]}"#)
assert(aliases.estimatedPayLines?.first?.rateType == .manual && aliases.estimatedPayLines?.first?.calculationStatus == .calculated)
let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .millisecondsSince1970
let roundTrip = try decoder.decode(WorkOffer.self, from: encoder.encode(split))
assert(roundTrip.claims?.first?.workerId == "tech" && roundTrip.scopeSnapshot?.products.first?.quantity == 2)
let partialScope = try decode(#"{"id":"partial","scopeSnapshot":{"tasks":[{"id":"task","name":"Inspect"}]}}"#)
assert(partialScope.scopeSnapshot?.tasks.count == 1 && partialScope.scopeSnapshot?.products.isEmpty == true)
// History follows this technician's claim, including work on still-open split routes.
for status in WorkOfferStatus.allCases {
    let offer = try decode("{\"id\":\"status\",\"offeredToUserId\":\"tech\",\"status\":\"\(status.rawValue)\"}")
    assert(offer.isPreviousWork(for: "tech") == status.isFinal, "History mismatch for \(status)")
    let active = [WorkOfferStatus.acceptancePendingApproval, .accepted, .scheduled, .inProgress].contains(status)
    assert(offer.isCurrentWork(for: "tech") == active, "Current mismatch for \(status)")
    assert(!offer.isPreviousWork(for: "other") && !offer.isCurrentWork(for: "other"))
    assert(!offer.isPreviousWork(for: "") && !offer.isCurrentWork(for: ""))
}
let finishedSplit = try decode(#"{"id":"split-done","status":"Posted","claims":[{"id":"mine","workerId":"tech","workerName":"Alex","stopIds":["one"],"taskIds":[],"status":"Completed","agreement":{"workerId":"tech","paySource":"Offered Amount"}},{"id":"theirs","workerId":"other","workerName":"Taylor","stopIds":["two"],"taskIds":[],"status":"In Progress","agreement":{"workerId":"other","paySource":"Offered Amount"}}]}"#)
assert(finishedSplit.isPreviousWork(for: "tech") && !finishedSplit.isCurrentWork(for: "tech"))
assert(finishedSplit.isCurrentWork(for: "other") && !finishedSplit.isPreviousWork(for: "other"))
let multipleClaims = try decode(#"{"id":"multiple","status":"Posted","claims":[{"id":"old","workerId":"tech","workerName":"Alex","stopIds":["one"],"taskIds":[],"status":"Completed","agreement":{"workerId":"tech","paySource":"Offered Amount"}},{"id":"new","workerId":"tech","workerName":"Alex","stopIds":["two"],"taskIds":[],"status":"Scheduled","agreement":{"workerId":"tech","paySource":"Offered Amount"}}]}"#)
assert(multipleClaims.isCurrentWork(for: "tech") && !multipleClaims.isPreviousWork(for: "tech"))
var cancelledSplit = multipleClaims
cancelledSplit.status = .cancelled
assert(cancelledSplit.isPreviousWork(for: "tech") && !cancelledSplit.isCurrentWork(for: "tech"))
let oldHistory = try decode(#"{"id":"old-history","status":"Rejected","offeredToUserId":"tech","createdAt":1000,"rejectedAt":2000}"#)
assert(oldHistory.isPreviousWork(for: "tech"))
assert(oldHistory.workOfferHistoryDate == Date(timeIntervalSince1970: 2))
var recentHistory = oldHistory
recentHistory.completedAt = Date(timeIntervalSince1970: 50)
assert(recentHistory.workOfferHistoryDate > oldHistory.workOfferHistoryDate)
assert(legacy.workOfferHistoryDate == legacy.createdAt)
print("Swift workflow decoding, all 13 offer statuses, split-claim history, and history ordering passed")
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-technician-work-') as directory:
    fixture = Path(directory) / 'main.swift'
    fixture.write_text(stubs + source + checks)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-technician-work-modules', str(fixture)], check=True)
