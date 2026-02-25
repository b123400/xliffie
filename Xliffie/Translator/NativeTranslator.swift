//
//  NativeTranslator.swift
//  Xliffie
//
//  Created by b123400 on 2026/02/24.
//  Copyright © 2026 b123400. All rights reserved.
//

import Foundation
import AppKit
import Translation
import NaturalLanguage
import SwiftUI

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

    // Translate API is only available in SwiftUI, so we need to make a dummy view, add to a host view to trigger it
    // so we can finally get a proper TranslationSession.
    @objc public static func downloadInView(host: NSView, source: String, target: String, completion: @convention(block) @escaping (Error?) -> Void) {
        var hostingView: NSHostingView<TranslatorView>?
        var hasResumed = false

        let configuration = TranslationSession.Configuration(
            source: Locale.Language(identifier: source),
            target: Locale.Language(identifier: target)
        )
        let view = TranslatorView(
            configuration: configuration,
        ) { session in
            guard !hasResumed else { return }
            hasResumed = true

            Task {
                do {
                    try await session.prepareTranslation()
                } catch {
                    completion(error)
                    NSLog("Error \(error)")
                    return
                }
                DispatchQueue.main.async {
                    hostingView?.removeFromSuperview()
                    hostingView = nil
                    completion(nil)
                }
            }
        }
        let hosting = NSHostingView(rootView: view)
        // Must be attached to a window for SwiftUI lifecycle to run
        hosting.frame = .zero
        hostingView = hosting
        host.addSubview(hosting)
    }

    private struct TranslatorView: View {
            let configuration: TranslationSession.Configuration
            let onSession: (TranslationSession) async -> Void

            var body: some View {
                Color.clear
                    .translationTask(configuration) { session in
                        await onSession(session)
                    }
            }
        }
}
