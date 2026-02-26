//
//  CustomGlossaryImporter.swift
//  Xliffie
//
//  Created by b123400 on 2024/02/17.
//  Copyright © 2024 b123400. All rights reserved.
//

import Foundation
import CSV

protocol CustomGlossaryImporterDelegate: AnyObject {
    func didReadRow(_ row: CustomGlossaryRow, fromImporter importer: CustomGlossaryImporter)
}

class CustomGlossaryImporter {

    weak var delegate: (any CustomGlossaryImporterDelegate)?

    func importFromFile(_ url: URL, withCallback callback: @escaping (Error?) -> Void) -> Progress {
        let totalSize: Int64
        if let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
           let fileSize = resourceValues.fileSize {
            totalSize = Int64(fileSize)
        } else {
            totalSize = 0
        }
        let progress = Progress(totalUnitCount: totalSize)
        DispatchQueue.global(qos: .userInitiated).async {
            guard let stream = InputStream(url: url) else {
                callback(NSError(domain: "CustomGlossaryImporter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot open file"]))
                return
            }
            do {
                let reader = try CSVReader(stream: stream, hasHeaderRow: true)
                while let row = reader.next() {
                    let glossaryRow = CustomGlossaryRow()
                    glossaryRow.sourceLocale = row.count > 0 && !row[0].isEmpty ? row[0] : nil
                    glossaryRow.targetLocale = row.count > 1 && !row[1].isEmpty ? row[1] : nil
                    glossaryRow.source = row.count > 2 ? row[2] : ""
                    glossaryRow.target = row.count > 3 ? row[3] : ""
                    self.delegate?.didReadRow(glossaryRow, fromImporter: self)
                }
                callback(nil)
            } catch {
                callback(error)
            }
        }
        return progress
    }
}
