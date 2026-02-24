//
//  NativeTranslator.swift
//  Xliffie
//
//  Created by b123400 on 2026/02/24.
//  Copyright © 2026 b123400. All rights reserved.
//

import Foundation
import Translation
import NaturalLanguage

@available(macOS 26.0, *)
@objc class NativeTranslator: Translator {

    override var batchSize: Int {
        // Unlimited
        return 9999999999
    }

    // MARK: Translate

    override func translateBatch(_ texts: [String], source: String?, target: String) async throws -> [String] {
        let sourceLocale: Locale.Language
        if let source = source {
            sourceLocale = Locale.Language(identifier: source)
        } else {
            let recognizer = NLLanguageRecognizer()
            for text in texts {
                recognizer.processString(text)
            }
            if let l = recognizer.dominantLanguage?.rawValue {
                sourceLocale = Locale.Language(identifier: l)
            } else {
                return []
            }
        }

        let session = TranslationSession(installedSource: sourceLocale, target: Locale.Language(identifier: target))
        let result = try await session.translations(from: texts.map { TranslationSession.Request(sourceText: $0) })

        return result.map { $0.targetText }
    }
}
