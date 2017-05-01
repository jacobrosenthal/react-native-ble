//
//  BLEAttribute.swift
//  BLEManager
//
//  Created by Bryce Jacobs on 4/18/17.
//
//

import Foundation

public class BLEAttribute{
    public var attributeId: Int;
    
    init(){
        attributeId = Int(arc4random_uniform(UInt32(65535)) + 1)
    }
}
