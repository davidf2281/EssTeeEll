//
//  FilingSystemItem.swift
//  EssTeeEll
//
//  Created by David Fearon on 20/12/2022.
//

import Foundation

protocol FilingSystemItem: Hashable {
    var url: URL { get }
}

extension FilingSystemItem {
    static func == (lhs: Self, rhs: Self) -> Bool {
        let match = lhs.url == rhs.url
        return match
    }
}

extension FilingSystemItem {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.url)
    }
}
