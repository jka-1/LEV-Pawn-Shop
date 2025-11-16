//
//  BigProjectUIAppApp.swift
//  BigProjectUIApp
//
//  Created by Charles Jorge on 11/5/25.
//

import SwiftUI
import SwiftData

@main
struct BigProjectUIApp: App {

    @StateObject var session = SessionManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: Item.self)
    }
}
