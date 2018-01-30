//
//  ThresholdPanGesture.swift
//  MRBasics
//
//  Created by Haotian on 2018/1/13.
//  Copyright © 2018年 Haotian. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

/**
 A custom `UIPanGestureRecognizer` to track when a translation threshold has been exceeded
 and panning should begin.

 - Tag: ThresholdPanGesture
 */
class ThresholdPanGestureRecognizer: UIPanGestureRecognizer {

    /// Indicates whether the currently active gesture has exceeeded the threshold.
    private(set) var isThresholdExceeded = false

    /// Observe when the gesture's `state` changes to reset the threshold.
    override var state: UIGestureRecognizerState {
        didSet {
            switch state {
            case .began, .changed:
                break

            default:
                // Reset threshold check.
                isThresholdExceeded = false
            }
        }
    }

    /// Returns the threshold value that should be used dependent on the number of touches.
    private static func threshold(forTouchCount count: Int) -> CGFloat {
        switch count {
        case 1: return 30

        // Use a higher threshold for gestures using more than 1 finger. This gives other gestures priority.
        default: return 60
        }
    }

    /// - Tag: touchesMoved
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        let translationMagnitude = translation(in: view).length

        // Adjust the threshold based on the number of touches being used.
        let threshold = ThresholdPanGestureRecognizer.threshold(forTouchCount: touches.count)

        if !isThresholdExceeded && translationMagnitude > threshold {
            isThresholdExceeded = true

            // Set the overall translation to zero as the gesture should now begin.
            setTranslation(.zero, in: view)
        }
    }
}
