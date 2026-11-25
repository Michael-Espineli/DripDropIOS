#!/usr/bin/env python3
"""Run the shipped web report bundle in Apple's JavaScriptCore and decode native models."""
import pathlib
import subprocess
import tempfile
root = pathlib.Path(__file__).resolve().parents[1]
source = (root / 'DripDrop/Modules/Report/ReportManager.swift').read_text()
models = source[source.index('struct BooksControls:'):source.index('struct BooksSavedReport:')]
fixture = root.parent / 'drip-drop-ecommerce/src/utils/reports/fixtures/modern-reports.json'
bundle = root / 'DripDrop/Modules/Report/ReportRuntime/reports.js'
code = '''import Foundation
import JavaScriptCore
''' + models + r'''
let context = JSContext()!
var failure: String?
context.exceptionHandler = { _, error in failure = error?.toString() }
context.evaluateScript(try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8))
func call(_ name: String, _ arguments: [Any]) throws -> String {
    failure = nil
    let result = context.objectForKeyedSubscript("ReportRuntime")!.objectForKeyedSubscript(name)!.call(withArguments: arguments)!.toString()!
    if let failure { fatalError(failure) }
    return result
}
let fixtureData = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
var fixture = try JSONSerialization.jsonObject(with: fixtureData) as! [String: Any]
var options = fixture["options"] as! [String: Any]
let catalog = try JSONSerialization.jsonObject(with: Data(call("catalogJSON", []).utf8)) as! [[String: Any]]
var checks = 0
for entry in catalog {
    for mode in ["summary", "detail"] {
        for group in ["company", "user", "customer"] {
            options["reportType"] = entry["value"]; options["mode"] = mode; options["groupBy"] = group
            fixture["options"] = options
            let json = String(decoding: try JSONSerialization.data(withJSONObject: fixture), as: UTF8.self)
            let output = try call("generateJSON", [json])
            let report = try JSONDecoder().decode(BooksReport.self, from: Data(output.utf8))
            precondition(!report.title.isEmpty)
            precondition(report.sections.allSatisfy { section in section.rows.allSatisfy { $0.count == section.columns.count } })
            precondition(!report.stats.contains { $0.value.contains("NaN") || $0.value.contains("Infinity") })
            if entry["value"] as? String == "job" { precondition(report.stats.first { $0.label == "Revenue" }?.value == "$310.00") }
            if entry["value"] as? String == "tax" { precondition(report.stats.first { $0.label == "Revenue Tax" }?.value == "$10.00") }
            for type in ["csv", "xlsx", "html"] {
                let contents = try call("exportJSON", [json, type])
                precondition(!contents.isEmpty)
                if type == "xlsx" { precondition(Data(base64Encoded: contents)!.prefix(2) == Data([80, 75])) }
            }
            checks += 1
        }
    }
}
let controls = BooksControls()
let roundTrip = try JSONDecoder().decode(BooksControls.self, from: JSONEncoder().encode(controls))
precondition(roundTrip == controls)
let month = BooksDateRange.preset("thisMonth")
precondition(month.start <= month.end)
print("Passed \(checks) JavaScriptCore report/model cases; CSV, Excel and HTML exports for every case; native controls round trip.")
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-books-') as directory:
    script = pathlib.Path(directory) / 'main.swift'
    script.write_text(code)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/books-swift-cache', str(script), str(bundle), str(fixture)], check=True)
