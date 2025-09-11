//
//  AIIntegration.swift
//  Physician-Feedback
//
//  Created by ChangS13 on 7/18/25.
//

import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
}

struct ChatResponse: Codable {
    struct Choice: Codable {
        let message: ChatMessage
    }
    let choices: [Choice]
}

func callOpenAI(prompt: String, completion: @escaping (String?) -> Void) {
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("[API KEY]", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let messages = [
        ChatMessage(role: "system", content: "You are a healthcare AI assistant tasked with creating physician notes and recommendation based on physician-patient conversations."),
        ChatMessage(role: "user", content: prompt)
    ]

    let chatRequest = ChatRequest(model: "gpt-3.5-turbo", messages: messages)

    do {
        request.httpBody = try JSONEncoder().encode(chatRequest)
    } catch {
        print("Failed to encode request:", error)
        completion(nil)
        return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Request error:", error)
            completion(nil)
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("No HTTP response")
            completion(nil)
            return
        }

        if httpResponse.statusCode != 200 {
            print("Bad response status code:", httpResponse.statusCode)
            if let data = data, let body = String(data: data, encoding: .utf8) {
                print("Error body:", body)
            }
            completion(nil)
            return
        }

        guard let data = data else {
            print("No data received")
            completion(nil)
            return
        }

        do {
            let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
            completion(decoded.choices.first?.message.content)
        } catch {
            print("Failed to decode response:", error)
            if let body = String(data: data, encoding: .utf8) {
                print("Raw response:", body)
            }
            completion(nil)
        }
    }.resume()
}
