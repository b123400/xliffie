//
//  CustomGlossaryImporter.swift
//  Xliffie
//
//  Created by b123400 on 2024/02/17.
//  Copyright © 2024 b123400. All rights reserved.
//

import Foundation

protocol CustomGlossaryImporterDelegate: AnyObject {
    func didReadRow(_ row: CustomGlossaryRow, fromImporter importer: CustomGlossaryImporter)
}

class CustomGlossaryImporter: NSObject, CHCSVParserDelegate {

    weak var delegate: (any CustomGlossaryImporterDelegate)?

    private var currentRow: CustomGlossaryRow?
    private var rowNumber: Int = 0
    private var progress: Progress?
    private var callback: ((Error?) -> Void)?

    func importFromFile(_ url: URL, withCallback callback: @escaping (Error?) -> Void) -> Progress {
        self.callback = callback
        let totalSize: Int64
        if let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
           let fileSize = resourceValues.fileSize {
            totalSize = Int64(fileSize)
        } else {
            totalSize = 0
        }
        let progress = Progress(totalUnitCount: totalSize)
        self.progress = progress
        DispatchQueue.global(qos: .userInitiated).async {
            let parser = CHCSVParser(contentsOfCSVURL: url)
            parser?.delegate = self
            parser?.parse()
        }
        return progress
    }

    // MARK: - CHCSVParserDelegate

    func parser(_ parser: CHCSVParser!, didBeginLine recordNumber: UInt) {
        currentRow = CustomGlossaryRow()
        rowNumber = Int(recordNumber)
    }

    func parser(_ parser: CHCSVParser!, didReadField field: String!, at fieldIndex: Int) {
        guard rowNumber != 1, let currentRow = currentRow else { return }
        switch fieldIndex {
        case 0:
            currentRow.sourceLocale = field?.isEmpty == false ? field : nil
        case 1:
            currentRow.targetLocale = field?.isEmpty == false ? field : nil
        case 2:
            currentRow.source = field ?? ""
        case 3:
            currentRow.target = field ?? ""
        default:
            break
        }
    }

    func parser(_ parser: CHCSVParser!, didFailWithError error: Error!) {
        callback?(error)
    }

    func parser(_ parser: CHCSVParser!, didEndLine recordNumber: UInt) {
        guard rowNumber != 1, let currentRow = currentRow else { return }
        progress?.completedUnitCount = Int64(parser.totalBytesRead)
        delegate?.didReadRow(currentRow, fromImporter: self)
    }

    func parserDidEndDocument(_ parser: CHCSVParser!) {
        callback?(nil)
    }
}
