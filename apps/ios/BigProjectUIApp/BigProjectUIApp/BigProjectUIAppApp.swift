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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: Item.self)
    }
}
