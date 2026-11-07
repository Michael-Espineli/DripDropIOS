#!/usr/bin/env python3
"""Exercise production finish/handoff and confirmed task writes without Firebase."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
error_presenter = 'enum PermissionErrorPresentation {' + (root / 'DripDrop/Resources/Errors.swift').read_text().split('enum PermissionErrorPresentation {', 1)[1].split('enum CustomerError:', 1)[0]
view = (root / 'DripDrop/Modules/ServiceStops/View/ServiceStopDetailView2.swift').read_text()
task_view = (root / 'DripDrop/Modules/ServiceStops/View/ServiceStopTaskView.swift').read_text()
stop_writer = (root / 'DripDrop/Resources/DataService/Protocol/ServiceStop/ServiceStopTask+ProductionDataService+Extension.swift').read_text()
job_writer = (root / 'DripDrop/Resources/DataService/Protocol/Jobs/JobTasks+ProductionDataService+Extension.swift').read_text()


def block(source, marker):
    start = source.index(marker)
    opening = source.index('{', start)
    depth, end = 1, opening + 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end].replace('private ', '')


models = '\n'.join(block(view, marker) for marker in [
    'private enum FieldJobCompletionFlow', 'private struct FieldJobCompletionPrompt'])
methods = '\n'.join(block(view, 'private func ' + name) for name in [
    'markFinished(', 'presentLinkedJobReview(', 'reviewFinishedStopJob(',
    'jobCompletionPromptIfEligible(', 'linkedJobId(', 'serviceStopLabel('])
writes = '\n'.join(block(source, 'func ' + name) for source, name in [
    (stop_writer, 'updateServiceStopTaskStatus('), (job_writer, 'updateJobTaskStatus('),
    (stop_writer, 'updateConfirmedTaskStatus(')])
save_status = '\n'.join(block(task_view, 'private func ' + name) for name in [
    'saveTaskStatus(', 'jobTaskCompanyId('])

stubs = r'''
import Foundation
enum Status: String { case finished = "Finished", notFinished = "Not Finished", scheduled = "Scheduled", skipped = "Skipped" }
typealias JobTaskStatus = Status
typealias ServiceStopOperationStatus = Status
struct ServiceStop { var id = "stop"; var internalId = "S1"; var jobId = "job"; var operationStatus = Status.notFinished; var otherCompany = false; var mainCompanyId: String? }
struct Job { var internalId = "J1"; var type = "Repair"; var operationStatus = Status.notFinished }
struct JobTask { var id = "task"; var status = Status.scheduled }
struct ServiceStopTask { var id = "copy"; var jobTaskId = "task"; var status = Status.scheduled }
struct JobPlannedServiceStop { var sortOrder = 0 }
struct Identity { var id: String }
enum Failure: Error { case denied }
@MainActor final class Master {
    var currentCompany: Identity? = Identity(id: "company")
    var user: Identity? = Identity(id: "tech")
}
@MainActor final class DetailVM {
    var taskList: [ServiceStopTask] = []
    var fail = false
    var writes = 0
    func updateServicestopOperationStatus(companyId: String, currentUserId: String, stop: ServiceStop, operationStatus: Status) async throws {
        if fail { throw Failure.denied }; writes += 1
    }
}
@MainActor final class Route {
    var alertMessage = ""; var showAlert = false; var restored = false
    func optimisticallyFinishServiceStop(_ stop: ServiceStop) -> ServiceStop? { stop }
    func restoreServiceStopAfterOptimisticUpdate(_ stop: ServiceStop) { restored = true }
}
@MainActor final class Navigation { var backs = 0; func goBack() { backs += 1 } }
@MainActor final class DeferredReference {
    var continuation: CheckedContinuation<Void, Error>?
    var fields: [String: Any] = [:]
    var stored: [String: Any] = [:]
    var autoAcknowledge = false
    var readFails = false
    func updateData(_ fields: [String: Any]) async throws {
        self.fields = fields
        if !autoAcknowledge { try await withCheckedThrowingContinuation { continuation = $0 } }
        for (key, value) in fields {
            if let operation = value as? FieldValue {
                if operation == .remove { stored.removeValue(forKey: key) }
                else { stored[key] = Date() }
            } else { stored[key] = value }
        }
    }
    func resolve(_ error: Error? = nil) {
        let pending = continuation; continuation = nil
        if let error { pending?.resume(throwing: error) } else { pending?.resume() }
    }
}
typealias DocumentReference = DeferredReference
enum FieldValue { case timestamp, remove
    static func serverTimestamp() -> FieldValue { .timestamp }
    static func delete() -> FieldValue { .remove }
}
struct Snapshot { var fields: [String: Any]; func data() -> [String: Any]? { fields } }
@MainActor final class Transaction {
    var fields: [String: Any] = [:]; var ref: DeferredReference?
    func getDocument(_ ref: DeferredReference) throws -> Snapshot {
        if ref.readFails { throw Failure.denied }
        return Snapshot(fields: ref.stored)
    }
    func updateData(_ fields: [String: Any], forDocument ref: DeferredReference) { self.fields = fields; self.ref = ref }
}
@MainActor final class Database {
    func runTransaction(_ update: (Transaction, UnsafeMutablePointer<NSError?>?) -> Any?) async throws -> Any? {
        let transaction = Transaction(); var error: NSError?
        let result = update(transaction, &error)
        if let error { throw error }
        if let ref = transaction.ref { try await ref.updateData(transaction.fields) }
        return result
    }
}
@MainActor final class Data {
    var job = Job(); var tasks = [JobTask()]; var failRead = false; var failTask = false
    var jobCalls = 0; var stopCalls = 0; var jobCompany = ""; var savedStatus: Status?
    func getWorkOrderById(companyId: String, workOrderId: String) async throws -> Job {
        if failRead { throw Failure.denied }; return job
    }
    func getJobTasks(companyId: String, jobId: String) async throws -> [JobTask] { tasks }
    func fetchJobPlannedServiceStops(companyId: String, jobId: String) async throws -> [JobPlannedServiceStop] { [] }
    func getServiceStopTasks(companyId: String, serviceStopId: String) async throws -> [ServiceStopTask] { [] }
    func updateJobTaskStatus(companyId: String, jobId: String, taskId: String, status: Status) async throws {
        jobCalls += 1; jobCompany = companyId; savedStatus = status
        if failTask { throw Failure.denied }
    }
    func updateServiceStopTaskStatus(companyId: String, serviceStopId: String, taskId: String, status: Status) async throws { stopCalls += 1; savedStatus = status }
}
@MainActor final class Writer {
    let reference = DeferredReference()
    let db = Database()
    func serviceStopTaskDocument(serviceStopId: String, companyId: String, taskId: String) -> DeferredReference { reference }
    func workOrderTaskDocument(companyId: String, workOrderId: String, taskId: String) -> DeferredReference { reference }
'''
harness = r'''
}
@MainActor final class Harness {
    let masterDataManager = Master(); let VM = DetailVM(); let vm = Route(); let navigationManager = Navigation(); let dataService = Data()
    var statusActionInProgress: Status?; var opStatus: Status?; var finishErrorMessage: String?
    var linkedJobCompletionFlow: FieldJobCompletionFlow?; var shouldNavigateBackAfterLinkedJobFlowDismiss = false
    var isLoadingLinkedJobReview = false; var failNotes = false
    var currentUserDisplayName = "Alex"
    var isFinishingOrSkippingStop: Bool { statusActionInProgress != nil }
    func saveServiceNotesIfNeeded(companyId: String, stop: ServiceStop) async throws { if failNotes { throw Failure.denied } }
'''
checks = r'''
}
@main struct Checks {
    @MainActor static func drain() async { for _ in 0..<200 { await Task.yield() } }
    @MainActor static func main() async throws {
        var count = 0
        func check(_ value: Bool, _ label: String) { precondition(value, label); count += 1; print("PASS: \(label)") }
        let open = Harness(); open.markFinished(ServiceStop()); await drain()
        if case .decision(let prompt) = open.linkedJobCompletionFlow {
            check(prompt.unfinishedTaskCount == 1, "remaining tasks do not hide the job review")
        } else { preconditionFailure("job review missing") }
        check(open.navigationManager.backs == 0 && open.shouldNavigateBackAfterLinkedJobFlowDismiss, "stay in detail until the job decision is dismissed")
        check(open.VM.writes == 1 && open.statusActionInProgress == nil, "finish is confirmed before handing off")
        let standalone = Harness(); standalone.markFinished(ServiceStop(jobId: "")); await drain()
        check(standalone.navigationManager.backs == 1 && standalone.linkedJobCompletionFlow == nil, "standalone stop returns to route")
        let finished = Harness(); finished.dataService.job.operationStatus = .finished
        finished.markFinished(ServiceStop()); await drain()
        check(finished.navigationManager.backs == 1, "already finished jobs need no second closeout")
        let denied = Harness(); denied.VM.fail = true; denied.markFinished(ServiceStop()); await drain()
        check(denied.vm.restored && denied.opStatus == .notFinished && denied.linkedJobCompletionFlow == nil, "failed finish restores the stop and shows no job review")
        let read = Harness(); read.dataService.failRead = true; read.markFinished(ServiceStop()); await drain()
        check(read.opStatus == .finished && read.navigationManager.backs == 0 && read.finishErrorMessage != nil, "job read failure keeps confirmed finish available for retry")
        read.dataService.failRead = false; read.reviewFinishedStopJob(ServiceStop()); await drain()
        check(read.linkedJobCompletionFlow != nil && read.VM.writes == 1, "job review retries without finishing the stop twice")
        let notes = Harness(); notes.failNotes = true; notes.markFinished(ServiceStop()); await drain()
        check(notes.navigationManager.backs == 0 && notes.linkedJobCompletionFlow == nil && notes.finishErrorMessage != nil, "failed notes stay visible for recovery")
        let missingUser = Harness(); missingUser.masterDataManager.user = nil
        missingUser.markFinished(ServiceStop()); await drain()
        check(missingUser.VM.writes == 0, "no finish without a signed-in user")

        for isJob in [false, true] {
            for fails in [false, true] {
                let writer = Writer(); var returned = false; var threw = false
                let task = Task { @MainActor in
                    do {
                        if isJob { try await writer.updateJobTaskStatus(companyId: "company", jobId: "job", taskId: "task", status: .finished) }
                        else { try await writer.updateServiceStopTaskStatus(companyId: "company", serviceStopId: "stop", taskId: "task", status: .finished) }
                    } catch { threw = true }
                    returned = true
                }
                await drain()
                check(!returned && writer.reference.continuation != nil, "\(isJob ? "job" : "stop") task waits for acknowledgement")
                writer.reference.resolve(fails ? Failure.denied : nil); await task.value
                check(returned && threw == fails, "\(isJob ? "job" : "stop") task propagates confirmed \(fails ? "failure" : "success")")
            }
        }
        let dated = Writer(); dated.reference.autoAcknowledge = true
        try await dated.updateJobTaskStatus(companyId: "company", jobId: "job", taskId: "task", status: .finished)
        let firstCompletion = dated.reference.stored["completedAt"] as! Date
        check(firstCompletion.timeIntervalSinceNow > -5, "native tasks save the actual completion date")
        try await dated.updateJobTaskStatus(companyId: "company", jobId: "job", taskId: "task", status: .finished)
        check(dated.reference.stored["completedAt"] as? Date == firstCompletion, "completion retry preserves the first timestamp")
        dated.reference.stored["finishedAt"] = firstCompletion
        try await dated.updateJobTaskStatus(companyId: "company", jobId: "job", taskId: "task", status: .scheduled)
        check(dated.reference.stored["completedAt"] == nil && dated.reference.stored["finishedAt"] == nil, "reopening clears stale completion timestamps")
        try await dated.updateJobTaskStatus(companyId: "company", jobId: "job", taskId: "task", status: .finished)
        check(dated.reference.stored["completedAt"] as! Date >= firstCompletion, "finishing reopened work records its new date")
        let readDenied = Writer(); readDenied.reference.readFails = true
        do { try await readDenied.updateJobTaskStatus(companyId: "company", jobId: "job", taskId: "task", status: .finished); preconditionFailure("must throw") } catch {}
        check(readDenied.reference.fields.isEmpty && readDenied.reference.stored.isEmpty, "failed task read causes no partial write")
        let linked = Harness()
        try await linked.saveTaskStatus(companyId: "company", serviceStop: ServiceStop(), task: ServiceStopTask(), status: .finished)
        check(linked.dataService.jobCalls == 1 && linked.dataService.stopCalls == 1, "linked task confirms both writes")
        let failedLink = Harness(); failedLink.dataService.failTask = true
        do { try await failedLink.saveTaskStatus(companyId: "company", serviceStop: ServiceStop(), task: ServiceStopTask(), status: .finished); preconditionFailure("must throw") } catch {}
        check(failedLink.dataService.stopCalls == 0, "failed canonical save cannot report the stop task finished")
        let adHoc = Harness()
        try await adHoc.saveTaskStatus(companyId: "company", serviceStop: ServiceStop(), task: ServiceStopTask(jobTaskId: ""), status: .finished)
        check(adHoc.dataService.jobCalls == 0 && adHoc.dataService.stopCalls == 1, "ad hoc tasks never write a blank job task ID")
        let reopen = Harness()
        try await reopen.saveTaskStatus(companyId: "company", serviceStop: ServiceStop(otherCompany: true, mainCompanyId: "sender"), task: ServiceStopTask(), status: .scheduled)
        check(reopen.dataService.jobCompany == "sender" && reopen.dataService.savedStatus == .scheduled, "reopening preserves cross-company target and requested status")
        print("\(count) mobile stop completion and task-save checks passed")
    }
}
'''

# The comments view is embedded in a tab, so its keyboard control must never
# invoke the enclosing navigation dismiss action. Verify the actual button body.
for marker, focus, bar in [
    ('private struct ServiceStopJobCommentsView', 'isCommentFocused', 'dismissCommentsBar'),
    ('private struct ServiceStopCustomerNotesSheet', 'isNoteFocused', 'dismissNotesBar')]:
    section = block(view, marker)
    button = block(section, 'var ' + bar)
    assert 'dismiss()' not in button and focus + ' = false' in button
    assert '.focused($' + focus + ')' in section and 'if ' + focus + ' {' in section
print('2 keyboard dismissal controls retain their detail/sheet and editor draft')

with tempfile.TemporaryDirectory(prefix='dripdrop-mobile-completion-') as directory:
    source = Path(directory) / 'checks.swift'
    source.write_text('import Foundation\n' + error_presenter + models + '\n' + stubs + writes + harness + methods + '\n' + save_status + checks)
    executable = Path(directory) / 'checks'
    subprocess.run(['swiftc', '-parse-as-library', '-module-cache-path', '/private/tmp/dripdrop-mobile-completion-modules', str(source), '-o', str(executable)], check=True)
    subprocess.run([str(executable)], check=True)
