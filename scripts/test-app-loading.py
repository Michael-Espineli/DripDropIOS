#!/usr/bin/env python3
"""Exercise the actual launch coordinator and RootView session methods offline."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
loading = (root / 'DripDrop/Views/Components/LoadingScreens/WaterLevelLoading.swift').read_text()
view = (root / 'DripDrop/Modules/Navigation/View/RootView.swift').read_text()


def block(source, marker):
    start = source.index(marker)
    opening = source.index('{', start)
    depth, end = 1, opening + 1
    while depth:
        if source[end] == '{':
            depth += 1
        elif source[end] == '}':
            depth -= 1
        end += 1
    return source[start:end]


coordinator = block(loading, '@MainActor\nfinal class AppLoadingState')
fill_transition = block(loading, 'private struct LoadingFillTransition').replace('private struct', 'struct', 1)
methods = '\n'.join(block(view, '@MainActor\n    private func ' + name)
                    .replace('private func', 'func', 1)
                    for name in ['updateSession()', 'loadAccount()'])
stubs = r'''
import SwiftUI
enum LoadError: Error { case failed }
@MainActor final class AuthenticationStub {
    var calls = 0
    var fails = false
    var delay = false
    var user: String? = "user"
    var company: String? = "company"
    var companyUser: String? = "member"
    func onInitialLoad() async throws {
        calls += 1
        if delay { try await Task.sleep(for: .milliseconds(50)) }
        if fails { throw LoadError.failed }
    }
}
@MainActor final class MasterStub {
    var showSignInView = true
    var user: String?
    var currentCompany: String?
    var companyUser: String?
    var subscriptionChecks = 0
    func checkForSubscriptionStatus() { subscriptionChecks += 1 }
}
@MainActor final class RootHarness {
    var loadingState = AppLoadingState()
    var masterDataManager = MasterStub()
    var VM = AuthenticationStub()
    var attemptedInitialLoad = false
'''
checks = r'''
}
@main struct Checks {
    @MainActor static func main() async {
        var count = 0
        func check(_ condition: Bool, _ label: String) {
            precondition(condition, label)
            count += 1
            print("PASS: \(label)")
        }
        let clock = Date(timeIntervalSince1970: 100)
        var fill = LoadingFillTransition()
        fill.move(to: 0.46, at: clock, duration: 6)
        check(abs(fill.value(at: clock) - 0.025) < 0.000001, "new fill starts at the visible waterline")
        check(fill.value(at: clock.addingTimeInterval(-1)) == 0.025, "clock before a transition cannot lower the water")
        let midpoint = fill.value(at: clock.addingTimeInterval(3))
        check(abs(midpoint - 0.2425) < 0.000001, "bounded drawing clock interpolates the water level")
        fill.move(to: 0.88, at: clock.addingTimeInterval(3), duration: 6)
        check(fill.value(at: clock.addingTimeInterval(3)) == midpoint, "stage changes continue from the rendered level")
        check(fill.value(at: clock.addingTimeInterval(10)) == 0.88, "long loads stop at their visual milestone")
        fill.move(to: 0.46, at: clock.addingTimeInterval(10), duration: 6)
        check(fill.target == 0.88, "a lower target cannot drain the screen")
        fill.move(to: 1, at: clock.addingTimeInterval(10), duration: 0.65)
        check(fill.value(at: clock.addingTimeInterval(11)) == 1, "completion fills to the top within the existing finish delay")
        var reduced = LoadingFillTransition()
        reduced.move(to: 2, at: clock, duration: 0)
        check(reduced.value(at: clock) == 1, "Reduce Motion updates immediately and clamps to a full screen")
        let root = RootHarness()
        check(root.loadingState.isVisible && root.loadingState.phase == .account,
              "launch starts covered before the first async call")
        let initial = root.loadingState.sessionID
        root.loadingState.workspaceLoaded(for: initial)
        root.loadingState.finish()
        check(root.loadingState.phase == .account, "out-of-order completion cannot skip account loading")
        await root.updateSession()
        let session = root.loadingState.sessionID
        check(root.VM.calls == 1 && !root.masterDataManager.showSignInView, "initial account loads once")
        check(root.loadingState.hasLoadedAccount && root.loadingState.isVisible,
              "home can mount while the same loading screen remains visible")
        check(root.loadingState.phase == .workspace && root.loadingState.fillTarget == 0.88,
              "second stage advances the fill without resetting")
        check(root.masterDataManager.currentCompany == "company" && root.masterDataManager.subscriptionChecks == 1,
              "account context is assigned before subscription setup")
        await root.updateSession()
        check(root.VM.calls == 1 && root.loadingState.sessionID == session,
              "sign-in-state handoff does not start a duplicate account load")
        root.loadingState.workspaceLoaded(for: initial)
        check(root.loadingState.phase == .workspace, "stale child completion is ignored")
        root.loadingState.workspaceLoaded(for: session)
        check(root.loadingState.phase == .finishing && root.loadingState.isVisible && root.loadingState.fillTarget == 1,
              "successful workspace finishes filling before dismissal")
        root.loadingState.workspaceLoaded(for: session)
        root.loadingState.finish()
        check(!root.loadingState.isVisible && root.loadingState.hasLoadedAccount, "ready app is revealed once")
        await root.updateSession()
        check(root.VM.calls == 1, "ready-session updates do not refetch the account")
        root.masterDataManager.showSignInView = true
        await root.updateSession()
        check(!root.loadingState.hasLoadedAccount && !root.loadingState.isVisible,
              "sign-out reveals sign-in and invalidates the session")
        root.loadingState.workspaceLoaded(for: session)
        check(root.loadingState.phase == .ready, "completion from signed-out home cannot show or finish a loader")
        root.masterDataManager.showSignInView = false
        await root.updateSession()
        check(root.VM.calls == 2 && root.loadingState.phase == .workspace && root.loadingState.sessionID != session,
              "a fresh login starts a fresh two-stage fill")
        let failed = RootHarness()
        failed.VM.fails = true
        await failed.updateSession()
        check(failed.masterDataManager.showSignInView && !failed.loadingState.isVisible && !failed.loadingState.hasLoadedAccount,
              "account error returns to sign-in without trapping the loader")
        failed.VM.fails = false
        failed.masterDataManager.showSignInView = false
        await failed.updateSession()
        check(failed.VM.calls == 2 && failed.loadingState.phase == .workspace, "login can recover after an account failure")
        let cancelled = RootHarness()
        cancelled.VM.delay = true
        let task = Task { await cancelled.updateSession() }
        while cancelled.VM.calls == 0 { await Task.yield() }
        task.cancel()
        await task.value
        await cancelled.updateSession()
        check(cancelled.masterDataManager.user == nil && !cancelled.loadingState.isVisible,
              "cancelled account work cannot populate a signed-out session")
        print("\(count) loading checks passed")
    }
}
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-loading-tests-') as directory:
    path = Path(directory)
    source = path / 'checks.swift'
    source.write_text(stubs[:stubs.index('@MainActor final class RootHarness')] + coordinator + '\n' + fill_transition + '\n'
                      + stubs[stubs.index('@MainActor final class RootHarness'):] + methods + checks)
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', '-module-cache-path', str(path / 'modules'),
                    str(source), '-o', str(path / 'checks')], check=True)
    subprocess.run([str(path / 'checks')], check=True)
