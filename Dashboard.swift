//
//  Dashboard.swift
//  Sergeant AI
//
//  Created by Samuel Ramirez on 12/26/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    
    var pm: PunishmentManager
    
    @State var CompletedEvents: [ScheduledEvent] = []
    @State var PendingEvents: [ScheduledEvent] = []
    
    @Query var punishments: [Punishment]

    // MARK: - Theme Colors
    private var background: Color {
        scheme == .dark ? .black : Color(white: 0.96)
    }

    private var primaryText: Color {
        scheme == .dark ? .white : .black
    }

    private var secondaryText: Color {
        scheme == .dark ? .gray : .secondary
    }

    private var accent: Color {
        scheme == .dark ? .red : .blue
    }

    private var cardBackground: Color {
        scheme == .dark ? Color(white: 0.1) : .white
    }

    private var punishmentBackground: Color {
        scheme == .dark
        ? Color(red: 0.15, green: 0.0, blue: 0.0)
        : Color(red: 0.92, green: 0.95, blue: 1.0)
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    header

                    if !punishments.isEmpty {
                        punishmentsSection
                    }

                    statusSection
                }
                .padding()
            }
        }
        .onAppear() {
            updateEvents(for: Date())
        }
    }
}

// MARK: - Header
private extension DashboardView {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SERGEANT AI")
                .font(.system(size: 34, weight: .heavy))
                .foregroundColor(primaryText)

            Text("DISCIPLINE • CONSISTENCY • EXECUTION")
                .font(.caption)
                .foregroundColor(secondaryText)
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Punishments
private extension DashboardView {
    var punishmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            sectionHeader("PUNISHMENTS", color: accent)
            

            ForEach(punishments) { punishment in
                punishmentButton(punishment)
            }

        }
        .onAppear() {
            
        }
    }

    func punishmentButton(_ punishment: Punishment) -> some View {
        NavigationLink {
            //RepCountingView(exercise: punishment.title)
            RepCountingView(counter: PushupCounter(target_count: punishment.count), punishment_id: punishment.id)
                .toolbar(.hidden, for: .tabBar)
                .toolbarBackground(.hidden, for: .navigationBar)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(punishment.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(primaryText)

                Text(punishment.detail)
                    .font(.caption)
                    .foregroundColor(accent.opacity(0.85))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(punishmentBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(accent.opacity(scheme == .dark ? 0.6 : 0.25), lineWidth: 1)
                    )
            )
            .shadow(
                color: accent.opacity(scheme == .dark ? 0.25 : 0.12),
                radius: 10,
                x: 0,
                y: 6
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status
private extension DashboardView {
    
    var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            sectionHeader("STATUS", color: secondaryText)

            HStack(spacing: 16) {
                statusCard(title: "Completed", value: "\(CompletedEvents.count)")
                statusCard(title: "Pending", value: "\(PendingEvents.count)")
            }
        }
    }

    func statusCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(secondaryText)

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(primaryText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
        )
    }
    
    func updateEvents(for date: Date) {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = #Predicate<ScheduledEvent> {
            $0.date >= start && $0.date < end
        }
        let sort = [SortDescriptor(\ScheduledEvent.startTime)]
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: sort)
        
        CompletedEvents = []
        PendingEvents = []

        do {
            let events = try context.fetch(descriptor)
            
            for event in events {
                if event.completed {
                    CompletedEvents.append(event)
                }
                else {
                    PendingEvents.append(event)
                }
            }
            
        } catch {
            
        }
    }
}

// MARK: - Reusable
private extension DashboardView {
    func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(color)
            .tracking(1.2)
    }
}


