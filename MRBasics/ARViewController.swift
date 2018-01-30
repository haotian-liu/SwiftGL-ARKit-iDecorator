//
//  ARViewController.swift
//  MRBasics
//
//  Created by Haotian on 2018/1/1.
//  Copyright © 2018年 Haotian. All rights reserved.
//

import GLKit
import ARKit
import os.log

class ARViewController: ViewController {
    var objects = [ARAnchor:Int]()
    var textManager: TextManager!
    var boxes = Boxes()

    private var guideMark: Int = 0
    // 0=nothing 1=tap 2=scale 3=move 4=release 5=delete

    private var lastDetected: float3?
    private var trackingObject: ModelObject?
    private var trackingPoint: (CGPoint, CGPoint)?

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messagePanel: UIVisualEffectView!

    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.handleTap(_:)))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)

        let rotateGesture = UIRotationGestureRecognizer.init(target: self, action: #selector(self.handleRotate(_:)))
        rotateGesture.delegate = self
        self.view.addGestureRecognizer(rotateGesture)

        let pinchGesture = UIPinchGestureRecognizer.init(target: self, action: #selector(self.handlePinch(_:)))
        pinchGesture.delegate = self
        self.view.addGestureRecognizer(pinchGesture)

        let panGesture = ThresholdPanGestureRecognizer.init(target: self, action: #selector(self.handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        self.view.addGestureRecognizer(panGesture)

        let pressGesture = UILongPressGestureRecognizer.init(target: self, action: #selector(self.handlePress(_:)))
        pressGesture.minimumPressDuration = 1.0
        pressGesture.delegate = self
        self.view.addGestureRecognizer(pressGesture)

        self.view.isUserInteractionEnabled = true

        setupUIControls()
        boxes.setupShader()
        boxes.setupBuffer()
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        super.glkView(view, drawIn: rect)

        glPushGroupMarkerEXT(0, "Render geometry")

        var defaultFBO = GLint()
        glGetIntegerv(GLenum(GL_FRAMEBUFFER_BINDING_OES), &defaultFBO)

//        boxes.renderObjectMark()

        glPushGroupMarkerEXT(0, "Render objects")

        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), GLuint(defaultFBO))

        glViewport(GLint(self.viewport.origin.x), GLint(self.viewport.origin.y), GLsizei(self.viewport.size.width), GLsizei(self.viewport.size.height))
        glDepthMask(GLboolean(GL_TRUE))
        glEnable(GLenum(GL_DEPTH_TEST))
        boxes.draw()
        glPopGroupMarkerEXT()
        glPopGroupMarkerEXT()
    }

    override func session(_ session: ARSession, didUpdate frame: ARFrame) {
        super.session(session, didUpdate: frame)

//        let baseIntensity: CGFloat = 40
//        let lightEstimateIntensity: CGFloat
//        if let lightEstimate = session.currentFrame?.lightEstimate {
//            lightEstimateIntensity = lightEstimate.ambientIntensity / baseIntensity
//        } else {
//            lightEstimateIntensity = baseIntensity
//        }

        // crazy test after each frame refresh!
        do {
            let screenCenter = CGPoint(x: 0.5, y: 0.5)
            let relativePoint = screenCenter
            let adjustedPoint = CGPoint(x: relativePoint.y * self.viewport.size.width, y: (1.0 - relativePoint.x) * self.viewport.size.height)

            let results = anchorHitTest(relativePoint, adjustedPoint, lastObjectPosition: lastDetected)
            for (transform, translation) in results {
                if let transform = transform {
                    lastDetected = transform.translation
//                    let anchor = ARAnchor(transform: transform)
//                    self.arSession.add(anchor: anchor)
                } else if let translation = translation {
                    lastDetected = translation
                }
            }
//            print("\(String(describing: lastDetected?.x)) \(String(describing: lastDetected?.y)) \(String(describing: lastDetected?.z))")
        }

        do {
            if let (relativePoint, adjustedPoint) = trackingPoint, let trackingObject = trackingObject {
                let results = anchorHitTest(relativePoint, adjustedPoint, lastObjectPosition: float3(trackingObject.translate), infinitePlane: true)

                for (transform, translation) in results {
                    if let transform = transform {
                        let anchor = ARAnchor(transform: transform)
                        self.arSession.add(anchor: anchor)
                        trackingObject.translate = GLKVector3(transform.translation)
                    } else if let translation = translation {
                        trackingObject.translate = GLKVector3(translation)
                    }
                }
            }
        }

        boxes.updateMatrix(type: .view, mat: self.viewMatrix)
        boxes.viewport = self.viewport
    }

    override func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        super.session(session, cameraDidChangeTrackingState: camera)
        boxes.updateMatrix(type: .projection, mat: self.projectionMatrix)

        // change text manager status
        textManager.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)

        switch camera.trackingState {
        case .notAvailable:
            fallthrough
        case .limited:
            textManager.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            textManager.cancelScheduledMessage(forType: .trackingStateEscalation)
            if guideMark == 0 {
                guideMark = 1
                textManager.scheduleMessage("请在屏幕上点击以放置沙发", inSeconds: 5.0, messageType: .focusSquare)
            }
        }
    }
}

extension ARViewController {
    func setupUIControls() {
        textManager = TextManager(viewController: self)

        messagePanel.layer.cornerRadius = 3.0
        messagePanel.clipsToBounds = true
        messagePanel.isHidden = true
        messageLabel.text = ""
    }

    @objc func handlePress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: gesture.view)
        let relativePoint = CGPoint(x: point.y / (gesture.view?.frame.size.height)!, y: point.x / (gesture.view?.frame.size.width)!)
        let adjustedPoint = CGPoint(x: relativePoint.y * self.viewport.size.width, y: (1.0 - relativePoint.x) * self.viewport.size.height)

        let tappedObject = getTappedObject(by: adjustedPoint)

        if let tappedObject = tappedObject {
            trackingObject?.selected = false
            trackingObject = nil
            trackingPoint = nil
            boxes.selectedObject = nil
            boxes.remove(tappedObject)
        }
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: gesture.view)
        let relativePoint = CGPoint(x: point.y / (gesture.view?.frame.size.height)!, y: point.x / (gesture.view?.frame.size.width)!)
        let adjustedPoint = CGPoint(x: relativePoint.y * self.viewport.size.width, y: (1.0 - relativePoint.x) * self.viewport.size.height)
        //        print("Adjusted point: \(adjustedPoint.x), \(adjustedPoint.y)")
        //        os_log("tap point relative (%f, %f)\n", type: .debug, relativePoint.x, relativePoint.y)
        //        os_log("Tap gesture recognized", type: .debug)

        if guideMark < 2 {
            guideMark = 2
            textManager.cancelScheduledMessage(forType: .focusSquare)
            textManager.scheduleMessage("用两只手指伸拉、旋转控制物体大小与方向", inSeconds: 1.0, messageType: .focusSquare)
        }
        if guideMark == 4 && boxes.count > 1 {
            guideMark = 5
            textManager.cancelScheduledMessage(forType: .focusSquare)
            textManager.scheduleMessage("如果场景里物体太多，可以长按删除。", inSeconds: 5.0, messageType: .focusSquare)
        }

        let tappedObject = getTappedObject(by: adjustedPoint)
        if let selectedObject = boxes.selectedObject {
            if let tappedObject = tappedObject {
                selectedObject.selected = false
                boxes.selectedObject = tappedObject
                tappedObject.selected = true
                trackingObject = tappedObject
                trackingPoint = selectedObject.index == tappedObject.index ? trackingPoint : nil
            } else {
                selectedObject.selected = false
                trackingObject = nil
                trackingPoint = nil
                boxes.selectedObject = nil
            }
            return
        } else if let tappedObject = tappedObject {
            tappedObject.selected = true
            trackingObject = tappedObject
            boxes.selectedObject = tappedObject
            return
        }

        let results = anchorHitTest(relativePoint, adjustedPoint, lastObjectPosition: lastDetected, showMessage: true)

        for (index, (transform, translation)) in results.enumerated() {
            if let transform = transform {
                let anchor = ARAnchor(transform: transform)
                self.arSession.add(anchor: anchor)
                if index != 0 {
                    // only add one box even if multiple planes detected
                    boxes.addBox(translate: transform.translation)
                }
            } else if let translation = translation {
                boxes.addBox(translate: translation)
            } else {
                print("failed to add object")
            }
        }
    }

    private func getTappedObject(by point: CGPoint) -> ModelObject? {
        let index = boxes.getPixelMarker(point)
        guard index != 255 else { return nil }
        return boxes.getObject(at: index)
    }

    @objc func handlePan(_ gesture: ThresholdPanGestureRecognizer) {
        guard gesture.view != nil else { return }

        let point = gesture.location(in: gesture.view)
        let relativePoint = CGPoint(x: point.y / (gesture.view?.frame.size.height)!, y: point.x / (gesture.view?.frame.size.width)!)
        let adjustedPoint = CGPoint(x: relativePoint.y * self.viewport.size.width, y: (1.0 - relativePoint.x) * self.viewport.size.height)

        if guideMark == 3 {
            guideMark = 4
            textManager.cancelScheduledMessage(forType: .focusSquare)
            textManager.scheduleMessage("调整满意的话，在空白处点击，物体就会被放下", inSeconds: 3.0, messageType: .focusSquare)
        }

        switch gesture.state {
        case .began:
            let tappedObject = getTappedObject(by: adjustedPoint)
            if tappedObject == nil {
                trackingPoint = nil
                trackingObject?.selected = false
                trackingObject = nil
                boxes.selectedObject = nil
                break
            } else if let selectedObject = boxes.selectedObject, tappedObject!.index != selectedObject.index {
                selectedObject.selected = false
                trackingPoint = nil
            }
            tappedObject!.selected = true
            boxes.selectedObject = tappedObject!
            trackingObject = boxes.selectedObject
        case .changed where gesture.isThresholdExceeded:
            guard let trackingObject = trackingObject else { return }

            var translation = gesture.translation(in: gesture.view)
            translation.x = translation.x / (gesture.view?.frame.size.width)! * self.viewport.size.width
            translation.y = -translation.y / (gesture.view?.frame.size.height)! * self.viewport.size.height
            let currentPosition = boxes.projectedObject(test: trackingObject)
            let point = CGPoint(x: CGFloat(currentPosition.x) + translation.x, y: CGFloat(currentPosition.y) + translation.y)
//            let relativePoint = CGPoint(x: point.y / (gesture.view?.frame.size.height)!, y: point.x / (gesture.view?.frame.size.width)!)
            let relativePoint = CGPoint(x: point.y / self.viewport.size.height, y: 1.0 - point.x / self.viewport.size.width)
//            let adjustedPoint = CGPoint(x: relativePoint.y * self.viewport.size.width, y: (1.0 - relativePoint.x) * self.viewport.size.height)
            let adjustedPoint = point
//            print("Current point: \(currentPosition.x), \(currentPosition.y)")
//            print("translation point: \(translation.x), \(translation.y)")
//            print("Adjusted point: \(adjustedPoint.x), \(adjustedPoint.y)")
//            os_log("tap point relative (%f, %f)\n", type: .debug, relativePoint.x, relativePoint.y)

            trackingPoint = (relativePoint, adjustedPoint)

            let results = anchorHitTest(relativePoint, adjustedPoint, lastObjectPosition: float3(trackingObject.translate), infinitePlane: true)

            for (transform, translation) in results {
                if let transform = transform {
                    let anchor = ARAnchor(transform: transform)
                    self.arSession.add(anchor: anchor)
                    trackingObject.translate = GLKVector3(transform.translation)
                } else if let translation = translation {
                    trackingObject.translate = GLKVector3(translation)
                }
            }

            gesture.setTranslation(.zero, in: gesture.view)
            break
        case .changed:
            break
        default:
            trackingPoint = nil
            trackingObject = nil
            break
        }
    }

    @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) {
        guard gesture.view != nil else { return }

        if guideMark < 3 {
            guideMark = 3
            textManager.cancelScheduledMessage(forType: .focusSquare)
            textManager.scheduleMessage("尝试拖动物体来改变物体的位置", inSeconds: 1.0, messageType: .focusSquare)
        }

        if gesture.state == .began || gesture.state == .changed {
            boxes.rotate(by: gesture.rotation)
            gesture.rotation = 0
        }
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.view != nil else { return }

        if guideMark < 3 {
            guideMark = 3
            textManager.cancelScheduledMessage(forType: .focusSquare)
            textManager.scheduleMessage("尝试拖动物体来改变物体的位置", inSeconds: 1.0, messageType: .focusSquare)
        }

        if gesture.state == .began || gesture.state == .changed {
            boxes.scale(by: gesture.scale)
            gesture.scale = 1.0
        }
    }

    func anchorHitTest(_ relativePoint: CGPoint, _ adjustedPoint: CGPoint, lastObjectPosition: float3? = nil, infinitePlane: Bool = false, showMessage: Bool = false) -> [(float4x4?, float3?)] {
        let currentFrame = self.arSession.currentFrame
        let results = currentFrame?.hitTest(relativePoint, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        if let count = results?.count, count != 0 {
//            os_log("ARKit original found %d planes", type: .debug, count)
            return results!.map{ ($0.worldTransform, nil) }
        } else {
            let featureHitTestResult = hitTestWithFeatures(adjustedPoint, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0).first
            let featurePosition = featureHitTestResult?.position

            if infinitePlane || featurePosition == nil {
                if let objectPosition = lastObjectPosition,
                    let pointOnInfinitePlane = hitTestWithInfiniteHorizontalPlane(adjustedPoint, objectPosition) {
//                    os_log("Infinite plane detection success!!", type: .debug)
                    return [(nil, pointOnInfinitePlane)]
                }
            }

            if let featurePosition = featurePosition {
//                os_log("Feature point detection success!", type: .debug)
                return [(nil, featurePosition)]
            }

            let unfilteredFeatureHitTestResults = hitTestWithFeatures(adjustedPoint)
            if let result = unfilteredFeatureHitTestResults.first?.position {
//                os_log("Feature point unfiltered success!", type: .debug)
                return [(nil, result)]
            } else {
                if showMessage {
                    textManager.showMessage("试试别的地方！", autoHide: true)
                }
//                os_log("Feature point detection failed!", type: .debug)
                return [(nil, nil)]
            }
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // called after an anchor is added to the session
    }
}
