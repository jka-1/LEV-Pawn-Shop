//
//  RegisterView.swift
//  RunnrApp
//
//  Created by Charles Jorge on 11/6/25.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var auth: RunnerAuthState
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var profileImage: UIImage? = nil
    @State private var pdfDocument: URL? = nil
    @State private var showImagePicker = false
    @State private var showPDFPicker = false
    @State private var showCamera = false
    
    // MARK: - Color Theme
    private let bgBlack = Color.black
    private let cardDark = Color(red: 0.10, green: 0.10, blue: 0.10)   // #1A1A1A
    private let gold = Color(red: 0.84, green: 0.65, blue: 0.27)       // #D6A645
    private let textGray = Color.gray.opacity(0.6)
    
    var body: some View {
        ZStack {
            bgBlack.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    // MARK: - Title
                    Text("Register")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    // MARK: - Card with Inputs
                    VStack(spacing: 20) {
                        
                        // Name
                        TextField("Full Name", text: $name)
                            .textInputAutocapitalization(.words)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        
                        // Email
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        
                        // Password
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        
                        // Profile Picture Upload
                        Button {
                            showImagePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                Text(profileImage == nil ? "Upload Profile Picture" : "Change Profile Picture")
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(gold)
                            .cornerRadius(12)
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(image: $profileImage) // custom SwiftUI wrapper for UIImagePickerController
                        }
                        
                        // PDF / Resume Upload
                        Button {
                            showPDFPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.fill")
                                Text(pdfDocument == nil ? "Upload PDF Certification / Resume" : "Change PDF")
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(gold)
                            .cornerRadius(12)
                        }
                        .fileImporter(isPresented: $showPDFPicker, allowedContentTypes: [.pdf]) { result in
                            switch result {
                            case .success(let url):
                                pdfDocument = url
                            case .failure(let error):
                                print("PDF import failed: \(error.localizedDescription)")
                            }
                        }
                        
                        // Driver License Camera Confirmation
                        Button {
                            showCamera = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Scan Driver’s License for ID Verification")
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(gold)
                            .cornerRadius(12)
                        }
                        .sheet(isPresented: $showCamera) {
                            CameraCaptureView() // custom SwiftUI camera view for capturing DL
                        }
                        
                        // Register Button
                        Button {
                            auth.register(name: name, email: email, password: password)
                            // optionally pass profileImage, pdfDocument, and DL image for server upload
                        } label: {
                            GoldButtonContent(title: "Create Account", icon: "person.fill.badge.plus", gold: gold)
                        }
                        
                    }
                    .padding(25)
                    .background(cardDark)
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.7), radius: 10, y: 3)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // MARK: - Footer
                    Text("Runnr • Powered by LEV")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.vertical, 60)
                .padding(.horizontal, 20)
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegisterView()
                .environmentObject(RunnerAuthState())
        }
    }
}
