//
//  Sergeant_AIApp.swift
//  Sergeant AI
//
//  Created by Samuel Ramirez on 12/14/25.
//

import SwiftUI
import SwiftData

@main
struct Sergeant_AIApp: App {
    init() {
        NotificationManager.shared.requestPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                

        }
        .modelContainer(for: [ScheduledEvent.self, ChatMessage.self, Punishment.self])
    }
}
