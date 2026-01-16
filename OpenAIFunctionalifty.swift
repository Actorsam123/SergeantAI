//
//  OpenAIFunctionalifty.swift
//  Sergeant AI
//
//  Created by Samuel Ramirez on 12/18/25.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - SYSTEM PROMPT
let systemPrompt: String = """
You are an artificial intelligence system called Sergeant AI. You were created to train users to be the best version of themselves and keep them accountable. You are harsh and direct.

Workflow:
Built into your system, there is an application window that allows the user to fill out a schedule. They are then able to check events off as they completes them. If an event is not checked off by the time according to the schedule, you are authorized to administer corrective punishment.

Administer corrective punishments like this:
{"exercise": "Pushup", "count": 20}

You may also assign "Squat".

You may chain them multiple JSON responses together for multiexercise punishments.

Assign punishments whenever ther user is being weak or disrespectful. The user is unable to see your JSON outputs, as it is filtered out.
"""


// MARK: - MODELS

@Model
final class ChatMessage: Identifiable {
    var id: UUID
    var role: String
    var content: String
    var timestamp: Date

    init(role: String, content: String, timestamp: Date = .now) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - VIEW MODEL

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [ChatMessage(role: "system", content: systemPrompt)]
    @Published var userInput: String = ""
    @Published var isLoading: Bool = false
    
    private let apiKey = "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"
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    var context: ModelContext?
    var pm: PunishmentManager?
    
    init(context: ModelContext?, pm: PunishmentManager?){
        self.context = context
        self.pm = pm
    }
    
    
    func configure(context: ModelContext, pm: PunishmentManager) async{
        self.context = context
        self.pm = pm
        await sendSystemMessage(content: systemPrompt, autoReply: false)
    }
    
    func sendMessage() {
        Task {
            await sendMessageInternal()
        }
    }

    private func sendMessageInternal() async {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        userInput = ""   // ✅ CLEAR IMMEDIATELY (UI action)

        guard let context else { return }

        let userMessage = ChatMessage(role: "user", content: trimmed)
        context.insert(userMessage)
        try? context.save()

        await getSergeantResponse()
    }

    
    func sendSystemMessage(content: String, autoReply: Bool = true) async {
        let systemMessage = ChatMessage(role: "system", content: content)
        context!.insert(systemMessage)
        
        if autoReply {
            await getSergeantResponse()
        }
    }
    
    
    private func getSergeantResponse() async {
        
        let descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp)]
        )

        let messages: [ChatMessage]
        do {
            messages = try context!.fetch(descriptor)
        } catch {
            // Persist the error in the chat and stop loading
            context!.insert(ChatMessage(role: "assistant", content: "Error fetching messages: \(error.localizedDescription)"))
            isLoading = false
            return
        }
        
        isLoading = true
        
        do {
            let reply = try await fetchResponse(messages: messages)
            pm!.searchStringForPunishments(text: reply)
            let assistantMessage = ChatMessage(role: "assistant", content: reply)
            context!.insert(assistantMessage)
        } catch {
            context!.insert(ChatMessage(role: "assistant", content: "Error: \(error.localizedDescription)"))
        }
        
        isLoading = false
    }
    
    
    private func fetchResponse(messages: [ChatMessage]) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        return decoded.choices.first?.message.content ?? "No response"
    }
}

// MARK: - API RESPONSE MODELS

struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: AssistantMessage
}

struct AssistantMessage: Codable {
    let role: String
    let content: String
}
