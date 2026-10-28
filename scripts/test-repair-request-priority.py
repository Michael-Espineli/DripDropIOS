#!/usr/bin/env python3
"""Run the actual request Codable model and job priority helpers without Firebase."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'DripDrop/Modules/ServiceStops/View/RepairRequest+DS+Extension.swift').read_text()
model = source[source.index('struct RepairRequest:'):source.index('extension ProductionDataService')]
helpers = (root / 'DripDrop/Modules/Jobs/JobTemplate/JobTemplate+Helpers.swift').read_text()
priority = helpers[helpers.index('enum JobIssuePriorityLevel:'):helpers.index('extension JobTemplate')]
job_helpers = helpers[helpers.index('extension Job {'):]
enums = (root / 'DripDrop/Resources/ListOfEnum.swift').read_text()
status = enums[enums.index('enum RepairRequestStatus:'):enums.index('enum RateSheetStatus:')]
images = (root / 'DripDrop/Modules/Photos/DripDropImage.swift').read_text()
image_model = images[images.index('struct DripDropStoredImage:'):]
stubs = '''
import Foundation
struct Job {
    var issuePriorityLevel: Int?; var issuePriorityLabel: String?
    var priorityLevel: Int?; var priorityLabel: String?
    var solutionTier: Int?; var solutionTierLabel: String?
}
'''
checks = r'''
let base: [String: Any] = ["id": "request", "customerId": "customer", "customerName": "Taylor", "requesterId": "tech", "requesterName": "Alex", "date": 0, "status": "Unresolved", "description": "Leaking pump", "jobIds": ["existing-job"], "photoUrls": []]
func read(_ fields: [String: Any]) throws -> RepairRequest {
    try JSONDecoder().decode(RepairRequest.self, from: JSONSerialization.data(withJSONObject: base.merging(fields) { _, new in new }))
}
let legacy = try read([:])
let alias = try read(["priorityLevel": 3])
let canonical = try read(["issuePriorityLevel": 1, "priorityLevel": 4])
let invalid = try read(["issuePriorityLevel": 99])
assert(legacy.normalizedIssuePriority == .recommended)
assert(alias.normalizedIssuePriority == .preventive)
assert(canonical.normalizedIssuePriority == .critical)
assert(invalid.normalizedIssuePriority == .recommended)
for priority in JobIssuePriorityLevel.allCases {
    let webRecord = try read(["issuePriorityLevel": priority.rawValue, "issuePriorityLabel": priority.label, "priorityLevel": priority.rawValue, "priorityLabel": priority.label])
    assert(webRecord.normalizedIssuePriority == priority)
    var request = try read([:])
    request.setIssuePriority(priority)
    let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as! [String: Any]
    assert(encoded["issuePriorityLevel"] as? Int == priority.rawValue)
    assert(encoded["priorityLevel"] as? Int == priority.rawValue)
    assert(encoded["issuePriorityLabel"] as? String == priority.label)
    assert(encoded["priorityLabel"] as? String == priority.label)
    let roundTrip = try JSONDecoder().decode(RepairRequest.self, from: JSONEncoder().encode(request))
    assert(roundTrip == request && roundTrip.jobIds == ["existing-job"])
    var job = Job()
    job.setIssuePriority(roundTrip.normalizedIssuePriority)
    assert(job.issuePriorityLevel == priority.rawValue && job.priorityLevel == priority.rawValue && job.solutionTier == priority.rawValue)
    assert(job.issuePriorityLabel == priority.label && job.priorityLabel == priority.label && job.solutionTierLabel == priority.label)
}
print("8 Swift request priority compatibility and job inheritance scenarios passed")
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-request-priority-') as directory:
    fixture = Path(directory) / 'main.swift'
    fixture.write_text(stubs + priority + status + image_model + model + job_helpers + checks)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-request-priority-modules', str(fixture)], check=True)
