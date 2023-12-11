//
//  Extension.swift
//  TestBed
//
//  Created by Fabio Falco on 06/12/23.
//

import CoreGraphics
import SpriteKit

public func + (left: CGPoint, right: CGPoint) -> CGPoint {
   return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

public func += (left: inout CGPoint, right: CGPoint) {
   left = left + right
}
