//
//  ContentView.swift
//  Apple Wallet
//
//  Created by Matthew Pearaylall on 10/29/25.
//
import SwiftUI
import PassKit

struct ApplePayButton: UIViewRepresentable {
    var total: Decimal
    var label: String
    var onPaymentResult: (Bool) -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.startPayment), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(total: total, label: label, onPaymentResult: onPaymentResult)
    }

    class Coordinator: NSObject, PKPaymentAuthorizationViewControllerDelegate {
        var total: Decimal
        var label: String
        var onPaymentResult: (Bool) -> Void

        init(total: Decimal, label: String, onPaymentResult: @escaping (Bool) -> Void) {
            self.total = total
            self.label = label
            self.onPaymentResult = onPaymentResult
        }

        // MARK: Start payment
        @objc func startPayment() {
            let request = PKPaymentRequest()
            request.merchantIdentifier = "merchant.com.matthewpearaylall.walletdemo"
            request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
            request.merchantCapabilities = .threeDSecure
            request.countryCode = "US"
            request.currencyCode = "USD"

            // Dynamic payment summary
            request.paymentSummaryItems = [
                PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(decimal: total)),
                PKPaymentSummaryItem(label: "LEV Pawn Shop", amount: NSDecimalNumber(decimal: total))
            ]

            guard let controller = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                print("Unable to display Apple Pay Sheet.")
                onPaymentResult(false)
                return
            }

            controller.delegate = self
            UIApplication.shared.windows.first?.rootViewController?.present(controller, animated: true)
        }

        // MARK: Payment Authorized
        func paymentAuthorizationViewController(
            _ controller: PKPaymentAuthorizationViewController,
            didAuthorizePayment payment: PKPayment,
            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
        ) {
            // Send payment.token to backend here
            print("Payment Token:", payment.token)

            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        }

        // MARK: Finish Payment
        func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
            controller.dismiss(animated: true) {
                self.onPaymentResult(true)
            }
        }
    }
}
