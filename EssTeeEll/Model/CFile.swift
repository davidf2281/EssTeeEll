
//
//  CFile.swift
//
//  Created by David Fearon on 08/02/2021.
//

import Foundation

//************************************************************************************************
// CREDIT: This class adapted from https://forums.swift.org/t/read-text-file-line-by-line/28852/6
//************************************************************************************************

class CFile: FilingSystemItem, ByteReading {

    let url: URL
    private var file: UnsafeMutablePointer<FILE>?

    required init(url: URL) {
        assert(url.isFileURL, "Not a file URL")
        self.url = url
    }

    deinit {
        precondition(self.file == nil) // File must be closed before releasing the last reference.
    }

    func open() throws {
        guard let file = fopen(url.path, "r") else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }

        self.file = file
    }

    func close() {

        if let file = self.file {
            self.file = nil
            let success = ( fclose(file) == 0 )
            assert(success)
        }
    }

    func readLine(maxLength: Int = 1024) throws -> FileBytes? {

        guard let file = self.file else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(EBADF), userInfo: nil)
        }

        var buffer = FileBytes(repeating: 0, count: maxLength)

        guard fgets(&buffer, Int32(maxLength), file) != nil else {

            if feof(file) != 0 {
                return nil
            } else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            }
        }

        return buffer
    }
}
