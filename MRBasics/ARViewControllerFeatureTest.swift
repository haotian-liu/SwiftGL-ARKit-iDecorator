//
//  ARViewControllerFeatureTest.swift
//  MRBasics
//
//  Created by Haotian on 2018/1/14.
//  Copyright © 2018年 Haotian. All rights reserved.
//

// Motivated by https://developer.apple.com/documentation/arkit/handling_3d_interaction_and_ui_controls_in_augmented_reality

import GLKit
import ARKit

extension ARViewController {
    // Extension for more AR Feature detection stuff

    struct HitTestRay {
        var origin: float3
        var direction: float3

        func intersectionWithHorizontalPlane(atY planeY: Float) -> float3? {
            let normalizedDirection = simd_normalize(direction)

            // Special case handling: Check if the ray is horizontal as well.
            if normalizedDirection.y == 0 {
                if origin.y == planeY {
                    /*
                     The ray is horizontal and on the plane, thus all points on the ray
                     intersect with the plane. Therefore we simply return the ray origin.
                     */
                    return origin
                } else {
                    // The ray is parallel to the plane and never intersects.
                    return nil
                }
            }

            /*
             The distance from the ray's origin to the intersection point on the plane is:
             (`pointOnPlane` - `rayOrigin`) dot `planeNormal`
             --------------------------------------------
             direction dot planeNormal
             */

            // Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
            let distance = (planeY - origin.y) / normalizedDirection.y

            // Do not return intersections behind the ray's origin.
            if distance < 0 {
                return nil
            }

            // Return the intersection point.
            return origin + (normalizedDirection * distance)
        }

    }

    struct FeatureHitTestResult {
        var position: float3
        var distanceToRayOrigin: Float
        var featureHit: float3
        var featureDistanceToHitResult: Float
    }

    // MARK: - Hit Tests

    func hitTestRayFromScreenPosition(_ point: CGPoint) -> HitTestRay? {
        guard let frame = self.arSession.currentFrame else { return nil }

        let cameraPos = frame.camera.transform.translation

        // Note: z: 1.0 will unproject() the screen position to the far clipping plane.
        let positionVec = GLKVector3(Float(point.x), Float(point.y), 1.0)
        //        let screenPosOnFarClippingPlane = unprojectPoint(positionVec)
        var ptr: [Int32] = [Int32(self.viewport.origin.x), Int32(self.viewport.origin.y), Int32(self.viewport.size.width), Int32(self.viewport.size.height)]
        let screenPosOnFarClippingPlane = GLKMathUnproject(positionVec, self.viewMatrix, self.projectionMatrix, &ptr[0], nil)

        let rayDirection = simd_normalize(float3(screenPosOnFarClippingPlane) - cameraPos)
        return HitTestRay(origin: cameraPos, direction: rayDirection)
    }

    func hitTestWithInfiniteHorizontalPlane(_ point: CGPoint, _ pointOnPlane: float3) -> float3? {
        guard let ray = hitTestRayFromScreenPosition(point) else { return nil }

        // Do not intersect with planes above the camera or if the ray is almost parallel to the plane.
        if ray.direction.y > -0.03 {
            return nil
        }

        /*
         Return the intersection of a ray from the camera through the screen position
         with a horizontal plane at height (Y axis).
         */
        return ray.intersectionWithHorizontalPlane(atY: pointOnPlane.y)
    }

    func hitTestWithFeatures(_ point: CGPoint, coneOpeningAngleInDegrees: Float, minDistance: Float = 0, maxDistance: Float = Float.greatestFiniteMagnitude, maxResults: Int = 1) -> [FeatureHitTestResult] {

        guard let features = self.arSession.currentFrame?.rawFeaturePoints, let ray = hitTestRayFromScreenPosition(point) else {
            return []
        }

        //        print("Hit test on point: \(point.x) \(point.y)")

        let maxAngleInDegrees = min(coneOpeningAngleInDegrees, 360) / 2
        let maxAngle = (maxAngleInDegrees / 180) * .pi

        let results = features.points.flatMap { featurePosition -> FeatureHitTestResult? in
            let originToFeature = featurePosition - ray.origin

            let crossProduct = simd_cross(originToFeature, ray.direction)
            let featureDistanceFromResult = simd_length(crossProduct)

            let hitTestResult = ray.origin + (ray.direction * simd_dot(ray.direction, originToFeature))
            let hitTestResultDistance = simd_length(hitTestResult - ray.origin)

            if hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance {
                // Skip this feature - it is too close or too far away.
                return nil
            }

            let originToFeatureNormalized = simd_normalize(originToFeature)
            let angleBetweenRayAndFeature = acos(simd_dot(ray.direction, originToFeatureNormalized))

            if angleBetweenRayAndFeature > maxAngle {
                // Skip this feature - is is outside of the hit test cone.
                return nil
            }

            // All tests passed: Add the hit against this feature to the results.
            return FeatureHitTestResult(position: hitTestResult,
                                        distanceToRayOrigin: hitTestResultDistance,
                                        featureHit: featurePosition,
                                        featureDistanceToHitResult: featureDistanceFromResult)
        }

        // Sort the results by feature distance to the ray origin.
        let sortedResults = results.sorted { $0.distanceToRayOrigin < $1.distanceToRayOrigin }

        let remainingResults = maxResults > 0 ? Array(sortedResults.prefix(maxResults)) : sortedResults

        return remainingResults
    }

    func hitTestWithFeatures(_ point: CGPoint) -> [FeatureHitTestResult] {
        guard let features = self.arSession.currentFrame?.rawFeaturePoints,
            let ray = hitTestRayFromScreenPosition(point) else {
                return []
        }

        let possibleResults = features.points.map { featurePosition in
            return FeatureHitTestResult(featurePoint: featurePosition, ray: ray)
        }
        let closestResult = possibleResults.min(by: { $0.featureDistanceToHitResult < $1.featureDistanceToHitResult })!
        return [closestResult]
    }

}

extension ARViewController.FeatureHitTestResult {
    init(featurePoint: float3, ray: ARViewController.HitTestRay) {
        self.featureHit = featurePoint

        let originToFeature = featurePoint - ray.origin
        self.position = ray.origin + (ray.direction * simd_dot(ray.direction, originToFeature))
        self.distanceToRayOrigin = simd_length(self.position - ray.origin)
        self.featureDistanceToHitResult = simd_length(simd_cross(originToFeature, ray.direction))
    }
}

