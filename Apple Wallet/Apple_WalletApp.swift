//
//  Apple_WalletApp.swift
//  Apple Wallet
//
//  Created by user288203 on 10/29/25.
//

import SwiftUI
import SwiftData

@main
struct Apple_WalletApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ApplePay()
        }
        .modelContainer(sharedModelContainer)
    }
}
