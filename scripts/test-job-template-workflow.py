#!/usr/bin/env python3
"""Exercise the actual native job role/readiness predicates without Firebase."""
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
roles = (root / 'DripDrop/Modules/Roles/Logic/RoleManager.swift').read_text()
role_extension = roles[roles.index('extension Role {'):roles.index('final class RoleManager')]
creation = (root / 'DripDrop/Modules/Jobs/View/AddNewJobView.swift').read_text()
readiness = re.search(r'var canSubmitJob: Bool \{.*?\n    \}', creation, re.S).group(0)
settings = (root / 'DripDrop/Modules/Settings/New Group/SettingsManager.swift').read_text()
template_model = settings[settings.index('struct JobTemplate:'):settings.index('struct JobTemplatePlannedServiceStop:')]
fixture = '''
import Foundation
struct Role { var permissionIdList: [String] }
ROLE_EXTENSION
TEMPLATE_MODEL
struct Person { var id = "chosen"; var userId = "chosen-user" }
struct Readiness {
    var customer = Person()
    var serviceLocation = Person()
    var admin = Person()
    var rate = "0"
    var laborCost = "0"
    var isLoadingTemplate = false
    var startingTemplate: String? = nil
    var templateApplied = false
    var isTechnicianCreateFlow = true
    var serviceStops: [String] = []
    READINESS
}
let roles = ["22", "23", "27", "29", "31", "252"]
for permission in roles {
    let role = Role(permissionIdList: [permission])
    assert(role.canCreateJobFromTemplate == ["22", "23", "29"].contains(permission))
    assert(role.canCreateBlankJob == ["22", "27", "31"].contains(permission))
    assert(role.canCreateTemplateJobsForOthers == ["22", "29"].contains(permission))
    assert(role.canCreateCustomJobsForOthers == ["22", "31"].contains(permission))
}
var ready = Readiness()
assert(!ready.canSubmitJob)
ready.serviceStops = ["first-visit"]
assert(ready.canSubmitJob)
ready.startingTemplate = "template"
assert(!ready.canSubmitJob)
ready.templateApplied = true
assert(ready.canSubmitJob)
ready.isLoadingTemplate = true
assert(!ready.canSubmitJob)
ready.isLoadingTemplate = false
ready.isTechnicianCreateFlow = false
ready.serviceStops = []
assert(ready.canSubmitJob)
for json in [#"{"isActive":false}"#, #"{"active":false}"#, #"{"isActive":true,"active":false}"#] {
    let template = try JSONDecoder().decode(JobTemplate.self, from: Data(json.utf8))
    assert(!template.isActive)
}
let legacyActive = try JSONDecoder().decode(JobTemplate.self, from: Data("{}".utf8))
assert(legacyActive.isActive)
print("16 Swift job-template role, schedule, loading, and legacy-availability scenarios passed")
'''.replace('ROLE_EXTENSION', role_extension).replace('TEMPLATE_MODEL', template_model).replace('READINESS', readiness)
with tempfile.TemporaryDirectory(prefix='dripdrop-template-workflow-') as directory:
    path = Path(directory) / 'main.swift'
    path.write_text(fixture)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-template-workflow-modules', str(path)], check=True)
