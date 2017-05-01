//
//  Characteristic.swift
//  BLEManager
//
//  Created by Bryce Jacobs on 4/28/17.
//
//

import Foundation
import CoreBluetooth

public class Characteristic: BLEAttribute{
    public var _peripheral: Peripheral!
    public var _service: Service!
    public var _characteristic: CBCharacteristic!
    public var _descriptors: [Descriptor] = []
    
    init(peripheral: Peripheral, service: Service, characteristic: CBCharacteristic){
        super.init()
        
        _peripheral = peripheral
        _service = service
        _characteristic = characteristic
    }
    
    public var value: String? {
        guard let value = _characteristic.value else {
            return nil
        }
        
        return String(data: value, encoding: String.Encoding.utf8)
    }
    
}

extension Characteristic{
    public func toJSON() ->[String:AnyObject]{
        return [
            "peripheralUuid": _peripheral.identifier.uuidString as AnyObject,
            "uuid": _characteristic.uuid.uuidString as AnyObject,
            "id": attributeId as AnyObject
        ]
    }
    
    public func findDescriptor(uuidString: String) -> Descriptor?{
        guard let idx = _descriptors.index(where: {$0._descriptor.uuid.uuidString == uuidString}) else {
            return nil
        }
        
        return _descriptors[idx]
    }
}

extension Characteristic: Equatable { }

public func == (lhs: Characteristic, rhs: Characteristic) -> Bool{
    return lhs.attributeId == rhs.attributeId
}

public func == (lhs: Characteristic, rhs: CBCharacteristic) -> Bool{
    return lhs._characteristic.uuid == rhs.uuid
}

public func == (lhs: CBCharacteristic, rhs: Characteristic) -> Bool{
    return lhs.uuid == rhs._characteristic.uuid
}
