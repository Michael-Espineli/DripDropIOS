#!/usr/bin/env python3
"""Decode the real shared-handler fixture using the native DTO and its formatters."""
from pathlib import Path
import subprocess, tempfile
root=Path(__file__).resolve().parents[1]
s=(root/'DripDrop/Modules/RateSheet/Views/TechnicianPayrollInfoView.swift').read_text()
model=s[s.index('struct OwnPaysheet: Decodable {'):s.index('@MainActor final class OwnPaysheetModel')]
checks=r'''
let sheet = try JSONDecoder().decode(OwnPaysheet.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
func check(_ value: Bool, _ message: String) { if !value { fatalError(message) }; print("PASS: " + message) }
check(sheet.version == 1, "Contract version")
check(sheet.startDateKey == "2026-10-07" && sheet.endDateKey == "2026-11-05", "Exact 30-day dates")
check(sheet.summary.earnedCents == 15000 && sheet.summary.recordedPaidCents == 2500 && sheet.summary.remainingCents == 12500, "Earned = recorded paid + remaining")
check(sheet.summary.olderUnpaidCents == 10500, "Older unpaid balance is separate")
check(sheet.summary.reviewCount == 1, "Source work missing pay stays visible")
check(sheet.days.first?.routes.first?.name == "Scottsdale · Thursday", "Route identity")
check(sheet.days.first?.routes.first?.stops.first?.title == "Alex Carter", "Route stop order")
check(sheet.days.flatMap(\.routes).flatMap(\.stops).flatMap(\.tasks).contains { $0.title == "Test and balance water" && $0.coverageLabel == "Included in stop pay" }, "Included work is accounted for")
check(sheet.lineItems.contains { $0.isPaid && $0.paymentReference == "ACH-1105-42" }, "Recorded payment reference")
check(sheet.statements.first?.reference == "PS-000042", "Finalized statement history")
check(sheet.lineItems.allSatisfy { $0.totalAmountCents != 0 || $0.needsReview }, "No calculated zero earnings")
check(!sheet.periodLabel.isEmpty && !OwnPaysheet.day("2026-11-05").isEmpty, "Date presentation")
let incomplete = Data("{}".utf8)
do { _ = try JSONDecoder().decode(OwnPaysheet.self, from: incomplete); fatalError("Incomplete pay must not become zero") } catch { print("PASS: Incomplete response fails visibly") }
'''
with tempfile.TemporaryDirectory(prefix='own-paysheet-') as folder:
    swift=Path(folder)/'main.swift';swift.write_text('import Foundation\n'+model+checks)
    subprocess.run(['swift','-module-cache-path',folder+'/cache',str(swift),str(root/'scripts/fixtures/technician-paysheet.json')],check=True)
