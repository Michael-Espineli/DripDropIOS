#!/usr/bin/env python3
"""Exercise actual native task-pay policy, codecs, and stop attachment without Firebase."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'DripDrop/Modules/LaborContract/Terms/Task.swift').read_text()
draft = source[source.index('struct TaskPayDraft {'):source.index('protocol TaskItem {')]
group = source[source.index('struct JobTaskGroupItem:'):source.index('struct JobTask:')]
job = source[source.index('struct JobTask:'):source.index('struct LaborContractTask:')]
stop_task = source[source.index('struct ServiceStopTask:'):source.index('struct RecurringServiceStopTask:')]
recurring = source[source.index('struct RecurringServiceStopTask:'):]
attachment = (root / 'DripDrop/Modules/ServiceStops/View/ServiceStopTaskView.swift').read_text()
start = attachment.index('    func makeServiceStopTask(\n        from jobTask:')
copy = attachment[start:attachment.index('\n    }', start) + len('\n    }')]
stubs = '''import Foundation
protocol TaskItem {}
enum JobTaskType: String, Codable { case basic = "Basic" }
enum JobTaskStatus: String, Codable { case draft = "Draft", unassigned = "Unassigned", scheduled = "Scheduled", finished = "Finished" }
enum WorkerTypeEnum: String, Codable { case employee = "Employee", notAssigned = "Not Assigned" }
struct IdInfo: Codable, Hashable { var id = ""; var internalId = "" }
struct ServiceStop {
    var id = "stop"; var internalId = "S1"; var techId = "tech"; var tech = "Alex"
    var laborContractId = ""; var jobId = "job"; var recurringServiceStopId = ""; var serviceLocationId = "site"
}
'''
checks = r'''
let decoder = JSONDecoder()
var task = try decoder.decode(JobTask.self, from: Data(#"{"id":"task","name":"Checklist","contractedRate":0}"#.utf8))
var routine = TaskPayDraft()
assert(!routine.isAdditional && routine.validationMessage == nil)
routine.apply(to: &task)
assert(task.payrollMode == "included" && task.manualPayOverrideCents == nil && task.payrollStackBehavior == nil)
routine.selectAdditional(true)
assert(routine.isAdditional && routine.mode == "automatic" && routine.stackBehavior == "stackable")
assert(routine.validationMessage != nil)
routine.payTypeId = "repair"
assert(routine.validationMessage == nil)
routine.selectCalculation("custom")
assert(routine.customAmountCents == 0 && routine.validationMessage == nil)
routine.customAmountCents = 1500
routine.quantity = 2
routine.apply(to: &task)
let roundTrip = try decoder.decode(JobTask.self, from: JSONEncoder().encode(task))
assert(roundTrip.manualPayOverrideCents == 1500 && roundTrip.payrollStackBehavior == "stackable" && roundTrip.payQuantity == 2)
let attached = makeServiceStopTask(from: roundTrip, serviceStop: ServiceStop(), jobInternalId: "J1")
assert(attached.payrollMode == "custom" && attached.manualPayOverrideCents == 1500 && attached.payrollStackBehavior == "stackable")
assert(attached.payTypeId == "repair" && attached.payQuantity == 2 && attached.jobTaskId == "task")
let stopRoundTrip = try decoder.decode(ServiceStopTask.self, from: JSONEncoder().encode(attached))
assert(stopRoundTrip.manualPayOverrideCents == 1500 && stopRoundTrip.payrollStackBehavior == "stackable")
routine.selectAdditional(false)
routine.apply(to: &task)
assert(task.payrollMode == "included" && task.manualPayOverrideCents == nil && task.payrollStackBehavior == nil)
let legacy = try decoder.decode(JobTask.self, from: Data(#"{"id":"legacy"}"#.utf8))
assert(TaskPayDraft(task: legacy).mode == "automatic" && TaskPayDraft(task: legacy).validationMessage == nil)
let oldCustom = try decoder.decode(JobTask.self, from: Data(#"{"id":"old-custom","payrollMode":"custom","manualPayOverrideCents":0,"payrollStackBehavior":"exclusive","payQuantity":3}"#.utf8))
let oldDraft = TaskPayDraft(task: oldCustom)
assert(oldDraft.customAmountCents == 0 && oldDraft.stackBehavior == "exclusive" && !oldDraft.isEdited)
let unpaid = try decoder.decode(JobTask.self, from: Data(#"{"id":"unpaid","payrollMode":"unpaid"}"#.utf8))
assert(!TaskPayDraft(task: unpaid).isAdditional && TaskPayDraft(task: unpaid).mode == "unpaid")
let template = RecurringServiceStopTask(name: "Extra", description: "", type: .basic, contractedRate: 0, estimatedTime: 10, status: .unassigned, isTaskGroup: false, taskGroupId: "", taskGroupTaskId: "", payrollMode: "custom", manualPayOverrideCents: 1500, payrollStackBehavior: "stackable")
let recurringRoundTrip = try decoder.decode(RecurringServiceStopTask.self, from: JSONEncoder().encode(template))
assert(recurringRoundTrip.manualPayOverrideCents == 1500 && recurringRoundTrip.payrollStackBehavior == "stackable")
let oldGroup = try decoder.decode(JobTaskGroupItem.self, from: Data(#"{"id":"group","name":"Old","type":"Basic","description":"","contractedRate":0,"estimatedTime":0}"#.utf8))
assert(oldGroup.payrollMode == nil)
print("16 native task-pay policy, legacy compatibility, recurring codec, and attachment checks passed")
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-task-pay-') as directory:
    fixture = Path(directory) / 'main.swift'
    fixture.write_text(stubs + draft + group + job + stop_task + recurring + copy + checks)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-task-pay-modules', str(fixture)], check=True)
