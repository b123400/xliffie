//
//  Translator.swift
//  Xliffie
//
//  Created by b123400 on 2026/01/28.
//  Copyright © 2026 b123400. All rights reserved.
//

import Foundation
import Cache

let cache = Cache<String, String>()

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

enum TranslationIntermediateSource {
    case new(Int)
    case repeated(Int)
    case cached
}

@objc class Translator: NSObject {
    // MARK: Batch configuration
    
    /// The maximum number of texts to include in a single translation request.
    /// Subclasses can override this to match their API's limits.
    var batchSize: Int {
        return 1
    }
    
    // MARK: Translation
    
    @objc func translate(texts: [String], sourceLocale: String, targetLocale: String) async throws -> [String] {
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
    
    @objc func translate(texts: [String], sourceLocale: String, targetLocale: String, cached: Bool) async throws -> [String] {
        var intermediateSources: [TranslationIntermediateSource] = []
        var textFirstAppearedAt: [String: Int] = [:]
        var textsToTranslate: [String] = []
        for text in texts {
            if cached && self.cacheFor(text: text, sourceLocale: sourceLocale, targetLocale: targetLocale) != nil {
                intermediateSources.append(.cached)
                continue
            }
            let firstAppearedAt = textFirstAppearedAt[text]
            if let firstIndex = firstAppearedAt {
                intermediateSources.append(.repeated(firstIndex))
            } else {
                // Not cache, not repeated, we need to translate this
                let newIndex = textsToTranslate.count
                intermediateSources.append(.new(newIndex))
                textFirstAppearedAt[text] = newIndex
                textsToTranslate.append(text)
            }
        }

        let translatedResult = try await self.translate(texts: textsToTranslate, sourceLocale: sourceLocale, targetLocale: targetLocale)

        var result: [String] = []
        for (index, text) in texts.enumerated() {
            switch intermediateSources[index] {
            case let .new(i):
                let translated = translatedResult[i]
                result.append(translated)
                self.setCacheFor(text: text, sourceLocale: sourceLocale, targetLocale: targetLocale, targetString: translated)
            case let .repeated(i):
                let translated = translatedResult[i]
                result.append(translated)
            case .cached:
                result.append(self.cacheFor(text: text, sourceLocale: sourceLocale, targetLocale: targetLocale)!)
            }
        }

        return result
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
        return "\(self.className):\(sourceLocale):\(targetLocale):\(text)"
    }

    internal func cacheFor(text: String, sourceLocale: String, targetLocale: String) -> String? {
        return cache[self.cacheKeyFor(text: text, sourceLocale: sourceLocale, targetLocale: targetLocale)]
    }

    internal func setCacheFor(text: String, sourceLocale: String, targetLocale: String, targetString: String) {
        cache[self.cacheKeyFor(text: text, sourceLocale: sourceLocale, targetLocale: targetLocale)] = targetString
    }
}
