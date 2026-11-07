#!/usr/bin/env python3
"""Compile the production error presenter and check real NSError wire shapes."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'DripDrop/Resources/Errors.swift').read_text()
presenter = 'enum PermissionErrorPresentation {' + source.split('enum PermissionErrorPresentation {', 1)[1].split('enum CustomerError:', 1)[0]
checks = r'''
func check(_ condition: Bool, _ label: String) {
    precondition(condition, label)
    print("PASS: \(label)")
}
let firestore = NSError(domain: "FIRFirestoreErrorDomain", code: 7, userInfo: [NSLocalizedDescriptionKey: "Missing or insufficient permissions."])
check(firestore.userFacingMessage.contains("Firebase Firestore permission denied"), "database denials identify Firebase")
check(firestore.userFacingMessage.contains("FIRFirestoreErrorDomain/7"), "database diagnostic codes survive")
let storage = NSError(domain: "FIRStorageErrorDomain", code: -13021)
check(storage.userFacingMessage.contains("Firebase Storage permission denied"), "photo denials identify Firebase Storage")
let local = PermissionErrorPresentation.companyPermission("244", action: "finish service stops")
check(local.userFacingMessage.contains("Drip Drop permission denied"), "local role checks identify Drip Drop")
check(local.userFacingMessage.contains("Required permission: 244"), "known missing grants are shown")
let server = NSError(domain: "com.firebase.functions", code: 7, userInfo: [NSLocalizedDescriptionKey: "Active company access is required.", "details": ["permissionSource": "drip-drop"]])
check(server.userFacingMessage.contains("Drip Drop permission denied"), "tagged callable denials identify Drip Drop")
let oldServer = NSError(domain: "com.firebase.functions", code: 7)
check(oldServer.userFacingMessage.contains("source unconfirmed"), "older callable responses do not invent a source")
for (domain, code) in [("OtherDomain", 7), ("FIRFirestoreErrorDomain", 14), ("FIRFirestoreErrorDomain", 16), ("FIRStorageErrorDomain", -13010)] {
    let error = NSError(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: "Original failure"])
    check(error.userFacingMessage == "Original failure", "unrelated \(domain)/\(code) stays unchanged")
}
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-permission-errors-') as directory:
    swift = Path(directory) / 'checks.swift'
    swift.write_text('import Foundation\n' + presenter + checks)
    executable = Path(directory) / 'checks'
    subprocess.run(['swiftc', '-module-cache-path', '/private/tmp/dripdrop-permission-error-modules', str(swift), '-o', str(executable)], check=True)
    subprocess.run([str(executable)], check=True)
