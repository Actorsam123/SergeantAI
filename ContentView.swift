import SwiftUI
import SwiftData
import Foundation
import AVFoundation
import Combine

// MARK: - ROOT

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query var scheduledEvents: [ScheduledEvent]
    @Query(sort: \ChatMessage.timestamp, order: .forward)
    var messages: [ChatMessage]
    
    @StateObject var vm = ChatViewModel(context: nil, pm: nil)
    @StateObject var pm = PunishmentManager(context: nil)
    
    let checkForLateTasksTimer = Timer.publish(every: 10.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house") {
                NavigationStack {
                    DashboardView(pm: pm)
                }
                
            }

            Tab("Schedule", systemImage: "calendar") {
                ManageSchedule()
                
            }
            
            Tab("Chat", systemImage: "sparkles") {
                ChatView(messages: messages)
            }
            
            
            Tab("Debug", systemImage: "keyboard") {
                DebugView()
            }
        }
        .environmentObject(vm)
        .onAppear {
            pm.configure(context: context)
            Task { await vm.configure(context: context, pm: pm) }
        }
        .environmentObject(pm)
        .onReceive(checkForLateTasksTimer) { _ in
            TaskMonitor.shared.checkForLateEvents(
                scheduledEvents: scheduledEvents,
                chatVM: vm
            )
        }
    }
}




// MARK: - PREVIEW

//#Preview {
//    ContentView()
//}

