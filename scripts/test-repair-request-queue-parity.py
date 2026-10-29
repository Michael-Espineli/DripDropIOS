#!/usr/bin/env python3
"""Compare the actual web/iOS default queue and submitter rules, then exercise iOS filters."""
from pathlib import Path
import json
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
web = root.parent / 'drip-drop-ecommerce'
node = r'''
const fs = require('fs');
const vm = require('vm');
const root = process.argv[1];
const requests = JSON.parse(fs.readFileSync(root + '/src/utils/models/repairRequestQueueFixtures.json', 'utf8'));
const model = fs.readFileSync(root + '/src/utils/models/RepairRequest.js', 'utf8').split('export class RepairRequest')[0].replace(/^import .*$/gm, '').replace(/export /g, '');
const context = vm.createContext({requests});
vm.runInContext(model + `
const key = request => request.sourcePath + ':' + request.id;
result = {requests, open: requests.filter(r => isOpenRepairRequestStatus(r.status)).map(key), ordered: requests.filter(r => isOpenRepairRequestStatus(r.status)).sort(compareRepairRequestsByDate).map(key),
  personal: requests.filter(r => isOpenRepairRequestStatus(r.status) && isRepairRequestSubmittedByUser(r, ['tech-1'])).map(key)};
`, context);
process.stdout.write(JSON.stringify(context.result));
'''
reference = json.loads(subprocess.check_output(['node', '-e', node, str(web)], text=True))
enums = (root / 'DripDrop/Resources/ListOfEnum.swift').read_text()
status = enums[enums.index('enum RepairRequestStatus:'):enums.index('enum RateSheetStatus:')]
source = (root / 'DripDrop/Modules/ServiceStops/View/RepairRequest+DS+Extension.swift').read_text()
model = source[source.index('struct RepairRequest:'):source.index('extension ProductionDataService')]
helpers = (root / 'DripDrop/Modules/Jobs/JobTemplate/JobTemplate+Helpers.swift').read_text()
priority = helpers[helpers.index('enum JobIssuePriorityLevel:'):helpers.index('extension JobTemplate')]
images = (root / 'DripDrop/Modules/Photos/DripDropImage.swift').read_text()
images = images[images.index('struct DripDropStoredImage:'):]
view = (root / 'DripDrop/Modules/RepairRequest/View/RepairRequestListView.swift').read_text()
filters = view[view.index('    private var filteredRequests:'):view.index('    var body:')].replace('private var filteredRequests', 'var filteredRequests')
stubs = '''import Foundation
extension Date {
    func startOfDay() -> Date { Calendar.current.startOfDay(for: self) }
    func endOfDay() -> Date { Calendar.current.date(byAdding: .day, value: 1, to: startOfDay())!.addingTimeInterval(-0.001) }
}
struct FixtureViewModel { let listOfContrats: [RepairRequest] }
'''
fixture_type = '''struct FilterFixture {
    let repairRequestVM: FixtureViewModel
    var searchTerm = ""
    var selectedStatus = RepairRequestStatus.defaultOpenCases
    var techIds: [String] = []
    var useDateFilter = false
    var startDate = Date()
    var endDate = Date()
''' + filters + '}\n'
checks = r'''
let reference = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))) as! [String: Any]
let fields = reference["requests"] as! [[String: Any]]
let formatter = ISO8601DateFormatter()
let requests = fields.map { record -> RepairRequest in
    return RepairRequest.fromQueueFields(id: record["id"] as! String, data: record, sourcePath: record["sourcePath"] as! String)
}
let expected = Set(reference["open"] as! [String])
let actual = Set(requests.filter { $0.status.isOpenWorkQueueItem }.map(\.queueId))
precondition(actual == expected, "iOS and web must show exactly the same requests from both sources")
let personal = fields.filter { RepairRequestStatus.normalized($0["status"] as? String).isOpenWorkQueueItem && RepairRequest.submittedByUser($0, userIds: ["tech-1"]) }.map { "\($0["sourcePath"]!):\($0["id"]!)" }
precondition(Set(personal) == Set(reference["personal"] as! [String]), "Submitter ownership must match web independently of route/customer assignments")
var fixture = FilterFixture(repairRequestVM: FixtureViewModel(listOfContrats: requests))
precondition(fixture.filteredRequests.map(\.queueId) == reference["ordered"] as! [String], "The default list must match badges with no date or active-user restriction")
precondition(fixture.filteredRequests.first?.id == "lowercase", "Preview/list order starts with newest requests")
fixture.useDateFilter = true
fixture.startDate = formatter.date(from: "2026-01-01T00:00:00Z")!
fixture.endDate = formatter.date(from: "2026-12-31T00:00:00Z")!
precondition(!fixture.filteredRequests.contains { $0.id == "old-open" }, "Explicit dates can narrow the list")
fixture.useDateFilter = false
fixture.selectedStatus = [.convertedToJob]
precondition(Set(fixture.filteredRequests.map(\.id)) == Set(["converted", "in-progress", "in-progress-slug"]), "Converted filter includes legacy progress statuses")
fixture.selectedStatus = []
precondition(fixture.filteredRequests.count == requests.count, "Clearing status filters shows every status")
fixture.selectedStatus = RepairRequestStatus.defaultOpenCases
fixture.searchTerm = "old unresolved"
precondition(fixture.filteredRequests.map(\.id) == ["old-open"], "Search narrows the same queue")
fixture.searchTerm = ""
fixture.techIds = ["former-tech"]
precondition(fixture.filteredRequests.map(\.id) == ["old-open"], "Former technicians' requests stay available")
print("Web/iOS parity passed for \(requests.count) mixed-source requests, \(expected.count) actionable requests, \(personal.count) submitted requests, and custom list filters")
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-request-queue-') as directory:
    fixture = Path(directory) / 'main.swift'
    fixture.write_text(stubs + status + priority + images + model + fixture_type + checks)
    data = Path(directory) / 'reference.json'
    data.write_text(json.dumps(reference))
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-request-queue-modules', str(fixture), str(data)], check=True)

# Compile and run the actual native queue subscriptions against controllable Firestore listeners.
import ast
listener_test = ast.parse((root / 'scripts/test-company-dashboard-listeners.py').read_text())
fake_firestore = next(ast.literal_eval(item.value) for item in listener_test.body if isinstance(item, ast.Assign) and any(isinstance(target, ast.Name) and target.id == 'fake_firestore' for target in item.targets))
view_model = (root / 'DripDrop/Modules/RepairRequest/Logic/RepairRequestViewModel.swift').read_text()
start = view_model.index('    @Published private(set) var queueLoading')
end = view_model.index('    //----------------------------------------------------', start)
queue_type = '''@MainActor final class QueueFixture: ObservableObject {
    @Published private(set) var listOfContrats: [RepairRequest] = []
''' + view_model[start:end] + '''
    func stop() { stopQueue() }
}
'''
listener_checks = r'''
@MainActor func checkListeners() async {
    func settle() async { for _ in 0..<8 { await Task.yield() } }
    let db = Firestore.shared
    let model = QueueFixture()
    model.startQueue(companyId: "one")
    let company = db.queries["companies/one/repairRequests"]!.last!
    let homeowner = db.queries["homeownerRepairRequests"]!.last!
    company.callback(QuerySnapshot(documents: [QueryDocumentSnapshot("shared", ["status": " pending ", "date": Timestamp(value: Date(timeIntervalSince1970: 10))])]), nil)
    await settle()
    precondition(model.queueLoading && model.listOfContrats.first?.date == Date(timeIntervalSince1970: 10))
    homeowner.callback(QuerySnapshot(documents: [QueryDocumentSnapshot("shared", ["status": "Unresolved"])]), nil)
    await settle()
    precondition(!model.queueLoading && Set(model.listOfContrats.map(\.queueId)).count == 2)
    model.startQueue(companyId: "two")
    company.callback(QuerySnapshot(documents: [QueryDocumentSnapshot("stale", [:])]), nil)
    await settle()
    precondition(company.registration.removed && homeowner.registration.removed && model.listOfContrats.isEmpty)
    let current = db.queries["companies/two/repairRequests"]!.last!
    current.callback(nil, NSError(domain: "test", code: 1))
    await settle()
    precondition(model.queueError != nil)
    model.stop()
    current.callback(QuerySnapshot(documents: [QueryDocumentSnapshot("late", [:])]), nil)
    await settle()
    precondition(current.registration.removed && model.listOfContrats.isEmpty && model.queueError == nil)
    model.startQueue(companyId: "mine", submittedByUserId: "tech-1")
    let mine = db.queries["companies/mine/repairRequests"]!.last!
    mine.callback(QuerySnapshot(documents: [
        QueryDocumentSnapshot("own", ["requesterId": "tech-1"]),
        QueryDocumentSnapshot("alias", ["createdByUserId": "tech-1"]),
        QueryDocumentSnapshot("assigned", ["requesterId": "other-tech", "techId": "tech-1", "userId": "tech-1"])
    ]), nil)
    await settle()
    precondition(Set(model.listOfContrats.map(\.id)) == Set(["own", "alias"]), "Technician drill-down follows submissions, not assignments")
    model.stop()
    print("Native repair queue listener timestamp, source identity, error, company-change, and cleanup checks passed")
}
await checkListeners()
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-request-queue-listeners-') as directory:
    fixture = Path(directory) / 'main.swift'
    fixture.write_text('import Foundation\nimport Combine\n' + status + priority + images + model + fake_firestore + queue_type + listener_checks)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-request-queue-modules', str(fixture)], check=True)
