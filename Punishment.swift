//
//  Punishment.swift
//  Sergeant AI
//
//  Created by Samuel Ramirez on 12/26/25.
//

import Foundation
import Combine
import SwiftData
import SwiftUI

// MARK: - Model
@Model
final class Punishment: Identifiable {
    var id = UUID()
    var title: String
    var count: Int
    var detail: String
    
    init(title: String, count: Int, detail: String) {
        self.title = title
        self.count = count
        self.detail = detail
    }
}

func haptic() { UINotificationFeedbackGenerator().notificationOccurred(.error) }

final class PunishmentManager: ObservableObject{
    var context: ModelContext?
    var listOfValidPunishments = ["Pushup", "Squat"]
    
    init(context: ModelContext?){
        self.context = context
    }
    
    func configure(context: ModelContext) {
        self.context = context
    }
    
    func addPunishment(title: String, count: Int, detail: String) {
        let newPunishment = Punishment(title: title, count: count, detail: detail)
        context!.insert(newPunishment)
        haptic()
    }

    public func deletePunishment(id: UUID) {
        guard let context else { return }
        // Fetch the object with matching id and delete it
        let descriptor = FetchDescriptor<Punishment>(predicate: #Predicate { $0.id == id })
        do {
            if let punishment = try context.fetch(descriptor).first {
                context.delete(punishment)
            }
        } catch {
            // You might want to surface this error to the UI/log
            print("Failed to delete Punishment with id: \(id). Error: \(error)")
        }
    }

    public func clearPunishments() {
        guard let context else { return }
        // Fetch all Punishment objects and delete them
        let descriptor = FetchDescriptor<Punishment>()
        do {
            let all = try context.fetch(descriptor)
            for p in all {
                context.delete(p)
            }
        } catch {
            print("Failed to clear Punishments. Error: \(error)")
        }
    }
    

    public func searchStringForPunishments(text: String) {
        
        let JSONCommands: [[String: Any]]

        do {
            JSONCommands = try extractJSONObjects(from: text)
        } catch {
            return
        }
        
        for command in JSONCommands {
            if (command["exercise"] != nil) && (command["count"] != nil) {
                guard listOfValidPunishments.contains(command["exercise"] as! String) else { continue }
                let title = command["exercise"] as! String
                let count = command["count"] as! Int
                
                addPunishment(title: title, count: count, detail: "\(count) repititions")
            }
            
        }
    }
}
