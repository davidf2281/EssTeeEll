//
//  File.swift
//  EssTeeEll
//
//  Created by David Fearon on 20/12/2022.
//

import Foundation

class File: FilingSystemItem {
    
    let url: URL
    
    init(url: URL) {
        assert(url.isFileURL, "Not a file URL")
        self.url = url
    }
}
