//
//  BrowseScreen.swift
//  BigProjectUIApp
//
//  Created by Charles Jorge on 11/5/25.
//

import SwiftUI

struct BrowseScreen: View {
    var body: some View {
        VStack {
            Text("Browse the Shop")
                .font(.title)
                .padding()

            Text("Store inventory UI goes here.")
                .foregroundColor(.gray)

            Spacer()
        }
        .navigationTitle("Shop")
    }
}
