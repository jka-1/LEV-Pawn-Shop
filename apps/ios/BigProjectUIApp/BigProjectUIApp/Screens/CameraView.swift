import SwiftUI
import AVFoundation

struct CameraView: View {
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage?
    @State private var aiResult: String?
    @State private var isEstimating = false
    @State private var task: URLSessionDataTask?

    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                    .padding()
            } else {
                Text("No photo captured yet.")
                    .foregroundColor(.gray)
            }

            Button(action: {
                isShowingCamera = true
            }) {
                Text("Take Photo")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200, height: 50)
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding()
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(image: $capturedImage)
            }

            if let image = capturedImage {
                Button(action: { estimatePrice(image: image) }) {
                    Text(isEstimating ? "Estimating…" : "Estimate with AI")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 220, height: 50)
                        .background(isEstimating ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(isEstimating)
                .padding(.top, 8)

                if isEstimating {
                    Button(action: { cancelEstimate() }) {
                        Text("Stop")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 120, height: 44)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
            }

            if let result = aiResult {
                Text(result)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
        .navigationTitle("Camera")
    }

    func estimatePrice(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        isEstimating = true
        aiResult = nil

        let url = URL(string: "http://localhost:5000/api/estimate-price")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let b64 = data.base64EncodedString()
        let payload: [String: Any] = [
            "name": "iOS Item",
            "description": "Captured from iOS",
            "imageBase64": [
                "mimeType": "image/jpeg",
                "data": b64
            ]
        ]

        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                self.isEstimating = false
            }
            guard err == nil, let data = data else { return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let ok = json["ok"] as? Bool, ok == true,
               let price = json["price"] as? Double {
                let low = json["low"] as? Double
                let high = json["high"] as? Double
                let conf = json["confidence"] as? Double
                let parts: [String] = [
                    "AI suggests $\(Int(price))",
                    (low != nil && high != nil) ? "Range: $\(Int(low!))–$\(Int(high!))" : nil,
                    (conf != nil) ? "Confidence: \(Int((conf! * 100)))%" : nil
                ].compactMap { $0 }
                DispatchQueue.main.async {
                    self.aiResult = parts.joined(separator: " · ")
                }
            } else {
                DispatchQueue.main.async {
                    self.aiResult = "Estimate failed"
                }
            }
        let t = URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                self.isEstimating = false
            }
            guard err == nil, let data = data else { return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let ok = json["ok"] as? Bool, ok == true,
               let price = json["price"] as? Double {
                let low = json["low"] as? Double
                let high = json["high"] as? Double
                let conf = json["confidence"] as? Double
                let parts: [String] = [
                    "AI suggests $\(Int(price))",
                    (low != nil && high != nil) ? "Range: $\(Int(low!))–$\(Int(high!))" : nil,
                    (conf != nil) ? "Confidence: \(Int((conf! * 100)))%" : nil
                ].compactMap { $0 }
                DispatchQueue.main.async {
                    self.aiResult = parts.joined(separator: " · ")
                }
            } else {
                DispatchQueue.main.async {
                    self.aiResult = "Estimate failed"
                }
            }
        }
        self.task = t
        t.resume()
    }

    func cancelEstimate() {
        task?.cancel()
        task = nil
        isEstimating = false
    }
}
