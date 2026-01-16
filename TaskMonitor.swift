import Foundation

@MainActor
final class TaskMonitor {

    static let shared = TaskMonitor()
    private init() {}

    /// Tracks which late events have already been reported to the LLM
    private var reportedLateEventIDs = Set<UUID>()

    /// Main entry point
    func checkForLateEvents(
        scheduledEvents: [ScheduledEvent],
        chatVM: ChatViewModel
    ) {
        let now = Date()

        // Find all late + incomplete events
        let lateEvents = scheduledEvents.filter {
            !$0.completed && $0.endTime < now
        }

        guard !lateEvents.isEmpty else { return }

        // Only report events we haven't already sent to the LLM
        let newLateEvents = lateEvents.filter {
            !reportedLateEventIDs.contains($0.id)
        }

        guard !newLateEvents.isEmpty else { return }

        // Mark them as reported
        reportedLateEventIDs.formUnion(newLateEvents.map { $0.id })

        // Build a clean, readable message
        let eventList = newLateEvents
            .map { "- \($0.title) (due \($0.startTime.formatted()))" }
            .joined(separator: "\n")

        let message = """
        System Message:
        The user failed to complete the following tasks by the specified time:

        \(eventList)

        Punish them accordingly.
        """

        Task {
            await chatVM.sendSystemMessage(content: message)
        }
    }

    /// Optional: reset reporting (e.g. on logout or hard refresh)
    func reset() {
        reportedLateEventIDs.removeAll()
    }
}
