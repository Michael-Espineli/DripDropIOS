#!/usr/bin/env python3
"""Exercise production Swift move payloads, retry IDs, awaited results and ordering."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
source = (root / 'DripDrop/Resources/FunctionsManager.swift').read_text()
def block(text, marker):
    start = text.index(marker)
    opening = text.index('{', start)
    depth = 1
    end = opening + 1
    while depth:
        if text[end] == '{': depth += 1
        elif text[end] == '}': depth -= 1
        end += 1
    return text[start:end] + '\n'
stubs = '''import Foundation
enum ServiceStopOperationStatus: String { case notFinished = "Not Finished" }
struct ServiceStop {
 var id: String
 var techId: String = "source"
 var serviceDate: Date = Date(timeIntervalSince1970: 1793088000)
 var assignmentRevision: Int? = nil
 var recurringServiceStopId: String = ""
 var operationStatus: ServiceStopOperationStatus = .notFinished
}
struct ServiceStopOrder { var id: String; var order: Int; var serviceStopId: String; var recurringServiceStopId: String }
struct recurringRouteOrder { var order: Int; var recurringServiceStopId: String }
struct RecurringRoute { var order: [recurringRouteOrder] }
struct CompanyUser { var id: String = "employeeDoc"; var userId: String = "target"; var userName: String = "Taylor" }
enum DaysOfWeek: String { case monday = "Monday" }
'''
stubs += block(source, 'enum RouteMovePayload {')
stubs += block(source, 'private actor RouteMoveRequests {')
stubs += '''final class Bridge {
 var response: [String:Any] = ["status":200,"companyId":"company"]
 var transportFails = false
 var returned = false
 func technicianWorkflow(_ name:String,payload:[String:Any]) async throws -> [String:Any] {
   try await Task.sleep(nanoseconds:1_000_000)
   if transportFails { throw NSError(domain:"network",code:-1) }
   returned = true
   return response
 }
'''
stubs += block(source, 'func updateServiceStopPermanently(') + '}\n'
vm = (root / 'DripDrop/Modules/Dashboard/Logic/MobileDailyRouteDisplayViewModel.swift').read_text()
stubs += block(vm, 'struct RouteOrderBuilder {')
checks = r'''
@main struct Checks {
 static func main() async throws {
 var count = 0
 func check(_ value: @autoclosure () -> Bool,_ message:String) { precondition(value(),message);count += 1 }
 let first = ServiceStop(id:"one",assignmentRevision:2,recurringServiceStopId:"rss1")
 let second = ServiceStop(id:"two",recurringServiceStopId:"rss2")
 let day = Calendar.current.date(from:DateComponents(year:2026,month:10,day:28))!
 let payload = RouteMovePayload.make(companyId:"company",stops:[second,first],serviceDate:day,techId:"target")
 check(payload["action"] as? String == "oneTime","One-time mode")
 check(payload["serviceDateKey"] as? String == "2026-10-28","Calendar date remains the selected date")
 check(payload["timeZone"] as? String == TimeZone.current.identifier,"Timezone fallback")
 let stops = payload["stops"] as! [[String:Any]]
 check(stops.map{$0["id"] as! String} == ["one","two"],"Stable scope ordering")
 check(stops[0]["assignmentRevision"] as? Int == 2,"Optimistic assignment revision")
 check(stops[1]["assignmentRevision"] == nil,"Legacy revision omitted")
 check(stops[0]["serviceDateMillis"] as? Double == first.serviceDate.timeIntervalSince1970*1000,"Original date snapshot")
 let requests = RouteMoveRequests()
 let id = await requests.requestId(for:"move")
 let retry = await requests.requestId(for:"move")
 check(id == retry,"A retry after failure retains identity")
 await requests.finished("move")
 let next = await requests.requestId(for:"move")
 check(next != id,"A later confirmed action gets a fresh identity")
 let bridge = Bridge()
 try await bridge.updateServiceStopPermanently(companyId:"company",serviceStopList:[first],newTech:CompanyUser(),newDay:.monday)
 check(bridge.returned,"The bridge awaits the actual server response")
 for response in [["status":500,"error":"Coverage must be resolved"],["status":200,"companyId":"wrong"],[:]] as [[String:Any]] {
   bridge.response = response
   do {try await bridge.updateServiceStopPermanently(companyId:"company",serviceStopList:[first],newTech:CompanyUser(),newDay:.monday);preconditionFailure("Must reject failed/unconfirmed result")} catch {count += 1}
 }
 bridge.transportFails = true
 do {try await bridge.updateServiceStopPermanently(companyId:"company",serviceStopList:[first],newTech:CompanyUser(),newDay:.monday);preconditionFailure("Must surface transport errors")} catch {count += 1}
 let planned = RecurringRoute(order:[recurringRouteOrder(order:1,recurringServiceStopId:"rss1"),recurringRouteOrder(order:2,recurringServiceStopId:"rss2")])
 let saved = [ServiceStopOrder(id:"two",order:1,serviceStopId:"two",recurringServiceStopId:"rss2"),ServiceStopOrder(id:"one",order:2,serviceStopId:"one",recurringServiceStopId:"rss1")]
 check(RouteOrderBuilder.build(serviceStops:[first,second],recurringRoute:planned,existingOrder:saved).map{$0.serviceStopId} == ["two","one"],"Saved daily order survives before route start")
 check(RouteOrderBuilder.build(serviceStops:[second,first],recurringRoute:planned,existingOrder:nil).map{$0.serviceStopId} == ["one","two"],"New routes use planned order")
 let order = RouteOrderBuilder.build(serviceStops:[second,ServiceStop(id:"new")],recurringRoute:planned,existingOrder:saved)
 check(order.map{$0.serviceStopId} == ["two","new"],"Moved stops disappear and new stops append")
 check(order.map{$0.order} == [1,2],"Order indexes remain contiguous")
 print("Passed \(count) Swift route-move checks")
 }
}
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-route-moves-') as directory:
    fixture = Path(directory) / 'checks.swift'
    executable = Path(directory) / 'checks'
    fixture.write_text(stubs + checks)
    subprocess.run(['swiftc','-parse-as-library','-module-cache-path','/private/tmp/dripdrop-route-move-modules',str(fixture),'-o',str(executable)],check=True)
    subprocess.run([str(executable)],check=True)
