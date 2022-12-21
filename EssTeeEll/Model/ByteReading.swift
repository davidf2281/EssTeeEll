//
//  ByteReading.swift
//  deedoop
//
//  Created by David Fearon on 06/03/2021.
//

import Foundation

typealias FileBytes = [CChar]

protocol ByteReading {
    func open() throws
    func close()
    func readLine(maxLength: Int) throws -> FileBytes?
}
