//
//  QuestionGenerationService.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import Foundation
import Combine

@MainActor
class QuestionGenerationService: ObservableObject {
    
    // MARK: - Configuration
    /// OpenAI API key configuration priority:
    /// 1. Static property (set programmatically)
    /// 2. Environment variable OPENAI_API_KEY_PRODUCTION (for production key)
    /// 3. Environment variable OPENAI_API_KEY_TESTING (for testing key)
    /// 4. Info.plist key OPENAI_API_KEY_PRODUCTION (production key)
    /// 5. Info.plist key OPENAI_API_KEY_TESTING (testing key - currently configured)
    /// 
    /// Note: Production key takes priority over testing key when both are available.
    /// Get your API key from: https://platform.openai.com/api-keys
    static var apiKey: String? = nil
    
    private var resolvedApiKey: String {
        // Priority: 1. Static property, 2. Environment variables (prod first), 3. Info.plist (prod first), 4. Placeholder
        if let key = Self.apiKey {
            return key
        }
        if let prodKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY_PRODUCTION"], !prodKey.isEmpty {
            return prodKey
        }
        if let testKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY_TESTING"], !testKey.isEmpty {
            return testKey
        }
        if let prodKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY_PRODUCTION") as? String, !prodKey.isEmpty {
            return prodKey
        }
        if let testKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY_TESTING") as? String, !testKey.isEmpty {
            return testKey
        }
        return "YOUR_OPENAI_API_KEY_HERE"
    }
    
    // MARK: - API Endpoint
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        // No initialization needed - uses static or environment variable
    }
    
    // MARK: - Generate Question
    
    /// Generates a question using OpenAI API
    /// - Parameters:
    ///   - categoryName: The name of the category
    ///   - likedQuestions: Up to 10 recently liked questions to understand user preferences
    ///   - dislikedQuestions: Up to 10 recently disliked questions to avoid similar content
    ///   - dislikedQuestionsWithReasons: Up to 10 recently disliked questions with their rejection reasons
    /// - Returns: A generated question string
    func generateQuestion(for categoryName: String, likedQuestions: [String] = [], dislikedQuestions: [String] = [], dislikedQuestionsWithReasons: [(question: String, reason: String?)] = []) async -> String {
        // Build prompt with category context and user preferences
        var prompt = "Give me a simple, concise conversation starting question in the \(categoryName) category. The question should be thought-provoking but easy to understand - keep it concise and direct, not overly complex unless the user has explicitly asked for a more complex question. It should spark meaningful conversation while being straightforward."
        
        // Check if user has marked at least 5 questions as "Too complex"
        let tooComplexCount = dislikedQuestionsWithReasons.filter { $0.reason == "Too complex" }.count
        if tooComplexCount >= 5 {
            prompt += " Note: The user has marked several questions as too complex, so try to offer shorter, less complex questions while still maintaining depth and meaning."
        }
        
        // Check if user has marked at least 5 questions as "Too simple"
        let tooSimpleCount = dislikedQuestionsWithReasons.filter { $0.reason == "Too simple" }.count
        if tooSimpleCount >= 5 {
            prompt += " Note: The user has marked several questions as too simple, so try to offer slightly more complex, deeper questions that require more thought and reflection."
        }
        
        // Include liked questions
        if !likedQuestions.isEmpty {
            let likedList = likedQuestions.prefix(10).map { "\"\($0)\"" }.joined(separator: ", ")
            prompt += " Recently liked questions: \(likedList)"
        }
        
        // Include disliked questions with their reasons
        if !dislikedQuestionsWithReasons.isEmpty {
            let dislikedList = dislikedQuestionsWithReasons.prefix(10).map { item in
                if let reason = item.reason {
                    return "\"\(item.question)\" because it was \(reason)"
                } else {
                    return "\"\(item.question)\""
                }
            }.joined(separator: ", ")
            prompt += " Recently disliked questions: \(dislikedList)"
        }
        
        // Final instruction
        if !likedQuestions.isEmpty || !dislikedQuestionsWithReasons.isEmpty {
            prompt += " These are questions that the user has already generated before, so don't repeat them."
        }
        
        do {
            let question = try await callOpenAIAPI(prompt: prompt)
            print("prompt: \(prompt)")
            return question
        } catch QuestionGenerationError.httpError(429) {
            print("❌ API quota exceeded (429). Please check your API key usage or credits.")
            return "Unable to generate a new question right now. Your API quota has been exceeded. Please try again later or check your billing."
        } catch QuestionGenerationError.apiError(let message) where message.contains("quota") || message.contains("429") || message.contains("insufficient_quota") {
            print("❌ API quota/credits exceeded. Message: \(message)")
            return "Unable to generate a new question right now. Your API quota has been exceeded. Please check your OpenAI account credits."
        } catch {
            print("❌ Error generating question: \(error.localizedDescription)")
            print("❌ Full error: \(error)")
            return "What's one thing you've been meaning to try but haven't gotten around to yet?"
        }
    }
    
    // MARK: - OpenAI API Call
    
    private func callOpenAIAPI(prompt: String) async throws -> String {
        let apiKey = resolvedApiKey
        
        guard apiKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw QuestionGenerationError.apiError("Please set your OpenAI API key (OPENAI_API_KEY_TESTING or OPENAI_API_KEY_PRODUCTION). See QuestionGenerationService.swift for instructions.")
        }
        
        let apiKeyPreview = String(apiKey.prefix(10))
        print("🔑 [OpenAI] Using API key starting with: \(apiKeyPreview)...")
        
        guard let url = URL(string: apiURL) else {
            throw QuestionGenerationError.invalidURL
        }
        
        print("🌐 [OpenAI] Making API call to: \(apiURL)")
        
        // OpenAI API request body
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",  // Cost-effective model with good quality
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 1.0,  // Balanced temperature for creative but coherent responses
            "frequency_penalty": 0.6,  // Moderate penalty for repetition to encourage uniqueness
            "presence_penalty": 0.4,  // Moderate penalty for topic repetition
            "max_tokens": 150  // Limit length to encourage shorter, simpler questions
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw QuestionGenerationError.invalidRequestBody
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuestionGenerationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("❌ [OpenAI] API returned status code: \(httpResponse.statusCode)")
            print("❌ [OpenAI] Response: \(responseString)")
            
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw QuestionGenerationError.apiError(message)
            }
            throw QuestionGenerationError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse OpenAI response
        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
        print("✅ [OpenAI] API Response received (first 200 chars): \(String(responseString.prefix(200)))")
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ [OpenAI] Failed to parse JSON. Full response: \(responseString)")
            throw QuestionGenerationError.invalidResponseFormat
        }
        
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let text = message["content"] as? String else {
            print("❌ [OpenAI] Failed to extract text from response. JSON structure: \(json)")
            throw QuestionGenerationError.invalidResponseFormat
        }
        
        // Clean the text: remove whitespace and quotes from start/end
        var cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove quotes from start and end if present
        if cleanedText.hasPrefix("\"") && cleanedText.hasSuffix("\"") {
            cleanedText = String(cleanedText.dropFirst().dropLast())
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        print("✅ [OpenAI] Generated question: \(cleanedText)")
        return cleanedText
    }
}

// MARK: - Error Types

enum QuestionGenerationError: LocalizedError {
    case invalidURL
    case invalidRequestBody
    case invalidResponse
    case invalidResponseFormat
    case httpError(statusCode: Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidRequestBody:
            return "Failed to create request body"
        case .invalidResponse:
            return "Invalid response from API"
        case .invalidResponseFormat:
            return "Response format not recognized"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}


