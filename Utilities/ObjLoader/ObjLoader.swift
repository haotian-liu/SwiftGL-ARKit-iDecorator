//
//  ObjLoader.swift
//  MRBasics
//
//  Created by Haotian on 2017/9/30.
//  Copyright © 2017年 Haotian. All rights reserved.
//

import Foundation
import GLKit

struct ObjEntity {
    var name: String?
    var vertices: [GLKVector4] = []
    var normals: [GLKVector4] = []
    var textureCoords: [GLKVector3] = []
    var faces: [VertexIndex] = []
}

class ObjLoader {
    private static let commentMarker = "#".first
    private static let vertexMarker = "v".first
    private static let normalMarker = "vn"
    private static let textureCoordMarker = "vt"
    private static let objectMarker = "o".first
    private static let groupMarker = "g".first
    private static let faceMarker = "f".first
    private static let materialLibraryMarker = "mtllib"
    private static let useMaterialMarker = "usemtl"

    private var state = ObjEntity()
    private var vertexCount = 0
    private var normalCount = 0
    private var textureCoordCount = 0

    var scanner: ObjScanner
    let basePath: String

    init(basePath: String, source: String) {
        self.basePath = basePath

        let sourcePath = Bundle.main.path(forResource: basePath + "/" + source, ofType: nil)
        do {
            let sourceString = try String(contentsOfFile: sourcePath!, encoding: String.Encoding.utf8)
            scanner = ObjScanner(string: sourceString)
        } catch {
            exit(1)
        }
    }

    func read() throws -> [Shape] {
        var shapes: [Shape] = []
        resetState()

        do {
            while scanner.isAvailable {
                let marker = scanner.readMarker()

                guard let m = marker, m.count > 0 else {
                    scanner.moveToNextLine()
                    continue
                }

                if ObjLoader.isComment(m) {
                    scanner.moveToNextLine()
                    continue
                }

                if ObjLoader.isVertex(m) {
                    if let v = try readVertex() {
                        state.vertices.append(v)
                    }

                    scanner.moveToNextLine()
                    continue
                }

                if ObjLoader.isNormal(m) {
                    if let n = try readVertex() {
                        state.normals.append(n)
                    }

                    scanner.moveToNextLine()
                    continue
                }

                if ObjLoader.isTextureCoord(m) {
                    if let vt = scanner.readTextureCoord() {
                        state.textureCoords.append(vt)
                    }

                    scanner.moveToNextLine()
                    continue
                }

                if ObjLoader.isObject(m) {
                    if let s = buildShape() {
                        shapes.append(s)
                    }

                    state = ObjEntity()
                    state.name = scanner.readLine()
                    scanner.moveToNextLine()
                    continue
                }

                if ObjLoader.isGroup(m) {
                    if let s = buildShape() {
                        shapes.append(s)
                    }

                    state = ObjEntity()
                    state.name = try scanner.readString()
                    scanner.moveToNextLine()
                    continue
                }

                if ObjLoader.isFace(m) {
                    if let indices = try scanner.readFace() {
                        state.faces += indices
                    }

                    scanner.moveToNextLine()
                    continue
                }

                if ObjLoader.isMaterialLibrary(m) {
//                    let filenames = try scanner.readTokens()
//                    try parseMaterialFiles(filenames)
                    scanner.moveToNextLine()
                    continue
                }

                if ObjLoader.isUseMaterial(m) {
//                    let materialName = try scanner.readString()
//
//                    guard let material = self.materialCache[materialName] else {
//                        throw ObjLoadingError.UnexpectedFileFormat(error: "Material \(materialName) referenced before it was definied")
//                    }
//
//                    state.material = material
                    scanner.moveToNextLine()
                    continue
                }

                scanner.moveToNextLine()
            }
        } catch let e {
            resetState()
            throw e
        }
        return shapes
    }
}

extension ObjLoader {
    private func readVertex() throws -> GLKVector4? {
        do {
            return try scanner.readVertex()
        } catch VScannerErrors.UnreadableData(let error) {
            throw ObjLoadingError.UnexpectedFileFormat(error: error)
        }
    }

    private func buildShape() -> Shape? {
        if state.vertices.count == 0 && state.normals.count == 0 && state.textureCoords.count == 0 {
            return nil
        }

        let result = Shape(name: state.name, vertices: state.vertices, normals: state.normals, textureCoords: state.textureCoords, faces: state.faces)
        vertexCount += state.vertices.count
        normalCount += state.normals.count
        textureCoordCount += state.textureCoords.count

        return result
    }

    private func resetState() {
        scanner.reset()

        state = ObjEntity()
        vertexCount = 0
        normalCount = 0
        textureCoordCount = 0
    }

    // MARK: static methods for checking marker type
    private static func isComment(_ marker: String) -> Bool {
        return marker.first == commentMarker
    }

    private static func isVertex(_ marker: String) -> Bool {
        return marker.count == 1 && marker.first == vertexMarker
    }

    private static func isNormal(_ marker: String) -> Bool {
        return marker.count == 2 && marker[..<marker.index(marker.startIndex, offsetBy: 2)] == normalMarker
    }

    private static func isTextureCoord(_ marker: String) -> Bool {
        return marker.count == 2 && marker[..<marker.index(marker.startIndex, offsetBy: 2)] == textureCoordMarker
    }

    private static func isObject(_ marker: String) -> Bool {
        return marker.count == 1 && marker.first == objectMarker
    }

    private static func isGroup(_ marker: String) -> Bool {
        return marker.count == 1 && marker.first == groupMarker
    }

    private static func isFace(_ marker: String) -> Bool {
        return marker.count == 1 && marker.first == faceMarker
    }

    private static func isMaterialLibrary(_ marker: String) -> Bool {
        return marker == materialLibraryMarker
    }

    private static func isUseMaterial(_ marker: String) -> Bool {
        return marker == useMaterialMarker
    }

}
