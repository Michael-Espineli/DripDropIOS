#!/usr/bin/env python3
"""Exercise the dashboard's actual scope and aggregation models without Firebase."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'DripDrop/Modules/Dashboard/Logic/CompanyDashboardSnapshot.swift').read_text()
checks = r'''
var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
    checks += 1
}
func access(_ user: [String: Any] = [:], _ role: [String: Any] = [:], owner: Bool = false) -> CompanyDashboardAccess {
    CompanyDashboardAccess(userAccess: user, role: role, isOwner: owner)
}
func record(_ id: String, _ fields: [String: Any]) -> CompanyDashboardRecord { CompanyDashboardRecord(id: id, data: fields) }

check(access().scopes == Set(["personal", "regional", "company"]), "Legacy defaults must match web")
check(access([:], ["dashboardScopeAccess": ["personal"]]).canViewManager == false, "Personal-only role cannot view manager data")
check(access(["dashboardScopeAccess": []]).scopes.isEmpty, "Explicit empty user grants must not use defaults")
check(access(["dashboardScopeAccessMode": "custom", "dashboardScopeAccess": ["regional"]], ["dashboardScopeAccess": ["company"]]).scopes == Set(["regional"]), "User override wins")
check(access([:], ["allowedDashboardScopes": ["company", "unknown"]]).scopes == Set(["company"]), "Alias and unknown scopes")
check(access([:], ["permissionIdList": ["20", "240"]]).canViewStops, "Service stop permission")
check(!access().permits("420") && access(owner: true).permits("420"), "Role and owner tool visibility")

let north = record("north", ["tags": [" North ", "north", "Commercial"], "active": true])
let south = record("south", ["tags": "South, Residential", "isActive": false])
let customers = ["north": north, "south": south]
let northJob = record("job-n", ["customerId": "north", "operationStatus": "Unscheduled"])
let southJob = record("job-s", ["customerId": "south", "tags": ["North"], "operationStatus": "Unscheduled"])
let unknown = record("unknown", ["customerId": "missing"])
let fallback = record("fallback", ["customerId": "missing", "regionalTags": ["North"]])
let limited = access([:], ["fullCustomerRegionAccess": false, "customerRegionTags": ["North"]])
check(north.tags == ["North", "Commercial"] && !south.isActiveCustomer, "Normalize native/web customer fields")
check(limited.includes(northJob, customers: customers, selectedTag: ""), "Limited company includes granted region")
check(!limited.includes(southJob, customers: customers, selectedTag: ""), "Canonical customer tags win over stale embedded tags")
check(!limited.includes(unknown, customers: customers, selectedTag: ""), "Missing customer must not escape limited grant")
check(limited.includes(fallback, customers: customers, selectedTag: "north"), "Embedded tag fallback for unlinked records")
check(!limited.includes(northJob, customers: customers, selectedTag: "South"), "Selected area must match")
check(!access([:], ["fullCustomerRegionAccess": false, "customerRegionTags": []]).includes(northJob, customers: customers, selectedTag: ""), "Empty limited regions grant no records")
check(access(["fullCustomerRegionAccess": true], ["fullCustomerRegionAccess": false, "customerRegionTags": ["North"]]).fullRegionAccess, "User regional override wins")
check(!access(["regionalAccessMode": ""], ["fullCustomerRegionAccess": false, "customerRegionTags": ["North"]]).fullRegionAccess, "Empty user mode must not override a limited role")
check(access(["customerRegionAccessMode": "limited", "allowedCustomerTags": ["South"]]).regionTags == ["South"], "Regional aliases")
check(limited.availableTags(customers: [north, south]) == ["North"], "Picker only exposes permitted tags")
check(access().availableTags(customers: [north, south]).count == 4, "Company picker gathers normalized customer tags")
let regional = access([:], ["dashboardScopeAccess": ["regional"]])
check(!regional.includes(northJob, customers: customers, selectedTag: "") && regional.includes(northJob, customers: customers, selectedTag: "north"), "Regional-only cannot fall back to whole company")
check(access().includes(unknown, customers: customers, selectedTag: ""), "Whole-company scope includes work without customer links")
check(!access().includes(unknown, customers: customers, selectedTag: "North"), "Selected tag excludes unknown customers")

var calendar = Calendar.current
let day = calendar.startOfDay(for: Date())
let tomorrow = calendar.date(byAdding: .day, value: 1, to: day)!
func stop(_ id: String, _ status: String, _ tech: String, _ date: Date = day) -> CompanyDashboardRecord {
    record(id, ["serviceDate": date, "operationStatus": status, "techId": tech, "tech": tech == "a" ? "Alex" : "Sam"])
}
let stops = [stop("1", "Finished", "a"), stop("2", "Not Finished", "a"), stop("3", "Skipped", "a"), stop("4", "Not Finished", ""), stop("5", "Cancelled", ""), stop("6", "Not Finished", "b", tomorrow)]
let snapshot = CompanyDashboardSnapshot(customers: [north], stops: stops, jobs: [northJob], requests: [], selectedDate: day)
check(snapshot.dailyStops.count == 5 && snapshot.finished == 1, "Daily metrics exclude next-day work")
check(snapshot.skipped == 2 && snapshot.remaining == 2, "Skipped work is separate from remaining work")
check(snapshot.unassigned == 1, "Only actionable unassigned work requires attention")
check(snapshot.workload.count == 1 && snapshot.workload[0].finished == 1 && snapshot.workload[0].remaining == 1, "Group by technician ID and keep completion accurate")
check(snapshot.schedulingQueue.count == 1, "Unscheduled office follow-ups")
check(record("finished", ["operationStatus": "Finished"]).isOpenJob == false, "Exclude finished jobs")
check(record("expired", ["operationStatus": "Unscheduled", "billingStatus": "Expired"]).needsScheduling == false, "Exclude expired jobs from scheduling")
check(record("request", ["status": "pending"]).isOpenRequest, "Legacy pending requests remain visible")
check(!record("request", ["status": "Converted To Job"]).isOpenRequest, "Converted requests are not open follow-ups")
check(CompanyDashboardSnapshot(customers: [], stops: [], jobs: [], requests: [], selectedDate: day).workload.isEmpty, "Empty company is valid")
check(CompanyDashboardRecord.strings(" North, north, , South ") == ["North", "South"], "Comma-separated tags are case-insensitively unique")
print("\(checks) company dashboard access, area filtering, compatibility, and workload checks passed")
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-company-dashboard-') as directory:
    fixture = Path(directory) / 'main.swift'
    fixture.write_text(source + checks)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-dashboard-modules', str(fixture)], check=True)
