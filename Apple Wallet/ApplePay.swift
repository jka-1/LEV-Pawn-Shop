//
//  ContentView.swift
//  Apple Wallet
//
//  Created by Matthew Pearaylall on 10/29/25.
//
import SwiftUI
import PassKit

struct ApplePay: View {
    var body: some View {
        VStack(spacing: 25) {
            Text("LEV Pawn Shop")
                .font(.largeTitle)
                .bold()

            Text("UCF T-Shirt – $20.00")
                .font(.title3)

            RealApplePayButton()
                .frame(width: 220, height: 50)
        }
        .padding()
    }
}

// MARK: - Apple Pay Integration
struct RealApplePayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.startPayment), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, PKPaymentAuthorizationViewControllerDelegate {
        @objc func startPayment() {
            let request = PKPaymentRequest()
            request.merchantIdentifier = "merchant.com.matthewpearaylall.walletdemo"
            request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
            request.merchantCapabilities = .threeDSecure
            request.countryCode = "US"
            request.currencyCode = "USD"

            // Example order
            request.paymentSummaryItems = [
                PKPaymentSummaryItem(label: "UCF T-Shirt", amount: NSDecimalNumber(string: "20.00")),
                PKPaymentSummaryItem(label: "UCF Merch Store", amount: NSDecimalNumber(string: "20.00"))
            ]

            guard let controller = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                print("Unable to present Apple Pay sheet.")
                return
            }
            controller.delegate = self
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(controller, animated: true)
            }

        }

        func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                                didAuthorizePayment payment: PKPayment,
                                                handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
            // ✅ In production, send payment.token to your backend for processing
            print("Payment Authorized Token: \(payment.token)")
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        }

        func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
            controller.dismiss(animated: true)
        }
    }
}

