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
   
   enum ParsingError: Error {
      case readFileError
      case couldNotDetermineFileType
      case failedBinaryParsing
      case failedASCIIParsing
   }
}

protocol MeshParsing {
   var fileURL: URL? { get set }
   var state: MeshParsingState { get }
   var solid: Solid? { get }
   var statePublisher: Published<MeshParsingState>.Publisher { get }
   var meshPublisher: Published<Solid?>.Publisher { get }
   
   func start()
}
