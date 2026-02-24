//
//  Translator.swift
//  Xliffie
//
//  Created by b123400 on 2026/01/28.
//  Copyright © 2026 b123400. All rights reserved.
//

import Foundation

@objc enum TranslationError: Int, Error {
    case networkError
    case parseError
    case unsupportedLocale
    
    var localizedDescription: String {
        switch self {
        case .networkError:
            return NSLocalizedString("Network error occurred during translation", comment: "Translation network error")
        case .parseError:
            return NSLocalizedString("Failed to parse translation response", comment: "Translation parse error")
        case .unsupportedLocale:
            return NSLocalizedString("Unsupported locale", comment: "Translation unsupported locale")
        }
    }
}

@objc class Translator: NSObject {
    // MARK: Batch configuration
    
    /// The maximum number of texts to include in a single translation request.
    /// Subclasses can override this to match their API's limits.
    var batchSize: Int {
        return 1
    }
    
    // MARK: Translation
    
    func translate(texts: [String], sourceLocale: String, targetLocale: String) async throws -> [String] {
        let batches = toBatches(texts: texts)
        let source = filteredLocale(sourceLocale)
        let target = filteredLocale(targetLocale) ?? targetLocale

        return try await withThrowingTaskGroup(of: (Int, [String]).self) { group in
            for (index, batch) in batches.enumerated() {
                group.addTask {
                    let results = try await self.translateBatch(batch, source: source, target: target)
                    return (index, results)
                }
            }
            var ordered: [(Int, [String])] = []
            for try await result in group {
                ordered.append(result)
            }
            return ordered.sorted { $0.0 < $1.0 }.flatMap { $0.1 }
        }
    }
    
    func translate(texts: [String], sourceLocale: String, targetLocale: String, cached: Bool, batched: Bool) async throws -> [String] {
        // TODO: cache
        return try await self.translate(texts: texts, sourceLocale: sourceLocale, targetLocale: targetLocale)
    }
    
    /// Objective-C compatible translation method with completion handler
    @objc func translate(texts: [String], 
                        sourceLocale: String, 
                        targetLocale: String, 
                        completion: @escaping (NSError?, [String]?) -> Void) {
        Task {
            do {
                let results = try await translate(texts: texts, sourceLocale: sourceLocale, targetLocale: targetLocale)
                completion(nil, results)
            } catch {
                let nsError = error as NSError
                completion(nsError, nil)
            }
        }
    }
    
    /// Translates a single batch of texts. Subclasses must override this method.
    /// - Parameters:
    ///   - texts: The texts to translate in this batch
    ///   - source: The filtered source locale code, or nil for auto-detection
    ///   - target: The filtered target locale code
    /// - Returns: The translated texts in the same order as the input
    func translateBatch(_ texts: [String], source: String?, target: String) async throws -> [String] {
        fatalError("Subclasses must override translateBatch(_:source:target:)")
    }

    // MARK: Batch

    func toBatches(texts: [String]) -> [[String]] {
        guard batchSize > 0 else { return [texts] }
        return stride(from: 0, to: texts.count, by: batchSize).map {
            Array(texts[$0..<min($0 + batchSize, texts.count)])
        }
    }
    
    // MARK: Locale filtering
    
    /// Massages locale codes to make translation APIs happy.
    /// Returns nil if the locale should be omitted (e.g. auto-detect).
    func filteredLocale(_ code: String) -> String? {
        guard code.count > 3 else { return code }
        if code == "zh-Hant" || code == "zh-TW" { return "zh-TW" }
        if code.hasSuffix("input") { return nil }
        return String(code.prefix(2))
    }

    // MARK: Cache

    internal func cacheKeyFor(text: String, sourceLocale: String, targetLocale: String) -> String {
        // TODO: Implement later
        return "TODO"
    }

    internal func cacheFor(text: String, sourceLocale: String, targetLocale: String) -> String? {
        // TODO: Implement later
        return nil
    }
}
