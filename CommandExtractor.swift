//
//  CommandExtractor.swift
//  Sergeant AI
//
//  Created by Samuel Ramirez on 12/26/25.
//

import Foundation

// MARK: - JSON Helpers

public enum JSONExtractionError: Error, LocalizedError {
    case invalidUTF8
    case noObjectsFound

    public var errorDescription: String? {
        switch self {
        case .invalidUTF8:
            return "Failed to convert string to UTF-8 data."
        case .noObjectsFound:
            return "No valid JSON objects were found in the input string."
        }
    }
}

/// Extracts all JSON objects (top-level `{ ... }`) embedded within an arbitrary string.
/// - Parameter source: A string that may contain one or more JSON objects intermixed with other text.
/// - Returns: An array of dictionaries representing each parsed JSON object.
/// - Throws: `JSONExtractionError.noObjectsFound` if nothing valid was parsed.
public func extractJSONObjects(from source: String) throws -> [[String: Any]] {
    let candidates = findBalancedCurlyJSONRanges(in: source)

    var results: [[String: Any]] = []
    results.reserveCapacity(candidates.count)

    for range in candidates {
        let substring = String(source[range])

        guard let data = substring.data(using: .utf8) else {
            continue // never fail the whole extraction
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let object = json as? [String: Any] {
                results.append(object)
            }
        } catch {
            // Ignore malformed JSON blocks
            continue
        }
    }

    guard !results.isEmpty else {
        throw JSONExtractionError.noObjectsFound
    }

    return results
}

/// Removes all top-level JSON object blocks (balanced `{ ... }`) from the input string.
/// This respects JSON string literals and escape sequences when identifying blocks to remove.
/// - Parameter source: A string that may contain one or more JSON objects intermixed with other text.
/// - Returns: The input string with all detected JSON objects removed. If none are found, returns the original string.
public func filterOutJSONObjects(from source: String) -> String {
    let ranges = findBalancedCurlyJSONRanges(in: source)
    guard !ranges.isEmpty else { return source }

    // Sort ranges to process left-to-right
    let sorted = ranges.sorted { $0.lowerBound < $1.lowerBound }

    var result = String()
    result.reserveCapacity(source.count)

    var cursor = source.startIndex

    for range in sorted {
        // Append text before this JSON block
        if cursor < range.lowerBound {
            result.append(contentsOf: source[cursor..<range.lowerBound])
        }
        // Skip the JSON block
        cursor = range.upperBound
    }

    // Append any trailing text after the last JSON block
    if cursor < source.endIndex {
        result.append(contentsOf: source[cursor..<source.endIndex])
    }

    return result
}


// MARK: - Balanced Range Scanning

/// Scans the string and returns ranges for balanced `{ ... }` blocks.
private func findBalancedCurlyJSONRanges(in source: String) -> [Range<String.Index>] {
    findBalancedRanges(in: source, opening: "{", closing: "}")
}

/// Generic balanced range finder that respects JSON string literals and escapes.
/// Finds non-overlapping top-level balanced segments.
private func findBalancedRanges(
    in source: String,
    opening: Character,
    closing: Character
) -> [Range<String.Index>] {

    var ranges: [Range<String.Index>] = []
    var stack: [String.Index] = []

    var index = source.startIndex
    var inString = false

    while index < source.endIndex {
        let ch = source[index]

        if inString {
            if ch == "\"" {
                // Count preceding backslashes to determine escape state
                var backslashCount = 0
                var prev = index
                while prev > source.startIndex {
                    prev = source.index(before: prev)
                    if source[prev] == "\\" {
                        backslashCount += 1
                    } else {
                        break
                    }
                }

                if backslashCount % 2 == 0 {
                    inString = false
                }
            }

            index = source.index(after: index)
            continue
        }

        if ch == "\"" {
            inString = true
            index = source.index(after: index)
            continue
        }

        if ch == opening {
            stack.append(index)
        } else if ch == closing, let start = stack.popLast() {
            if stack.isEmpty {
                let upper = source.index(after: index)
                ranges.append(start..<upper)
            }
        }

        index = source.index(after: index)
    }

    return ranges
}
