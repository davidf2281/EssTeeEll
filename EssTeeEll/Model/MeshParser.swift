//
//  MeshParser.swift
//  EssTeeEll
//
//  Created by David Fearon on 20/12/2022.
//

import Foundation

class MeshParser: MeshParsing, ObservableObject {
   
   var fileURL: URL?
   public private(set) var solid: Solid? = nil
   private(set) var solidExtents: SolidExtents?
   
   @Published public private(set) var state: MeshParsingState = .initial
   var statePublisher: Published<MeshParsingState>.Publisher { $state }
   
   @Published public private(set) var parsingProgress: Float = 0
   var parsingProgressPublisher: Published<Float>.Publisher { $parsingProgress }
   
   func start() {
            
      guard let fileURL = self.fileURL else {
         self.state = .error(.readFileError)
         return
      }
      
      self.state = .parsing
      
      let fileType = fileType(fileURL)
      let result: (solid: Solid?, solidExtents: SolidExtents?)
      switch fileType {
     
         case .binary:
            result = parseBinary(fileURL)
      
         case .ascii:
            result = parseASCII(fileURL)
  
         case .unknown:
            result = (nil, nil)
      }
      
      guard let solid = result.solid, let solidExtents = result.solidExtents else {
         self.state = .error(.failedParsing(fileType))
         return
      }
      
      self.solidExtents = solidExtents
      self.solid = solid
      self.state = .parsed
   }
   
   // Determines whether the file is in binary or ASCII STL format.
   // If the first five bytes spell 'solid' we assume it's ASCII, otherwise assume it's binary
   private func fileType(_ fileURL: URL) -> MeshParsingState.FileType {
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
   
   private func parseBinary(_ fileURL: URL) -> (solid: Solid?, solidExtents: SolidExtents?) {
      
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
         return (nil, nil)
      }

      var parsingProgressCount = 0
      let parsingProgressUpdateThreshold = 1000
      
      var minX = Float.greatestFiniteMagnitude
      var minY = Float.greatestFiniteMagnitude
      var minZ = Float.greatestFiniteMagnitude
      var maxX = -Float.greatestFiniteMagnitude
      var maxY = -Float.greatestFiniteMagnitude
      var maxZ = -Float.greatestFiniteMagnitude

      var facets: [Solid.Facet] = []
      var indexPointer = facetStartIndex
      
      for index in 1...facetCount {

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
                  
         let normal = Solid.Normal(i: i, j: j, k: k)
         let v1 = Solid.Vertex(x: v1x, y: v1y, z: v1z)
         let v2 = Solid.Vertex(x: v2x, y: v2y, z: v2z)
         let v3 = Solid.Vertex(x: v3x, y: v3y, z: v3z)
         let facet = Solid.Facet(normal: normal, outerLoop: [v1, v2, v3])
         facets.append(facet)
         
         if v1x < minX { minX = v1x }
         if v2x < minX { minX = v2x }
         if v3x < minX { minX = v3x }
         
         if v1y < minY { minY = v1y }
         if v2y < minY { minY = v2y }
         if v3y < minY { minY = v3y }
         
         if v1z < minZ { minZ = v1z }
         if v2z < minZ { minZ = v2z }
         if v3z < minZ { minZ = v3z }
         
         if v1x > maxX { maxX = v1x }
         if v2x > maxX { maxX = v2x }
         if v3x > maxX { maxX = v3x }
         
         if v1y > maxY { maxY = v1y }
         if v2y > maxY { maxY = v2y }
         if v3y > maxY { maxY = v3y }
         
         if v1z > maxZ { maxZ = v1z }
         if v2z > maxZ { maxZ = v2z }
         if v3z > maxZ { maxZ = v3z }
         
         parsingProgressCount += 1
         if parsingProgressCount > parsingProgressUpdateThreshold {
            self.parsingProgress = Float(index) / Float(facetCount)
            parsingProgressCount = 0
         }
      }
      
      let solid = Solid(name: fileURL.lastPathComponent, facets: facets)
      let solidExtents = SolidExtents(minX: minX, minY: minY, minZ: minZ, maxX: maxX, maxY: maxY, maxZ: maxZ)
      let elapsed = startTime.timeIntervalSinceNow
      
      print("parsed in \(String(format: "%.2f", -elapsed)) seconds")
      
      return (solid, solidExtents)
   }
   
   private func parseASCII(_ fileURL: URL) -> (solid: Solid?, solidExtents: SolidExtents?) {
      return (nil, nil) // TODO:
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
}
