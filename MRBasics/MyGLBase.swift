//
//  MyGLBase.swift
//  MRBasics
//
//  Created by Haotian on 2017/9/30.
//  Copyright © 2017年 Haotian. All rights reserved.
//

import Foundation
import GLKit

class BaseEffect {
    var programId : GLuint = 0

    init(vertexShader: String, fragmentShader: String) {
        self.compile(vertexShader: vertexShader, fragmentShader: fragmentShader)
    }

    func Activate() {
        glUseProgram(self.programId)
    }

    func Deactivate() {
        glUseProgram(0)
    }

    func getUniformLocation(_ name: UnsafePointer<GLchar>!) -> Int32 {
        return glGetUniformLocation(self.programId, name)
    }
}

extension BaseEffect {
    func compileShader(_ shaderName: String, shaderType: GLenum) -> GLuint {
        let path = Bundle.main.path(forResource: shaderName, ofType: nil)

        do {
            let shaderString = try NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue)
            let shaderId = glCreateShader(shaderType)
            var shaderStringLength = GLint(Int32(shaderString.length))
            var shaderCString = shaderString.utf8String

            glShaderSource(
                shaderId,
                GLsizei(1),
                &shaderCString,
                &shaderStringLength)

            glCompileShader(shaderId)
            var compileStatus: GLint = 0
            glGetShaderiv(shaderId, GLenum(GL_COMPILE_STATUS), &compileStatus)

            if compileStatus == GL_FALSE {
                var infoLength: GLsizei = 0
                let bufferLength: GLsizei = 1024
                glGetShaderiv(shaderId, GLenum(GL_INFO_LOG_LENGTH), &infoLength)

                let info: [GLchar] = Array(repeating: GLchar(0), count: Int(bufferLength))
                var actualLength: GLsizei = 0

                glGetShaderInfoLog(shaderId, bufferLength, &actualLength, UnsafeMutablePointer(mutating: info))
                NSLog(String(validatingUTF8: info)!)
                exit(1)
            }

            return shaderId

        } catch {
            exit(1)
        }
    }

    func compile(vertexShader: String, fragmentShader: String) {
        let vertexShaderName = self.compileShader(vertexShader, shaderType: GLenum(GL_VERTEX_SHADER))
        let fragmentShaderName = self.compileShader(fragmentShader, shaderType: GLenum(GL_FRAGMENT_SHADER))

        self.programId = glCreateProgram()
        glAttachShader(self.programId, vertexShaderName)
        glAttachShader(self.programId, fragmentShaderName)

        glLinkProgram(self.programId)

        var linkStatus: GLint = 0
        glGetProgramiv(self.programId, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == GL_FALSE {
            var infoLength : GLsizei = 0
            let bufferLength : GLsizei = 1024
            glGetProgramiv(self.programId, GLenum(GL_INFO_LOG_LENGTH), &infoLength)

            let info: [GLchar] = Array(repeating: GLchar(0), count: Int(bufferLength))
            var actualLength : GLsizei = 0

            glGetProgramInfoLog(self.programId, bufferLength, &actualLength, UnsafeMutablePointer(mutating: info))
            NSLog(String(validatingUTF8: info)!)
            exit(1)
        }
    }
}
