#!/usr/bin/env python3
"""Compare the iOS list engine against the actual web predicates and sort functions.

Runs without Firebase, app credentials, or a simulator. The web checkout must be
next to DripDropIOS (or pass its path as the first argument).
"""
from pathlib import Path
import json
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
web = Path(sys.argv[1]) if len(sys.argv) > 1 else root.parent / 'drip-drop-ecommerce'
node = r"""
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = process.argv[1];
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const jobs = read('src/views/company/jobs/Jobs.jsx');
const definitions = jobs.slice(jobs.indexOf('const OPERATIONS_QUICK_OPERATION_STATUSES'), jobs.indexOf('const SortHeaderButton'));
const plain = text => text.replace(/export /g, '');
const jobModel = plain(read('src/utils/models/Job.js')).replace(/^import .*$/gm, '');
const context = vm.createContext({ output: null });
vm.runInContext(plain(read('src/utils/models/JobPlan.js')) + '\n' + plain(read('src/utils/jobStatusFilters.js')) + '\n' + plain(read('src/utils/customerTags.js')) + '\n' + jobModel + '\n' + definitions + `
const fixtures = [];
let counter = 0;
for (const operationStatus of [...OPERATION_STATUS_OPTIONS, '']) {
  for (const billingStatus of [...BILLING_STATUS_OPTIONS, '']) {
    for (const priority of [1, 2, 3, 4, null]) {
      const index = counter++;
      fixtures.push({
        id: 'document-' + index, internalId: 'J' + index,
        customerId: index % 2 ? 'north' : 'south', customerName: index % 3 ? 'Customer 10' : 'Customer 2',
        adminId: ['uid-alex', 'member-alex', 'legacy-alex', 'uid-pat', '', 'inactive-user'][index % 6],
        adminName: index % 4 ? 'Alex' : '', type: 'Repair ' + (index % 3), description: 'Fix the pool',
        operationStatus, billingStatus, issuePriorityLevel: priority,
        dateCreated: index % 7 ? 1500000000000 + (index % 5) * 86400000 : null,
        rate: index % 11 * 1000, laborCost: index % 4 * 1000
      });
    }
  }
}
fixtures.push({id:'legacy', internalId:'J2', operationStatus:'Waiting for Parts', billingStatus:'Accepted', priorityLevel:1, rate:'5000', laborCost:'2000'});
fixtures.push({id:'zero-priority', internalId:'J3', operationStatus:'Unscheduled', billingStatus:'Accepted', issuePriorityLevel:0, priorityLevel:1, solutionTier:4});
fixtures.push({id:'string-priority', internalId:'J4', operationStatus:'Unscheduled', billingStatus:'Accepted', issuePriorityLevel:'3'});
const webJobs = fixtures.map(data => Job.fromFirestore({id:data.id,data:()=>data}));
const scenarios = [];
function scenario(name, changes = {}) {
  const mode = changes.mode || 'operations';
  const defaults = defaultFiltersForJobListView(mode);
  const config = { name, mode, operationStatuses: defaults.operationFilters, billingStatuses: defaults.billingFilters,
    priorities: defaults.priorityFilters, adminFilterActive:false, adminIds:[], search:'', sortField:'dateCreated', ascending:false, ...changes };
  const adminLookup = new Set(config.adminIds);
  if (['uid-alex','member-alex','legacy-alex'].some(id => adminLookup.has(id))) ['uid-alex','member-alex','legacy-alex'].forEach(id => adminLookup.add(id));
  const isDefault = filtersMatchJobListViewDefaults(config.operationStatuses, config.billingStatuses, config.priorities, mode);
  const selected = webJobs.filter(job => mode === 'billing' && isDefault ? isFinishedOutstandingJob(job) : statusInFilter(job.operationStatus, config.operationStatuses) && statusInFilter(job.billingStatus, config.billingStatuses))
    .filter(job => priorityInFilter(job, config.priorities))
    .filter(job => jobMatchesAdminFilters(job, config.adminFilterActive, adminLookup))
    .filter(job => !config.search.trim() || [job.customerName, job.adminName, job.internalId, job.type, job.description, job.billingStatus, job.operationStatus, getIssuePriorityLabel(getJobPriorityLevel(job))].some(value => String(value || '').toLowerCase().includes(config.search.trim().toLowerCase())));
  config.expected = sortJobs(selected, config.sortField + '-' + (config.ascending ? 'asc':'desc')).map(job => job.id);
  scenarios.push(config);
}
scenario('Operations default (old, unassigned, inactive admins, waiting parts)');
scenario('Billing default (expired/rejected outstanding)', {mode:'billing'});
scenario('Billing priority switches to custom filters', {mode:'billing',priorities:[1]});
scenario('Billing admin-only keeps preset', {mode:'billing',adminFilterActive:true,adminIds:['uid-alex']});
scenario('No priorities means no jobs', {priorities:[]});
scenario('No statuses means any status', {operationStatuses:[],billingStatuses:[]});
for (const operationStatus of OPERATION_STATUS_OPTIONS) scenario('Operation '+operationStatus,{operationStatuses:[operationStatus],billingStatuses:[]});
for (const billingStatus of BILLING_STATUS_OPTIONS) scenario('Billing '+billingStatus,{operationStatuses:[],billingStatuses:[billingStatus]});
for (const priority of [1,2,3,4]) scenario('Priority '+priority,{operationStatuses:[],billingStatuses:[],priorities:[priority]});
scenario('Empty admin selection means no jobs', {adminFilterActive:true});
for (const admin of ['uid-alex','member-alex','legacy-alex','inactive-user']) scenario('Admin '+admin,{adminFilterActive:true,adminIds:[admin]});
for (const query of [' Waiting FOR Parts ', 'Recommended', 'Customer 2', 'J10', 'fix', 'Paid', 'document-']) scenario('Search '+query,{operationStatuses:[],billingStatuses:[],search:query});
for (const sort of JOB_SORT_OPTIONS) {
  const [sortField,direction] = sort.value.split('-');
  scenario('Sort '+sort.value,{operationStatuses:[],billingStatuses:[],sortField,ascending:direction==='asc'});
}
const customersById = new Map([['north',{tags:['North','VIP']}],['south',{tags:['South']}]]);
const regions = [];
for (const userAccess of [{},{customerRegionTags:['South']},{fullCustomerRegionAccess:true},{fullCustomerRegionAccess:false,customerRegionTags:[]}]) {
  for (const role of [{},{customerRegionTags:['North']},{fullCustomerRegionAccess:false,customerRegionTags:[]}]) {
    for (const selectedRegionTag of ['', 'north', 'South']) {
      for (const enabled of [true,false]) {
        const records = [{id:'n',customerId:'north'},{id:'s',customerId:'south'},{id:'missing',customerId:'unknown'}];
        regions.push({userAccess,role,selectedRegionTag,enabled,expected:filterRecordsByCustomerTags({records,customersById,userAccess,role,selectedRegionTag,regionalAccessEnabled:enabled}).map(record=>record.id)});
      }
    }
  }
}
output = {fixtures,scenarios,regions};
`, context);
process.stdout.write(JSON.stringify(context.output));
"""
reference = json.loads(subprocess.check_output(['node', '-e', node, str(web)], text=True))
enums = (root / 'DripDrop/Resources/ListOfEnum.swift').read_text()
enums = enums[enums.index('enum JobOperationStatus:'):enums.index('enum RepairRequestStatus:')]
model = (root / 'DripDrop/Modules/Jobs/logic/JobManager.swift').read_text()
model = model[model.index('struct Job:'):model.index('protocol JobManagerProtocol')]
helpers = (root / 'DripDrop/Modules/Jobs/JobTemplate/JobTemplate+Helpers.swift').read_text()
priority = helpers[helpers.index('enum JobIssuePriorityLevel:'):helpers.index('extension JobTemplate {')] + helpers[helpers.index('extension Job {'):]
filtering = (root / 'DripDrop/Modules/Jobs/logic/JobListFiltering.swift').read_text()
stubs = "import Foundation\nstruct ServiceStopTaskTemplate: Codable, Hashable {}\nstruct JobLaborLineItem: Codable, Hashable {}\n"
checks = r"""
let file = CommandLine.arguments[1]
let data = try Data(contentsOf: URL(fileURLWithPath: file))
let reference = try JSONSerialization.jsonObject(with: data) as! [String: Any]
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .millisecondsSince1970
let jobs = try decoder.decode([Job].self, from: JSONSerialization.data(withJSONObject: reference["fixtures"]!))
let admins = [JobListAdmin(documentId: "legacy-alex", data: ["userId":"uid-alex","id":"member-alex","userName":"Alex"])]
let sortFields: [String: JobListSortField] = ["dateCreated":.dateCreated,"internalId":.internalId,"customerName":.customerName,"adminName":.adminName,"type":.type,"billingStatus":.billingStatus,"operationStatus":.operationStatus,"priority":.priority,"rate":.rate,"laborCost":.laborCost,"profit":.profit]
let scenarios = reference["scenarios"] as! [[String: Any]]
for scenario in scenarios {
    var filters = JobListFilters()
    filters.mode = scenario["mode"] as! String == "billing" ? .billing : .operations
    filters.operationStatuses = Set((scenario["operationStatuses"] as! [String]).compactMap(JobOperationStatus.init(rawValue:)))
    filters.billingStatuses = Set((scenario["billingStatuses"] as! [String]).compactMap(JobBillingStatus.init(rawValue:)))
    filters.priorities = Set(scenario["priorities"] as! [Int])
    filters.adminFilterActive = scenario["adminFilterActive"] as! Bool
    filters.adminIds = Set(scenario["adminIds"] as! [String])
    filters.search = scenario["search"] as! String
    filters.sortField = sortFields[scenario["sortField"] as! String]!
    filters.ascending = scenario["ascending"] as! Bool
    let actual = filters.apply(to: jobs, admins: admins).map(\.id)
    let expected = scenario["expected"] as! [String]
    if actual != expected {
        print("FAIL: \(scenario["name"]!): expected \(expected.prefix(15)), got \(actual.prefix(15))")
        exit(1)
    }
}
let customers = ["north":["North","VIP"], "south":["South"]]
let regions = reference["regions"] as! [[String: Any]]
for scenario in regions {
    let access = JobListRegionAccess(userAccess: scenario["userAccess"] as! [String: Any], role: scenario["role"] as! [String: Any])
    let records = [("n","north"),("s","south"),("missing","unknown")]
    let actual = records.filter { scenario["enabled"] as! Bool == false || access.includes(customerId: $0.1, customers: customers, selectedTag: scenario["selectedRegionTag"] as! String) }.map { $0.0 }
    assert(actual == scenario["expected"] as! [String], "Region parity failed: \(scenario)")
}
let sparse = try decoder.decode(Job.self, from: Data(#"{"id":"sparse","operationStatus":" Canceled ","billingStatus":"Customer Resolved","rate":"5000","issuePriorityLevel":"3","invoiceRef":{"id":"invoice","internalId":"I42"}}"#.utf8))
assert(sparse.operationStatus == .canceled && sparse.billingStatus == .customerResolved)
assert(sparse.rate == 5000 && sparse.issuePriorityLevel == 3 && sparse.invoiceRef == "I42")
assert(sparse.serviceStopIds.isEmpty && sparse.adminId.isEmpty && sparse.otherCompany == false)
let roundTrip = try JSONDecoder().decode(Job.self, from: JSONEncoder().encode(sparse))
assert(roundTrip.billingStatus == .customerResolved && roundTrip.issuePriorityLevel == 3 && roundTrip.invoiceRef == "I42")
var filters = JobListFilters()
filters.adminFilterActive = true
filters.adminIds = ["uid-alex"]
filters.search = "pool"
filters.selectMode(.billing)
assert(filters.adminFilterActive && filters.adminIds == ["uid-alex"] && filters.search == "pool")
print("Passed \(scenarios.count) web/iOS filter-and-sort comparisons across \(jobs.count) jobs, \(regions.count) region comparisons, decoding and mode-switch checks.")
"""
with tempfile.TemporaryDirectory(prefix='dripdrop-job-list-') as directory:
    directory = Path(directory)
    fixture = directory / 'reference.json'
    fixture.write_text(json.dumps(reference))
    swift = directory / 'main.swift'
    swift.write_text(stubs + enums + model + priority + filtering + checks)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-job-list-modules', str(swift), str(fixture)], check=True)
