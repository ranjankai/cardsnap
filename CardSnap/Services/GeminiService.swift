import Foundation

class GeminiService {
    static let shared = GeminiService()
    
    private var apiKey: String {
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["GEMINI_API_KEY"] as? String {
            return key
        }
        return ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
    }

    // Waterfall: tries models in order until one succeeds
    private let models = [
        "gemini-3.5-flash",
        "gemini-3.1-flash-lite",
        "gemini-3-flash-preview",
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite"
    ]

    func parseBusinessCard(rawText: String) async throws -> ParsedContact {
        let prompt = """
        You are an expert contact information extractor.
        Parse the following text extracted via OCR from a physical business card into a structured JSON object.

        OCR Text:
        \(rawText)

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

        var lastError: Error = GeminiError.allModelsFailed
        for model in models {
            do {
                let contact = try await callGemini(model: model, prompt: prompt)
                return contact
            } catch {
                print("[Gemini Waterfall] \(model) failed: \(error.localizedDescription)")
                lastError = error
                // If it's an API key error, break immediately — no point trying others
                if case GeminiError.invalidAPIKey = error { break }
            }
        }
        throw lastError
    }

    private func callGemini(model: String, prompt: String) async throws -> ParsedContact {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

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
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse {
            if http.statusCode == 400 { throw GeminiError.invalidAPIKey }
            guard http.statusCode == 200 else { throw GeminiError.invalidResponse(http.statusCode) }
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            throw GeminiError.emptyResponse
        }

        // Clean potential markdown wrapper just in case
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw GeminiError.emptyResponse
        }
        return try JSONDecoder().decode(ParsedContact.self, from: jsonData)
    }
}

// MARK: - Errors
enum GeminiError: Error, LocalizedError {
    case allModelsFailed
    case invalidURL
    case invalidAPIKey
    case invalidResponse(Int)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .allModelsFailed:       return "All AI models failed to parse the business card."
        case .invalidURL:            return "Invalid API URL."
        case .invalidAPIKey:         return "Invalid Gemini API key."
        case .invalidResponse(let c): return "Unexpected API response (HTTP \(c))."
        case .emptyResponse:         return "AI returned an empty response."
        }
    }
}

// MARK: - Response Models
struct GeminiResponse: Codable {
    let candidates: [Candidate]?
    struct Candidate: Codable {
        let content: Content?
        struct Content: Codable {
            let parts: [Part]?
            struct Part: Codable {
                let text: String?
            }
        }
    }
}
