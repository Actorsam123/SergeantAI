//
//  AI.swift
//  Sergeant AI
//
//  Created by Samuel Ramirez on 12/17/25.
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

// MARK: - Message Model
struct Message: Identifiable, Hashable {
    var id = UUID()
    var role: String
    var content: String
}

// MARK: - Message Bubble
struct MessageBubble: View {
    @Environment(\.colorScheme) private var scheme
    let role: String
    let content: String

    private var isUser: Bool { role == "user" }

    private var bubbleBackground: Color {
        if scheme == .dark {
            return isUser ? Color(white: 0.18) : Color(red: 0.15, green: 0.0, blue: 0.0)
        } else {
            return isUser ? Color(white: 0.9) : Color(red: 0.92, green: 0.95, blue: 1.0)
        }
    }

    private var textColor: Color {
        scheme == .dark ? .white : .black
    }

    var body: some View {
        HStack {
            if isUser { Spacer() }

            Text(content)
                .font(.system(.body, design: .rounded))
                .foregroundColor(textColor)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(bubbleBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(isUser ? .clear : .red.opacity(scheme == .dark ? 0.5 : 0.2), lineWidth: 1)
                        )
                )
                .frame(
                    maxWidth: isUser ? 300 : screenWidth * 0.85,
                    alignment: isUser ? .trailing : .leading
                )
                .padding(.horizontal, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))

            if !isUser { Spacer() }
        }
    }
}

// MARK: - Send Button Style
struct SendButton: ButtonStyle {
    @Environment(\.colorScheme) var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(14)
            .background(
                Capsule()
                    .fill(scheme == .dark ? Color.red : Color.blue)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Chat View
struct ChatView: View {

    @EnvironmentObject var vm: ChatViewModel
    @Environment(\.colorScheme) private var scheme

    @State private var userMessage: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var messages: [ChatMessage]

    private var background: Color {
        scheme == .dark ? .black : Color(white: 0.96)
    }

    var body: some View {
        VStack(spacing: 0) {

            // Messages
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 8) {
                        ForEach(messages) { msg in
                            if msg.role != "system" {
                                let filtered = filterOutJSONObjects(from: msg.content)
                                MessageBubble(role: msg.role, content: filtered)
                                    .id(msg.id)
                            }
                        }
                    }
                    .padding(.top, 12)
                    .animation(.easeInOut(duration: 0.5), value: messages.count)
                    .onChange(of: messages.count) {
                        if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Input Bar
            HStack(spacing: 12) {
                TextField("Report to Sergeant", text: $vm.userInput, axis: .vertical)
                    .focused($isTextFieldFocused)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(scheme == .dark ? Color(white: 0.15) : .white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(scheme == .dark ? .red.opacity(0.4) : .gray.opacity(0.4), lineWidth: 1)
                    )

                Button {
                    isTextFieldFocused = false
                    vm.sendMessage()
                } label: {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(SendButton())
            }
            .padding()
            .background(
                scheme == .dark
                ? Color.black.opacity(0.95)
                : Color(white: 0.97)
            )
        }
        .background(background)
        .contentShape(Rectangle())
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
}

#Preview {
    //ChatView(messages: [])
}

