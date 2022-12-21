//
//  MeshParser.swift
//  EssTeeEll
//
//  Created by David Fearon on 20/12/2022.
//

import Foundation

class MeshParser: MeshParsing, ObservableObject {
   var fileURL: URL?
   @Published public private(set) var state: MeshParsingState = .initial
   @Published public private(set) var solid: Solid? = nil
   var statePublisher: Published<MeshParsingState>.Publisher { $state }
   var meshPublisher: Published<Solid?>.Publisher { $solid }

   private enum FileType {
      case binary
      case ascii
      case unknown
   }
   
   func start() {
            
      guard let fileURL = self.fileURL else {
         self.state = .error(.readFileError)
         return
      }
      
      self.state = .parsing
      // Determine whether the file is in binary or ASCII STL format.
      // If the first five bytes spell 'solid' we assume it's ASCII, otherwise assume it's binary
      
      let fileType = fileType(fileURL)
      
      switch fileType {
     
         case .binary:
            guard let solid = parseBinary(fileURL) else {
               self.state = .error(.failedBinaryParsing)
               return
            }
            self.state = .parsed
            self.solid = solid
            
         case .ascii:
            guard let solid = parseASCII(fileURL) else {
               self.state = .error(.failedASCIIParsing)
               return
            }
            self.state = .parsed
            self.solid = solid

         case .unknown:
            self.state = .error(.couldNotDetermineFileType)
      }
   }
   
   private func fileType(_ fileURL: URL) -> MeshParser.FileType {
      guard let url = self.fileURL else {
         return .unknown
      }
      
      let cFile = CFile(url: url)
      
      defer {
         cFile.close()
      }
      
      do {
         try cFile.open()
         if let line = try cFile.readLine(), line.count > 4 {
            let characters = line[0...4].map { UInt8($0) }
            let string = String(bytes: characters, encoding: .utf8)
            return string == "solid" ? .ascii : .binary
         }
         return .unknown
      } catch {
         return .unknown
      }
   }
   
   private func parseBinary(_ fileURL: URL) -> Solid? {
      
      let startTime = Date()
      
      let headerLength = 80
      let facetStartIndex = 84
      let facetCount: UInt32
      let data: Data
      
      do {
         data = try Data(contentsOf: fileURL)
         facetCount = uInt32FromData(data, startIndex: headerLength)
         print("There are \(facetCount) facets")
      } catch {
         return nil
      }
      
      var facets: [Facet] = []
      var indexPointer = facetStartIndex
      
      for _ in 1...facetCount {

         let i = floatFromData(data, startIndex: indexPointer)
         indexPointer += 4
         
         let j = floatFromData(data, startIndex: indexPointer)
         indexPointer += 4
         
         let k = floatFromData(data, startIndex: indexPointer)
         indexPointer += 4
         
         let v1x = floatFromData(data, startIndex: indexPointer)
         indexPointer += 4
         
         let v1y = floatFromData(data, startIndex: indexPointer)
         indexPointer += 4
         
         let v1z = floatFromData(data, startIndex: indexPointer)
         indexPointer += 4
         
         let v2x = floatFromData(data, startIndex: indexPointer)
         indexPointer += 4
         
         let v2y = floatFromData(data, startIndex: indexPointer)
         indexPointer += 4
         
         let v2z = floatFromData(data, startIndex: indexPointer)
         indexPointer += 4
         
         let v3x = floatFromData(data, startIndex: indexPointer)
         indexPointer += 4
         
         let v3y = floatFromData(data, startIndex: indexPointer)
         indexPointer += 4
         
         let v3z = floatFromData(data, startIndex: indexPointer)
         indexPointer += 4

         // Skip over unused attribute byte count
         indexPointer += 2
                  
         let normal = Normal(i: i, j: j, k: k)
         let v1 = Vertex(x: v1x, y: v1y, z: v1z)
         let v2 = Vertex(x: v2x, y: v2y, z: v2z)
         let v3 = Vertex(x: v3x, y: v3y, z: v3z)
         
         let facet = Facet(normal: normal, outerLoop: [v1, v2, v3])
         facets.append(facet)
      }
      
      let solid = Solid(name: fileURL.lastPathComponent, facets: facets)
      
      let elapsed = startTime.timeIntervalSinceNow
      
      print("parsed in \(String(format: "%.2f", -elapsed)) seconds")
      
      return solid
   }
   
   private func uInt32FromData(_ data: Data, startIndex: Int) -> UInt32 {
      let bytes = data[startIndex...(startIndex + 3)]
      let array = [UInt8](bytes)
      let uInt = UInt32(littleEndian: array.withUnsafeBytes{ $0.load(as: UInt32.self) })
      return uInt
   }
   
   private func floatFromData(_ data: Data, startIndex: Int) -> Float {
      let bytes = data[startIndex...(startIndex + 3)]
      let array = [UInt8](bytes)
      let uInt = UInt32(littleEndian: array.withUnsafeBytes{ $0.load(as: UInt32.self) })
      let float = Float(bitPattern: uInt)
      return float
   }
   
   private func parseASCII(_ fileURL: URL) -> Solid? {
      return nil // TODO:
   }
}
