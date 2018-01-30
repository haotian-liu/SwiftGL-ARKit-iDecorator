//
//  GeometryBase.swift
//  MRBasics
//
//  Created by Haotian on 2017/10/23.
//  Copyright © 2017年 Haotian. All rights reserved.
//

import Foundation
import GLKit

class VertexIndex {
    // Vertex index, zero-based
    let vIndex: UInt32?
    // Normal index, zero-based
    let nIndex: UInt32?
    // Texture Coord index, zero-based
    let tIndex: UInt32?

    init(vIndex: UInt32?, nIndex: UInt32?, tIndex: UInt32?) {
        self.vIndex = vIndex
        self.nIndex = nIndex
        self.tIndex = tIndex
    }
}

extension VertexIndex: Equatable {}

func ==(lhs: VertexIndex, rhs: VertexIndex) -> Bool {
    return lhs.vIndex == rhs.vIndex &&
        lhs.nIndex == rhs.nIndex &&
        lhs.tIndex == rhs.tIndex
}

class Shape {
    let name: String?
    let vertices: [GLKVector4]
    let normals: [GLKVector4]
    let textureCoords: [GLKVector2]
//    let material: Material?
    let faces: [[VertexIndex]]

    init(name: String?,
                vertices: [GLKVector4],
                normals: [GLKVector4],
                textureCoords: [GLKVector2],
//                material: Material?,
                faces: [[VertexIndex]]) {
        self.name = name
        self.vertices = vertices
        self.normals = normals
        self.textureCoords = textureCoords
//        self.material = material
        self.faces = faces
    }

    func dataForVertexIndex(v: VertexIndex) -> (GLKVector4?, GLKVector4?, GLKVector2?) {
        var data: (GLKVector4?, GLKVector4?, GLKVector2?) = (nil, nil, nil)

        if let vi = v.vIndex {
            data.0 = vertices[Int(vi)]
        }

        if let ni = v.nIndex {
            data.1 = normals[Int(ni)]
        }

        if let ti = v.tIndex {
            data.2 = textureCoords[Int(ti)]
        }

        return data
    }
}

extension Shape: Equatable {
    static func ==(lhs: Shape, rhs: Shape) -> Bool {
        return true
    }
}
