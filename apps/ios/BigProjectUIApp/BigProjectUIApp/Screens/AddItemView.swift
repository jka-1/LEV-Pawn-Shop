//
//  AddItemView.swift
//  BigProjectUIApp
//
//  Created by Charles Jorge on 11/5/25.
//

import SwiftUI

struct AddItemView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Add a New Item")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            Text("Take a picture of the item you want to pawn.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            NavigationLink(destination: CameraView()) {
                Text("Open Camera")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200, height: 50)
                    .background(Color.black)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .navigationTitle("Add Item")
        .padding()
    }
}
