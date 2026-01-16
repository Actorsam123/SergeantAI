//
//  Debug.swift
//  Sergeant AI
//
//  Created by Samuel Ramirez on 12/20/25.
//
import SwiftUI
import SwiftData
import Combine
import YOLO


enum DebugReset {
    static func wipeAppData() {
        let url = URL.applicationSupportDirectory
            .appending(path: "default.store")

        try? FileManager.default.removeItem(at: url)
        exit(0) // force relaunch
    }
}

struct DebugView: View {
    @State private var useDarkMode: Bool = false
    @ObservedObject var logger = DebugController.logger
    
    var body: some View {
        VStack(spacing: 16) {
            Toggle(isOn: $useDarkMode) {
                Text("Dark Mode")
            }
            .padding(.horizontal)

            ScrollView {
                ForEach(logger.Logs) { log in
                    Text(log.content)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
            }

            Button("Reset app") {
                DebugController.logger.Logs.removeAll()
                DebugReset.wipeAppData()
            }
            .tint(Color.red)
            .padding(.bottom)
        }
        .preferredColorScheme(useDarkMode ? .dark : .light)
    }
}


public struct Log: Identifiable {
    public var id: UUID = UUID()
    public var content: String
    
}

public class DebugController: ObservableObject {
    public var Logs: [Log] = []
    
    public static let logger = DebugController()
    
    public init() {}
        
    public func log(_ content: String) {
        Logs.append(Log(content: content))
    }
    

}

