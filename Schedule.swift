//
//  schedule.swift
//  Sergeant AI
//
//  Created by Samuel Ramirez on 12/14/25.
//

import Combine
import SwiftUI
import SwiftData
import Foundation
import UIKit

// MARK: - Utilities

func dateHasPassed(date: Date) -> Bool {
    Date() > date
}

func convertDateToString(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd h:mm a"
    return formatter.string(from: date)
}

func dateKey(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

func hapticDelete() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
}

// MARK: - Theme

enum AppTheme {
    static let background = Color.black
    static let card = Color(white: 0.12)
    static let accent = Color.red
    static let success = Color.green
    static let secondary = Color.gray
}

// MARK: - UI Components

struct AppCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(14)
    }
}

struct FieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(AppTheme.secondary)
    }
}

// MARK: - Data Model

@Model
class ScheduledEvent {
    let id: UUID = UUID()
    var startTime: Date
    var endTime: Date
    var date: Date
    var title: String
    var completed: Bool
    var note: String

    init(startTime: Date, endTime: Date, date: Date, title: String, completed: Bool, note: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.date = date
        self.title = title
        self.completed = completed
        self.note = note
    }
}

// MARK: - Manage Schedule

struct ManageSchedule: View {
    @EnvironmentObject var vm: ChatViewModel
    @Environment(\.modelContext) private var context

    @State private var selectedDate = Date()
    @State private var events: [ScheduledEvent] = []

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    AppCard {
                        FieldLabel(text: "Date")
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .foregroundColor(.white)
                        .onChange(of: selectedDate) { fetchEvents(for: $0) }
                    }
                    .padding(.horizontal)

                    List {
                        if events.isEmpty {
                            Text("No tasks scheduled")
                                .foregroundColor(AppTheme.secondary)
                                .listRowBackground(AppTheme.background)
                        } else {
                            ForEach(events) { event in
                                NavigationLink {
                                    LoadEventSchedule(event: event)
                                } label: {
                                    AppCard {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(event.title)
                                                    .font(.headline)
                                                    .foregroundColor(.white)

                                                Text(
                                                    "\(event.startTime.formatted(date: .omitted, time: .shortened)) – \(event.endTime.formatted(date: .omitted, time: .shortened))"
                                                )
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            }

                                            Spacer()

                                            Image(systemName: event.completed ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(
                                                    event.completed
                                                    ? AppTheme.success
                                                    : AppTheme.secondary
                                                )
                                        }
                                    }
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(AppTheme.background)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(event)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AddEventSchedule(eventDate: selectedDate)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
            .onAppear {
                fetchEvents(for: selectedDate)
            }
        }
    }

    private func fetchEvents(for date: Date) {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = #Predicate<ScheduledEvent> {
            $0.date >= start && $0.date < end
        }
        let sort = [SortDescriptor(\ScheduledEvent.startTime)]
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: sort)

        do {
            events = try context.fetch(descriptor)
        } catch {
            events = []
        }
    }

    private func delete(_ event: ScheduledEvent) {
        hapticDelete()
        context.delete(event)
        NotificationManager.shared.cancelNotification(taskID: event.id)
        fetchEvents(for: selectedDate)

        Task {
            await vm.sendSystemMessage(content: """
            System Message:
            User deleted task: "\(event.title)"
            """)
        }
    }
}

// MARK: - Add Event

struct AddEventSchedule: View {
    @EnvironmentObject var vm: ChatViewModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let eventDate: Date

    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var title = ""
    @State private var note = ""
    @FocusState private var keyboardFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
                .onTapGesture { keyboardFocused = false }

            VStack(spacing: 20) {
                AppCard {
                    FieldLabel(text: "Title")
                    TextField("What needs to get done?", text: $title)
                        .foregroundColor(.white)
                        .focused($keyboardFocused)
                }

                AppCard {
                    FieldLabel(text: "Time")
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                        .foregroundColor(.white)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                        .foregroundColor(.white)
                }

                AppCard {
                    FieldLabel(text: "Notes")
                    TextField("Optional details", text: $note, axis: .vertical)
                        .foregroundColor(.white)
                        .focused($keyboardFocused)
                }

                Button {
                    let newEvent = ScheduledEvent(
                        startTime: startTime,
                        endTime: endTime,
                        date: eventDate,
                        title: title,
                        completed: false,
                        note: note
                    )

                    context.insert(newEvent)

                    NotificationManager.shared.scheduleTaskOverdueNotification(
                        taskID: newEvent.id,
                        title: newEvent.title,
                        dueDate: newEvent.endTime
                    )

                    Task {
                        await vm.sendSystemMessage(content: """
                        System Message:
                        User added task: "\(newEvent.title)"
                        """)
                    }

                    dismiss()
                } label: {
                    Text("Add task")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(title.isEmpty)
            }
            .padding()
        }
        .navigationTitle("New task")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    keyboardFocused = false
                }
            }
        }
    }
}

// MARK: - Edit Event

struct LoadEventSchedule: View {
    @EnvironmentObject var vm: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: ScheduledEvent

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                AppCard {
                    FieldLabel(text: "Title")
                    TextField("", text: $event.title)
                        .foregroundColor(.white)
                }

                AppCard {
                    FieldLabel(text: "Time")
                    DatePicker("Start", selection: $event.startTime, displayedComponents: .hourAndMinute)
                        .foregroundColor(.white)
                    DatePicker("End", selection: $event.endTime, displayedComponents: .hourAndMinute)
                        .foregroundColor(.white)
                }

                AppCard {
                    FieldLabel(text: "Notes")
                    TextField("", text: $event.note, axis: .vertical)
                        .foregroundColor(.white)
                }

                Button {
                    event.completed = true
                    NotificationManager.shared.cancelNotification(taskID: event.id)

                    Task {
                        await vm.sendSystemMessage(content: """
                        System Message:
                        User completed task: "\(event.title)"
                        """)
                    }

                    dismiss()
                } label: {
                    Text(event.completed ? "Completed" : "Mark as complete")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(event.completed ? AppTheme.success : AppTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(event.completed)
            }
            .padding()
        }
        .navigationTitle("Edit task")
    }
}
