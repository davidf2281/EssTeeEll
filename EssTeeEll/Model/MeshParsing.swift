//
//  MeshParsing.swift
//  EssTeeEll
//
//  Created by David Fearon on 20/12/2022.
//

import Foundation

enum MeshParsingState {
   case initial
   case parsing
   case parsed
   case error(ParsingError)
   
   enum FileType {
      case binary
      case ascii
      case unknown
   }
   
   enum ParsingError: Error {
      case readFileError
      case couldNotDetermineFileType
      case failedParsing(FileType)
   }
}

protocol MeshParsing {
   var fileURL: URL? { get set }
   var state: MeshParsingState { get }
   var solid: Solid? { get }
   var solidExtents: SolidExtents? { get }
   var statePublisher: Published<MeshParsingState>.Publisher { get }
   
   func start()
}
