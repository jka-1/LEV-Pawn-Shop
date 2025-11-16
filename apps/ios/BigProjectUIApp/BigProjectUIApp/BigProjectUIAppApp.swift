//
//  BigProjectUIAppApp.swift
//  BigProjectUIApp
//
//  Created by Charles Jorge on 11/5/25.
//

import SwiftUI
import SwiftData

@main
struct BigProjectUIAppApp: App {
    @StateObject private var session = SessionManager.shared   // ✅ use singleton

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .modelContainer(for: Item.self)
                .preferredColorScheme(.dark)
        }
    }
}
