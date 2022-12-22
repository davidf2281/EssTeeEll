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
      let result: (solid: Solid?, extents: SolidExtents?)
      switch fileType {
     
         case .binary:
            result = parseBinary(fileURL)
      
         case .ascii:
            result = parseASCII(fileURL)
  
         case .unknown:
            result = (nil, nil)
      }
      
      guard let solid = result.solid, let extents = result.extents else {
         self.state = .error(.failedParsing(fileType))
         return
      }
      
      self.solidExtents = extents
      self.solid = solid
      self.state = .parsed
   }
   
   // Determines whether the given file is in binary or ASCII STL format.
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
         if let line = try cFile.readLine(maxLength: 5), line.count > 4 {
            let characters = line[0...4].map { UInt8($0) }
            let string = String(bytes: characters, encoding: .utf8)
            return string == "solid" ? .ascii : .binary
         }
         return .unknown
      } catch {
         return .unknown
      }
   }
   
   private func parseBinary(_ fileURL: URL) -> (solid: Solid?, extents: SolidExtents?) {
      
      let startTime = Date()
      
      let headerLength = 80
      let facetCount: UInt32

      guard let inputStream = InputStream(url: fileURL) else {
         return (nil, nil)
      }
      
      inputStream.open()
      
      defer {
         inputStream.close()
      }
      
      // Throw away the 80-byte header
      let headerBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: headerLength)
      let headerBytesRead = inputStream.read(headerBuffer, maxLength: headerLength)
      headerBuffer.deallocate()
      guard headerBytesRead == 80 else {
         return (nil, nil)
      }
      
      let facetCountBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
      let facetCountBytesRead = inputStream.read(facetCountBuffer, maxLength: 4)
      guard facetCountBytesRead == 4 else {
         return (nil, nil)
      }
      
      let facetCountBoundBuffer = UnsafeMutableRawPointer(facetCountBuffer).bindMemory(to: UInt32.self, capacity: 1)
      facetCount = facetCountBoundBuffer.pointee
      facetCountBoundBuffer.deallocate()
      
      print("There are \(facetCount) facets")
                  
      var parsingProgressCount = 0
      let parsingProgressUpdateThreshold = 1000
      
      var minX = Float.greatestFiniteMagnitude
      var minY = Float.greatestFiniteMagnitude
      var minZ = Float.greatestFiniteMagnitude
      var maxX = -Float.greatestFiniteMagnitude
      var maxY = -Float.greatestFiniteMagnitude
      var maxZ = -Float.greatestFiniteMagnitude

      var facets: [Solid.Facet] = []
      
      let facetBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 50)
      
      for index in 1...facetCount {
         
         let facetBufferBytesRead = inputStream.read(facetBuffer, maxLength: 50)
         guard facetBufferBytesRead == 50 else {
            return (nil, nil)
         }
         
         let i = floatFromUnsafePointer(pointer: facetBuffer, byteOffset: 0)
         let j = floatFromUnsafePointer(pointer: facetBuffer, byteOffset: 4)
         let k = floatFromUnsafePointer(pointer: facetBuffer, byteOffset: 8)
         
         let v1x = floatFromUnsafePointer(pointer: facetBuffer, byteOffset: 12)
         let v1y = floatFromUnsafePointer(pointer: facetBuffer, byteOffset: 16)
         let v1z = floatFromUnsafePointer(pointer: facetBuffer, byteOffset: 20)
         
         let v2x = floatFromUnsafePointer(pointer: facetBuffer, byteOffset: 24)
         let v2y = floatFromUnsafePointer(pointer: facetBuffer, byteOffset: 28)
         let v2z = floatFromUnsafePointer(pointer: facetBuffer, byteOffset: 32)
         
         let v3x = floatFromUnsafePointer(pointer: facetBuffer, byteOffset: 36)
         let v3y = floatFromUnsafePointer(pointer: facetBuffer, byteOffset: 40)
         let v3z = floatFromUnsafePointer(pointer: facetBuffer, byteOffset: 44)

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
      
      facetBuffer.deallocate()
      let solid = Solid(name: fileURL.lastPathComponent, facets: facets)
      let extents = SolidExtents(minX: minX, minY: minY, minZ: minZ, maxX: maxX, maxY: maxY, maxZ: maxZ)
      let elapsed = startTime.timeIntervalSinceNow
      
      print("Parsed in \(String(format: "%.2f", -elapsed)) seconds")
      
      return (solid, extents)
   }
   
   private func parseASCII(_ fileURL: URL) -> (solid: Solid?, extents: SolidExtents?) {
      return (nil, nil) // TODO:
   }
   
   private func floatFromUnsafePointer(pointer: UnsafeMutablePointer<UInt8>, byteOffset: Int) -> Float {
      let boundBuffer = UnsafeMutableRawPointer(pointer + byteOffset).bindMemory(to: Float32.self, capacity: 1)
      let float = Float(boundBuffer.pointee)
      return float
   }
   
//   private func floatsFromUnsafePointer(pointer: UnsafeMutablePointer<UInt8>, capacity: Int) -> [Float] {
//      let boundBuffer = UnsafeMutableRawPointer(pointer).bindMemory(to: Float32.self, capacity: capacity)
//      let float: [Float] = Float(boundBuffer.pointee)
//      return float
//   }
}
