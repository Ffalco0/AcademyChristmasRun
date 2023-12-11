//
//  Types.swift
//  TestBed
//
//  Created by Fabio Falco on 08/12/23.
//

import Foundation

struct PhysicsCategory{
    static let Player:      UInt32 = 0b1
    static let Block:       UInt32 = 0b10
    static let Obstacle:    UInt32 = 0b100
    static let Ground:      UInt32 = 0b1000
}
