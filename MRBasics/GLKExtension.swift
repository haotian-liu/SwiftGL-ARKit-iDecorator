//
//  GLESBasic.swift
//  MRBasics
//
//  Created by Haotian on 2017/9/29.
//  Copyright © 2017年 Haotian. All rights reserved.
//

import Foundation
import GLKit
import os.log

enum MatrixType {
    case model, view, projection
}

extension GLKVector2 {
    init(_ x: GLfloat, _ y: GLfloat) {
        self = GLKVector2Make(x, y)
    }
}

extension GLKVector3 {
    init(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
        self = GLKVector3Make(x, y, z)
    }
    init(_ v: float3) {
        self = GLKVector3Make(v.x, v.y, v.z)
    }
}

extension GLKVector4 {
    init(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ w: GLfloat) {
        self = GLKVector4Make(x, y, z, w)
    }
    init(_ v: simd_float4) {
        self = GLKVector4Make(v.x, v.y, v.z, v.w)
    }
    static prefix func - (v: GLKVector4) -> GLKVector4 {
        return GLKVector4Make(-v.x, -v.y, -v.z, -v.w)
    }
    func debug_log(_ vec: String) {
        print("Vector \(vec) Info: \(self.x) \(self.y) \(self.z) \(self.w)")
    }
}

extension GLKMatrix3 {
    init(_ row0: GLKVector3, _ row1: GLKVector3, _ row2: GLKVector3) {
        self = GLKMatrix3MakeWithRows(row0, row1, row2)
    }

    init(_ mat: GLKMatrix4) {
        self = GLKMatrix4GetMatrix3(mat)
    }

    func debug_log() {
        os_log("--------", type: .debug)
        os_log("GLKMatrix3 Info", type: .debug)
        os_log("%f %f %f", type: .debug, self.m.0, self.m.1, self.m.2)
        os_log("%f %f %f", type: .debug, self.m.3, self.m.4, self.m.5)
        os_log("%f %f %f", type: .debug, self.m.6, self.m.7, self.m.8)
    }
}

extension GLKMatrix4 {
    init(_ row0: GLKVector4, _ row1: GLKVector4, _ row2: GLKVector4, _ row3: GLKVector4) {
        self = GLKMatrix4MakeWithRows(row0, row1, row2, row3)
    }

    init(_ object: matrix_float4x4) {
        self = GLKMatrix4MakeWithColumns(
            GLKVector4(object.columns.0),
            GLKVector4(object.columns.1),
            GLKVector4(object.columns.2),
            GLKVector4(object.columns.3)
        )
    }

    func debug_log() {
        os_log("--------", type: .debug)
        os_log("GLKMatrix4 Info", type: .debug)
        os_log("%f %f %f %f", type: .debug, self.m.0, self.m.1, self.m.2, self.m.3)
        os_log("%f %f %f %f", type: .debug, self.m.4, self.m.5, self.m.6, self.m.7)
        os_log("%f %f %f %f", type: .debug, self.m.8, self.m.9, self.m.10, self.m.11)
        os_log("%f %f %f %f", type: .debug, self.m.12, self.m.13, self.m.14, self.m.15)
        os_log("--------", type: .debug)
    }

    static func * (left: GLKMatrix4, right: GLKMatrix4) -> GLKMatrix4 {
        return GLKMatrix4Multiply(left, right)
    }
}

extension float3 {
    init(_ object: GLKVector3) {
        self = float3(x: Float(object.x), y: Float(object.y), z: object.z)
    }
}

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
     */
    var translation: float3 {
        let translation = columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension CGPoint {
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}
