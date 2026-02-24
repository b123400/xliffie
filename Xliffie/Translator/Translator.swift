//
//  Translator.swift
//  Xliffie
//
//  Created by b123400 on 2026/01/28.
//  Copyright © 2026 b123400. All rights reserved.
//

import Foundation

enum TranslationError: Error {
    case networkError(Error?)
    case parseError
    case unsupportedLocale(String)
}

class Translator: NSObject {
    func translate(texts: [String], sourceLocale: String, targetLocale: String) async throws -> [String] {
        fatalError("Not implemented")
    }

    func translate(texts: [String], sourceLocale: String, targetLocale: String, cached: Bool, batched: Bool) async throws -> [String] {
        // TODO: cache
        return try await self.translate(texts: texts, sourceLocale: sourceLocale, targetLocale: targetLocale)
    }

    // MARK: Batch

    func toBatches(texts: [String]) -> [[String]] {
        return [texts]
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
