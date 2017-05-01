//
//  Descriptor.swift
//  BLEManager
//
//  Created by Bryce Jacobs on 4/28/17.
//
//

import Foundation
import CoreBluetooth

public class Descriptor: BLEAttribute{
    public var _peripheral: Peripheral!
    public var _service: Service!
    public var _characteristic: Characteristic!
    public var _descriptor: CBDescriptor!
    
    init(peripheral: Peripheral, service: Service!, characteristic: Characteristic, descriptor: CBDescriptor){
        super.init()
        
        _peripheral = peripheral
        _service = service
        _characteristic = characteristic
        _descriptor = descriptor
    }
    
    public var value: String? {
        guard let value = _descriptor.value else {
            return nil
        }
        
        return String(data: (value as! Data), encoding: String.Encoding.utf8)
    }
}

extension Descriptor{
    public func toJSON() ->[String:AnyObject]{
        return [
            "peripheralUuid": _peripheral.identifier.uuidString as AnyObject,
            "serviceUuid": _service._service.uuid.uuidString as AnyObject,
            "characteristicUuid": _characteristic._characteristic.uuid.uuidString as AnyObject,
            "uuid": _descriptor.uuid.uuidString as AnyObject,
            "id": attributeId as AnyObject
        ]
    }
}

extension Descriptor: Equatable { }

public func == (lhs: Descriptor, rhs: Descriptor) -> Bool{
    return lhs.attributeId == rhs.attributeId
}

public func == (lhs: Descriptor, rhs: CBDescriptor) -> Bool{
    return lhs._descriptor.uuid == rhs.uuid
}

public func == (lhs: CBDescriptor, rhs: Descriptor) -> Bool{
    return lhs.uuid == rhs._descriptor.uuid
}
