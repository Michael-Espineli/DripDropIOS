#!/usr/bin/env python3
"""Run the app's pure Swift billing/remapping code without Firebase or a simulator."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'DripDrop/Modules/Jobs/JobTemplateWorkflowService.swift').read_text()
models = source[source.index('struct JobLaborLineItem:'):source.index('extension ProductionDataServiceProtocol {')]
task_source = (root / 'DripDrop/Modules/LaborContract/Terms/Task.swift').read_text()
task_model = task_source[task_source.index('struct JobTask:'):task_source.index('struct LaborContractTask:')]
history_models = source[source.index('// The same audit fields'): ]
settings_source = (root / 'DripDrop/Modules/Settings/New Group/SettingsManager.swift').read_text()
template_models = settings_source[settings_source.index('struct JobTemplatePlannedServiceStop:'):settings_source.index('struct JobTemplateShoppingItem:')]
planned_stop_model = (root / 'DripDrop/Modules/Jobs/View/JobPlannedServiceStop.swift').read_text()
stubs = '''
import Foundation
protocol TaskItem {}
enum JobTaskType: String, Codable { case basic = "Basic" }
enum JobTaskStatus: String, Codable { case draft = "Draft", unassigned = "Unassigned", scheduled = "Scheduled" }
enum WorkerTypeEnum: String, Codable { case notAssigned = "Not Assigned" }
struct IdInfo: Codable, Hashable { var id = ""; var internalId = "" }
func makeTask(id: String, contractedRate: Int = 0, billingLaborPriceCents: Int? = nil, taxable: Bool? = nil) -> JobTask {
    JobTask(id: id, name: "Task", type: .basic, contractedRate: contractedRate, estimatedTime: 0, status: .draft, customerApproval: false, actualTime: 0, workerId: "", workerType: .notAssigned, workerName: "", laborContractId: "", serviceStopId: IdInfo(), equipmentId: "", serviceLocationId: "", bodyOfWaterId: "", dataBaseItemId: "", billingLaborPriceCents: billingLaborPriceCents, taxable: taxable)
}
struct ShoppingListItem {}
struct ServiceStop {
    var plannedServiceStopId: String?
    var payWorkTypeId: String?
    var payWorkTypeName: String?
    var payrollMode: String?
    var manualPayOverrideCents: Int?
    var manualPayOverrideNotes: String?
    var payrollStackBehavior: String?
    var payQuantity: Double?
}
struct ServiceStopTask {}
'''
checks = r'''
let json = #"{"id":"service","name":"Service","quantity":1,"unitPriceCents":10000,"totalPriceCents":10000,"internalCostCents":2000,"taxable":true,"taskIds":[],"taskTemplateIds":["old-task"],"plannedServiceStopTemplateIds":["old-stop"],"catalogItemId":"catalog","stripeProductId":"prod","stripePriceId":"price"}"#
let original = try JSONDecoder().decode(JobLaborLineItem.self, from: Data(json.utf8))
let copy = original.remapped(companyId: "company", taskIds: ["old-task":"new-task"], stopIds: ["old-stop":"new-stop"], jobId: "job")
assert(copy.id != original.id && copy.jobId == "job")
assert(copy.linkedTaskIds == ["new-task"] && copy.linkedStopIds == ["new-stop"])
assert(copy.priceCents == 10000 && copy.taxable == true && copy.catalogItemId == "catalog" && copy.stripePriceId == "price")
var service = copy
service.plannedServiceStopIds = []
service.laborLinePlannedServiceStopIds = []
service.plannedServiceStopTemplateIds = []
var scope = NewJobScope(tasks: [makeTask(id: "new-task", contractedRate: 2000, billingLaborPriceCents: 7500), makeTask(id: "extra", contractedRate: 1000, billingLaborPriceCents: 5000, taxable: false)], laborLineItems: [service])
var retired = JobLaborLineItem(id: "scope_task_extra")
retired.totalPriceCents = 5000
scope.laborLineItems.append(retired)
assert(scope.completeLaborLines.reduce(0) { $0 + $1.priceCents } == 10000)
scope.tasks[1].billingLaborPriceCents = 6000
assert(scope.completeLaborLines.reduce(0) { $0 + $1.priceCents } == 10000)
scope.laborLineItems[0].taskIds = ["new-task", "extra"]
assert(scope.completeLaborLines.count == 1 && scope.completeLaborLines[0].internalCostCents == 0)
let free = NewJobScope(tasks: [makeTask(id: "free", contractedRate: 4000, billingLaborPriceCents: 0, taxable: false)])
assert(free.completeLaborLines.isEmpty)
let minimal = try JSONDecoder().decode(JobLaborLineItem.self, from: Data(#"{"id":"old"}"#.utf8))
assert(minimal.priceCents == 0 && minimal.taxable == nil)
let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(copy)) as! [String: Any]
assert(encoded["taxable"] as? Bool == true && encoded["stripeProductId"] as? String == "prod")
let legacyTask = try JSONDecoder().decode(JobTask.self, from: Data(#"{"id":"legacy","contractedRate":"5000","billingLaborPriceCents":""}"#.utf8))
assert(legacyTask.billingLaborPriceCents == nil && legacyTask.contractedRate == 5000)
let freeTask = try JSONDecoder().decode(JobTask.self, from: Data(#"{"id":"free","contractedRate":5000,"billingLaborPriceCents":0,"taxable":false}"#.utf8))
assert(freeTask.billingLaborPriceCents == 0 && freeTask.taxable == false)
let creationTime = Date(timeIntervalSince1970: 1792780200)
let actor = JobCreationActor(userId: "actual-creator", userName: "Alex Creator")
let creation = actor.creationEvent(companyId: "company", jobId: "job", internalId: "J42", at: creationTime)
assert(creation.actorUserId == "actual-creator" && creation.actorDisplayName == "Alex Creator" && creation.eventType == "Created")
assert(creation.timestamp == creationTime && creation.createdAtMillis == 1792780200000)
let unknownName = JobCreationActor(userId: "auth-user", userName: "").creationEvent(companyId: "company", jobId: "job", internalId: "J42", at: creationTime)
assert(unknownName.actorDisplayName == "auth-user")
let historical = try JSONDecoder().decode(JobHistoryEvent.self, from: Data(#"{"id":"older","actorUserId":"original-creator","createdAtMillis":1792780200000}"#.utf8))
assert(historical.actorDisplayName == "original-creator" && historical.timestamp == creationTime)
let paidTask = try JSONDecoder().decode(JobTask.self, from: Data(#"{"id":"pay","payTypeId":"filter","payrollMode":"custom","manualPayOverrideCents":0,"payrollStackBehavior":"exclusive","payQuantity":2}"#.utf8))
assert(paidTask.payTypeId == "filter" && paidTask.payrollMode == "custom" && paidTask.manualPayOverrideCents == 0 && paidTask.payQuantity == 2)
let payRoundTrip = try JSONDecoder().decode(JobTask.self, from: JSONEncoder().encode(paidTask))
assert(payRoundTrip.manualPayOverrideCents == 0 && payRoundTrip.payrollStackBehavior == "exclusive")
let templatePayJSON = #"{"id":"template-task","companyId":"company","templateId":"template","name":"Filter","type":"Basic","description":"","contractedRate":0,"estimatedTime":30,"customerApproval":false,"sortOrder":0,"payTypeId":"filter","payrollMode":"custom","manualPayOverrideCents":0,"payQuantity":2}"#
let templateTask = try JSONDecoder().decode(JobTemplateTask.self, from: Data(templatePayJSON.utf8))
let templateRoundTrip = try JSONDecoder().decode(JobTemplateTask.self, from: JSONEncoder().encode(templateTask))
assert(templateRoundTrip.payTypeId == "filter" && templateRoundTrip.manualPayOverrideCents == 0 && templateRoundTrip.payQuantity == 2)
let operationalTemplateJSON = #"{"id":"template-task","companyId":"company","templateId":"template","name":"Filter","type":"Basic","description":"","estimatedTime":30,"customerApproval":false,"sortOrder":0}"#
let operationalTemplate = try JSONDecoder().decode(JobTemplateTask.self, from: Data(operationalTemplateJSON.utf8))
assert(operationalTemplate.estimatedTime == 30 && operationalTemplate.payTypeId == nil)
let templateOrigin = try JSONDecoder().decode(JobTask.self, from: Data(#"{"id":"copied","sourceTemplateId":"template","sourceTemplateTaskId":"template-task"}"#.utf8))
assert(templateOrigin.sourceTemplateId == "template" && templateOrigin.sourceTemplateTaskId == "template-task")
let originRoundTrip = try JSONDecoder().decode(JobTask.self, from: JSONEncoder().encode(templateOrigin))
assert(originRoundTrip.sourceTemplateTaskId == "template-task" && originRoundTrip.sourceTemplateId == "template")
var planned = JobPlannedServiceStop(companyId: "company", jobId: "job", name: "Install", serviceStopTypeId: "job-visit", serviceStopTypeName: "Visit", serviceStopTypeImage: "", serviceStopTypeUseCaseRawValue: "jobVisit", estimatedMinutes: 30, sortOrder: 0, plannedLaborCostCents: 5500, createdByUserId: "creator", payTypeId: "repair", manualPayOverrideCents: 0, manualPayOverrideNotes: "Approved amount", billingLaborPriceCents: 15000, sourceTemplatePlannedStopId: "template-visit")
var scheduled = ServiceStop()
try planned.applyPay(to: &scheduled)
assert(scheduled.plannedServiceStopId == planned.id && scheduled.payWorkTypeId == "repair")
assert(scheduled.payrollMode == "custom" && scheduled.manualPayOverrideCents == 0 && scheduled.manualPayOverrideNotes == "Approved amount")
let savedVisit = try JSONDecoder().decode(JobPlannedServiceStop.self, from: JSONEncoder().encode(planned))
assert(savedVisit.sourceTemplatePlannedStopId == "template-visit" && savedVisit.billingLaborPriceCents == 15000)
planned.payrollMode = "included"
try planned.applyPay(to: &scheduled)
assert(scheduled.payrollMode == "included" && scheduled.manualPayOverrideCents == nil && scheduled.manualPayOverrideNotes == nil)
planned.payrollMode = "custom"
planned.manualPayOverrideCents = nil
do {
    try planned.applyPay(to: &scheduled)
    assertionFailure("An incomplete fixed pay setup was scheduled")
} catch {
    assert(scheduled.payrollMode == "included")
}
print("Swift job billing, template and planned visit pay checks passed")
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-job-billing-') as directory:
    fixture = Path(directory) / 'main.swift'
    fixture.write_text(stubs + task_model + template_models + planned_stop_model + models + history_models + checks)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-job-billing-modules', str(fixture)], check=True)
