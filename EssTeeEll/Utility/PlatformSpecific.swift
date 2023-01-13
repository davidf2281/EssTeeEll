//
//  PlatformSpecific.swift
//  EssTeeEll
//
//  Created by David Fearon on 30/12/2022.
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class PlatformSpecific {
   
   enum Color {
      case black
      case green
   }
   
#if os(iOS) || os(watchOS) || os(tvOS)
   class func color(_ color: Color) -> UIColor {
      switch color {
         case .black:
            return UIColor.black
         case .green:
            return UIColor.green
      }
   }
   
#elseif os(macOS)
   class func color(_ color: Color) -> NSColor {
      switch color {
         case .black:
            return NSColor.black
         case .green:
            return NSColor.green
      }
   }
   
#endif
}
