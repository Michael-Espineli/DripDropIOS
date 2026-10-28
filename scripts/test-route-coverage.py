#!/usr/bin/env python3
"""Exercise the route coverage selection used by the iOS sheet without Firebase."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'DripDrop/Modules/WorkOffer/JobWorkOffersView.swift').read_text()
selection = source[source.index('enum RouteCoverageSelection {'):source.index('\nstruct RouteCoverageOfferSheet: View')]
stubs = '''import Foundation
enum ServiceStopOperationStatus { case finished, notFinished, skipped }
struct ServiceStop {
    var id: String
    var operationStatus: ServiceStopOperationStatus = .notFinished
    var techId: String = "tech"
    var serviceDate: Date
    var startTime: Date? = nil
    var endTime: Date? = nil
}
struct ActiveRoute {
    var date: Date
    var techId: String = "tech"
    var serviceStopsIds: [String]
}
'''
checks = r'''
var count = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
    count += 1
}
let day = Calendar.current.startOfDay(for: Date())
let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: day)!
let route = ActiveRoute(date: day, serviceStopsIds: ["second", "finished", "first", "skipped", "moved", "rescheduled", "missing", "second"])
let stops = [
    ServiceStop(id: "first", serviceDate: day),
    ServiceStop(id: "second", serviceDate: day.addingTimeInterval(3600)),
    ServiceStop(id: "finished", operationStatus: .finished, serviceDate: day),
    ServiceStop(id: "skipped", operationStatus: .skipped, serviceDate: day),
    ServiceStop(id: "moved", techId: "other", serviceDate: day),
    ServiceStop(id: "rescheduled", serviceDate: tomorrow),
    ServiceStop(id: "unrelated", serviceDate: day)
]
let eligible = RouteCoverageSelection.eligibleStops(in: stops, route: route)
check(eligible.map(\.id) == ["second", "first"], "Keep route order; exclude completed, skipped, moved, missing, rescheduled, and unrelated stops; deduplicate")
check(RouteCoverageSelection.selectedStopIds(in: stops, route: route, selected: ["first", "finished", "unrelated"]) == ["first"], "Partial offers must contain only explicitly selected eligible stops")
check(RouteCoverageSelection.selectedStopIds(in: stops, route: route, selected: []).isEmpty, "Clearing the selection must not offer the entire route")
check(!RouteCoverageSelection.isWholeRoute(eligible.map(\.id), route: route), "The remainder of a started route is a partial offer")
let wholeRoute = ActiveRoute(date: day, serviceStopsIds: ["second", "first"])
check(RouteCoverageSelection.isWholeRoute(["first", "second"], route: wholeRoute), "Whole-route detection uses membership, not selection order")
check(!RouteCoverageSelection.isWholeRoute([], route: ActiveRoute(date: day, serviceStopsIds: [])), "An empty route is not a full-route offer")
let nextRoute = ActiveRoute(date: tomorrow, serviceStopsIds: ["next"])
let multiDay = stops + [ServiceStop(id: "next", serviceDate: tomorrow)]
check(RouteCoverageSelection.selectedStopIds(in: multiDay, route: route, selected: ["first", "next"]) == ["first"] && RouteCoverageSelection.selectedStopIds(in: multiDay, route: nextRoute, selected: ["first", "next"]) == ["next"], "Multi-day coverage keeps each day's selected stops in its own offer")
var changed = eligible
changed[0].operationStatus = .finished
check(RouteCoverageSelection.selectedStopIds(in: changed, route: route, selected: ["first", "second"]) == ["first"], "Refresh before posting removes stops completed while the sheet was open")
changed[1].techId = "other"
check(RouteCoverageSelection.selectedStopIds(in: changed, route: route, selected: ["first", "second"]).isEmpty, "Refresh cannot offer stops reassigned while selecting")
let begun = ServiceStop(id: "first", serviceDate: day, startTime: day)
check(RouteCoverageSelection.eligibleStops(in: [begun], route: route).isEmpty, "Started stops cannot enter a new coverage offer")
check(RouteCoverageSelection.coverageSelection(available: ["first", "second"], requested: ["first", "stale"]) == ["first"], "Manager-selected scope stays limited to available selected stops")
check(RouteCoverageSelection.coverageSelection(available: ["first", "second"], requested: []) == [], "Explicit empty scope never becomes a whole-route offer")
check(RouteCoverageSelection.coverageSelection(available: ["first", "second"], requested: nil) == ["first", "second"], "Existing technician entry defaults to all available stops")
check(RouteCoverageSelection.cents(from: "") == 0, "Blank optional pay uses the technician rate")
check(RouteCoverageSelection.cents(from: " 125.50 ") == 12550, "Convert fixed pay to cents")
check(RouteCoverageSelection.cents(from: "12,25") == 1225, "Accept a decimal comma")
for invalid in ["-1", "nan", "inf", "12junk", "1.234", "99999999999999999999999"] {
    check(RouteCoverageSelection.cents(from: invalid) == nil, "Reject invalid or overflowing pay: \(invalid)")
}
print("\(count) route coverage selection, stale-stop, and pay validation checks passed")
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-route-coverage-') as directory:
    fixture = Path(directory) / 'main.swift'
    fixture.write_text(stubs + selection + checks)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-route-coverage-modules', str(fixture)], check=True)
