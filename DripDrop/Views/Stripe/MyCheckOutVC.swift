//
//  MyCheckOutVC.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/11/24.
//

import Foundation
import StripePaymentSheet

class MyCheckoutVC: UIViewController {
  func didTapCheckoutButton() {
    let intentConfig = PaymentSheet.IntentConfiguration(
      mode: .payment(amount: 1099, currency: "USD")
    ) { [weak self] _, _, intentCreationCallback in
      self?.handleConfirm(intentCreationCallback)
    }
    var configuration = PaymentSheet.Configuration()
    configuration.returnURL = "your-app://stripe-redirect" // Use the return url you set up in the previous step
    let paymentSheet = PaymentSheet(intentConfiguration: intentConfig, configuration: configuration)
  }

  func handleConfirm(_ intentCreationCallback: @escaping (Result<String, Error>) -> Void) {
    // ...explained later
  }
}
