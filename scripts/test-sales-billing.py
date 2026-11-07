#!/usr/bin/env python3
"""Exercise the production Sales Codable models without Firebase or a device."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'DripDrop/Resources/Models.swift').read_text()

def declaration(prefix):
    start = source.index(prefix)
    return source[start:source.index('\n}', start) + 2]

names = ['SalesBillingSubscriptionStatus', 'SalesInvoiceStatus', 'SalesInvoiceType',
         'SalesInvoiceDeliveryMethod', 'SalesPaymentStatus', 'SalesPaymentMethod', 'SalesBillingMode']
code = 'import Foundation\n' + '\n'.join(declaration('enum ' + name + ':') for name in names)
code += '\nstruct SalesAgreementServiceLocationSnapshot: Codable, Hashable {}\n'
for name in ['SalesInvoiceLineItem', 'SalesInvoice', 'SalesPayment', 'SalesBillingSubscription']:
    code += '\n' + declaration('struct ' + name + ':')
    code += '\n' + declaration('extension ' + name + ' {')
code += r'''
let decoder = JSONDecoder()
let invoiceJSON = #"{"id":"invoice","companyId":"company","customerId":"customer","status":"open","currency":"usd","subtotalAmountCents":5000,"discountAmountCents":0,"taxAmountCents":0,"totalAmountCents":5000,"amountDueCents":5000,"lineItems":[{"id":"service","name":"Half visit","quantity":0.5,"unitAmountCents":10000,"totalAmountCents":5000}]}"#
let invoice = try decoder.decode(SalesInvoice.self, from: Data(invoiceJSON.utf8))
assert(invoice.stripeInvoiceId.isEmpty && invoice.stripePaymentIntentId.isEmpty && invoice.jobId.isEmpty)
assert(invoice.totalAmountCents == 5000 && invoice.lineItems[0].quantity == 0.5)
assert(invoice.lineItems[0].description.isEmpty && invoice.lineItems[0].taxable == false)
let receiptJSON = #"{"id":"payment","companyId":"company","customerId":"customer","invoiceId":"invoice","method":"stripeCard","status":"partiallyRefunded","amountCents":10000,"refundedAmountCents":4000,"grossPosted":true}"#
let receipt = try decoder.decode(SalesPayment.self, from: Data(receiptJSON.utf8))
assert(receipt.hasPostedMoney && receipt.netCollectedCents == 6000)
assert(receipt.billingProfileId.isEmpty && receipt.recordedByUserId.isEmpty && receipt.currency == "usd")
for status in ["processing", "partiallyRefunded", "disputed", "reversed", "refunded"] {
    let json = receiptJSON.replacingOccurrences(of: "partiallyRefunded", with: status)
    let value = try decoder.decode(SalesPayment.self, from: Data(json.utf8))
    assert(value.status.rawValue == status)
}
for status in ["paymentReview", "partiallyRefunded", "refunded"] {
    let value = try decoder.decode(SalesInvoice.self, from: Data(invoiceJSON.replacingOccurrences(of: "open", with: status).utf8))
    assert(value.status.rawValue == status)
}
let unknown = try decoder.decode(SalesPayment.self, from: Data(receiptJSON.replacingOccurrences(of: "partiallyRefunded", with: "futureStatus").utf8))
assert(unknown.status == .unknown && unknown.netCollectedCents == 0)
let reversed = try decoder.decode(SalesPayment.self, from: Data(receiptJSON.replacingOccurrences(of: "partiallyRefunded", with: "reversed").utf8))
assert(reversed.netCollectedCents == 0)
let subscriptionJSON = #"{"id":"sub","companyId":"company","customerId":"customer","amountCents":10000,"status":"cancellationPending"}"#
let sub = try decoder.decode(SalesBillingSubscription.self, from: Data(subscriptionJSON.utf8))
assert(sub.status == .cancellationPending && sub.stripeSubscriptionId.isEmpty && sub.intervalCount == 1)
let encoded = try JSONEncoder().encode(receipt)
let roundTrip = try decoder.decode(SalesPayment.self, from: encoded)
assert(roundTrip.netCollectedCents == 6000)
// Required money remains required; omitted optional processor fields are allowed.
let missingMoney = #"{"id":"bad","companyId":"company","customerId":"customer","status":"open","lineItems":[]}"#
assert((try? decoder.decode(SalesInvoice.self, from: Data(missingMoney.utf8))) == nil)
let creditedJSON = #"{"companyId":"company","customerId":"customer","status":"paid","totalAmountCents":10000,"amountPaidCents":8000,"stripeCreditAmountCents":2000}"#
let credited = try decoder.decode(SalesInvoice.self, from: Data(creditedJSON.utf8))
assert(credited.balanceCents == 0)
print("19 native Sales billing compatibility, fractional quantity, net collection and status checks passed")
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-sales-billing-') as directory:
    path = Path(directory) / 'main.swift'
    path.write_text(code)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-sales-billing-modules', str(path)], check=True)
