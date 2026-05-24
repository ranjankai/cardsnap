import Foundation
import Vision
import CoreImage

let apiKey: String = {
    if let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: path),
       let key = dict["GEMINI_API_KEY"] as? String {
        return key
    }
    let absolutePath = "/Users/rkant/Public/CardSnap/CardSnap/Keys.plist"
    if let dict = NSDictionary(contentsOfFile: absolutePath),
       let key = dict["GEMINI_API_KEY"] as? String {
        return key
    }
    return ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
}()
let models = [
    "gemini-3.5-flash",
    "gemini-3.1-flash-lite",
    "gemini-3-flash-preview",
    "gemini-2.5-flash",
    "gemini-2.5-flash-lite"
]

func runOCR(imagePath: String) -> String {
    guard let ciImage = CIImage(contentsOf: URL(fileURLWithPath: imagePath)) else {
        print("Failed to load image")
        return ""
    }
    
    let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    
    do {
        try requestHandler.perform([request])
        guard let observations = request.results else { return "" }
        let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        return text
    } catch {
        print("OCR Error: \(error)")
        return ""
    }
}

func testGemini(text: String) async {
    print("--- OCR TEXT ---")
    print(text)
    print("----------------")
    
    let prompt = """
    You are an expert contact information extractor.
    Parse the following text extracted via OCR from a physical business card into a structured JSON object.

    OCR Text:
    \(text)

    Return ONLY a valid raw JSON object with these exact keys. No markdown, no code blocks, no explanation:
    {
      "firstName": "",
      "lastName": "",
      "jobTitle": "",
      "company": "",
      "emails": [],
      "phones": [],
      "website": "",
      "address": "",
      "linkedinUrl": ""
    }

    Rules:
    - Phones must include country code if present (e.g. +91-9999999999)
    - linkedinUrl only if explicitly printed on the card (e.g. linkedin.com/in/johndoe)
    - If a field cannot be determined, leave it as empty string or empty array
    - Do NOT invent or guess any data
    """
    
    for model in models {
        print("Testing model: \(model)...")
        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlStr) else { continue }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "temperature": 0.1
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as! HTTPURLResponse
            print("HTTP Status: \(httpResponse.statusCode)")
            if let responseStr = String(data: data, encoding: .utf8) {
                print("Response JSON length: \(responseStr.count)")
                if httpResponse.statusCode != 200 {
                    print(responseStr)
                } else {
                    print("SUCCESS! Returning payload.")
                    print(responseStr)
                    return
                }
            }
        } catch {
            print("Request error: \(error)")
        }
    }
    print("All models failed.")
}

let imagePath = "/Users/rkant/.gemini/antigravity/brain/121089b7-7cb4-4a56-b0cd-5cf3e954449b/media__1779601625667.png"
let text = runOCR(imagePath: imagePath)

let semaphore = DispatchSemaphore(value: 0)
Task {
    await testGemini(text: text)
    semaphore.signal()
}
semaphore.wait()
