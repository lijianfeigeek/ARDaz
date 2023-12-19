//
//  AnimatingModel.swift
//  ARDaz
//
//  Created by Jeffery on 18/12/23.
//

import RealityKit

struct AnimatingModel {
    let entity: Entity
    let animationParam: ARSceneSpec.AnimationParam
    
    //    func update(at time: Double) {
    //        let (position, rotation) = calcPosition(at: time)
    //        entity.position = position
    //        entity.transform.rotation = rotation
    //    }
    //
    //    private func calcPosition(at time: Double) -> (SIMD3<Float>, simd_quatf) {
    //        let angle = animationParam.angularVelocity * Float(time)
    //        let position = SIMD3<Float>(animationParam.radius * cosf(angle),
    //                               0,
    //                               animationParam.radius * sinf(angle))
    //                  + animationParam.center
    //        return (position, simd_quatf(angle: -angle + (animationParam.angularVelocity < 0 ? Float.pi : 0),
    //                                     axis: SIMD3<Float>(0, 1, 0)))
    //    }
    
    func update(at time: Double) {
        let rotation = calcRotation(at: time)
        entity.transform.rotation = rotation
    }
    
    private func calcRotation(at time: Double) -> simd_quatf {
        let angle = animationParam.angularVelocity * Float(time)
        return simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
    }
}
