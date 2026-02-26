//
//  CustomGlossaryRow.swift
//  Xliffie
//
//  Created by b123400 on 2024/02/08.
//  Copyright © 2024 b123400. All rights reserved.
//

import Foundation

@objc class CustomGlossaryRow: NSObject {
    @objc var id: NSNumber?
    @objc var sourceLocale: String?
    @objc var targetLocale: String?
    @objc var source: String = ""
    @objc var target: String = ""
}
