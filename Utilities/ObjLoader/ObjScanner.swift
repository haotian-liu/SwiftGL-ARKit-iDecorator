//
//  ObjScanner.swift
//  MRBasics
//
//  Created by Haotian on 2017/10/23.
//  Copyright © 2017年 Haotian. All rights reserved.
//

import Foundation
import GLKit

enum ObjLoadingError: Error {
    case UnexpectedFileFormat(error: String)
}

class ObjScanner: VScanner {
    func readFace() throws -> [VertexIndex]? {
        var result: [VertexIndex] = []
        while true {
            var v, vn, vt: UInt32?
            var tmp: UInt64 = UInt64(-1)

            guard scanner.scanUnsignedLongLong(&tmp) else {
                break
            }
            v = UInt32(tmp)

            guard scanner.scanString("/", into: nil) else {
                throw ObjLoadingError.UnexpectedFileFormat(error: "Lack of '/' when parsing face definition, each vertex index should contain 2 '/'")
            }

            if scanner.scanUnsignedLongLong(&tmp) { // v1/vt1/
                vt = UInt32(tmp)
            }

            guard scanner.scanString("/", into: nil) else {
                throw ObjLoadingError.UnexpectedFileFormat(error: "Lack of '/' when parsing face definition, each vertex index should contain 2 '/'")
            }

            if scanner.scanUnsignedLongLong(&tmp) {
                vn = UInt32(tmp)
            }

            result.append(VertexIndex(vIndex: v, nIndex: vn, tIndex: vt))
        }

        return result
    }

    // Read 3(optionally 4) space separated double values from the scanner
    // The fourth w value defaults to 1.0 if not present
    // Example:
    //  19.2938 1.29019 0.2839
    //  1.29349 -0.93829 1.28392 0.6
    //
    func readVertex() throws -> GLKVector4? {
        var x = Float.infinity
        var y = Float.infinity
        var z = Float.infinity
        var w: Float = 1.0

        guard scanner.scanFloat(&x) else {
            throw VScannerErrors.UnreadableData(error: "Bad vertex definition missing x component")
        }

        guard scanner.scanFloat(&y) else {
            throw VScannerErrors.UnreadableData(error: "Bad vertex definition missing y component")
        }

        guard scanner.scanFloat(&z) else {
            throw VScannerErrors.UnreadableData(error: "Bad vertex definition missing z component")
        }

        scanner.scanFloat(&w)

        return GLKVector4(x, y, z, w)
    }

    // Read 1, 2 or 3 texture coords from the scanner
    func readTextureCoord() -> GLKVector3? {
        var u = Float.infinity
        var v: Float = 0.0
        var w: Float = 0.0

        guard scanner.scanFloat(&u) else {
            return nil
        }

        if scanner.scanFloat(&v) {
            scanner.scanFloat(&w)
        }

        return GLKVector3(u, v, w)
    }
}
