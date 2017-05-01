//
//  Service.swift
//  BLEManager
//
//  Created by Bryce Jacobs on 4/18/17.
//
//

import Foundation
import CoreBluetooth

public class Service: BLEAttribute{
    public var _peripheral: Peripheral!
    public var _service: CBService!
    public var _characteristics: [Characteristic] = []
    public var _includedServices: [Service] = []

    init(peripheral: Peripheral, service: CBService){
        super.init()
        
        _peripheral = peripheral
        _service = service
    }
}

extension Service{
    public func toJSON() ->[String:AnyObject]{
        return [
            "peripheralUuid": _peripheral.identifier.uuidString as AnyObject,
            "uuid": _service.uuid.uuidString as AnyObject,
            "id": attributeId as AnyObject
        ]
    }
    
    public func findCharacteristic(uuidString: String) -> Characteristic?{
        guard let idx = _characteristics.index(where: {$0._characteristic.uuid.uuidString == uuidString}) else {
            return nil
        }
        
        return _characteristics[idx]
    }
}

extension Service: Equatable { }

public func == (lhs: Service, rhs: Service) -> Bool{
    return lhs.attributeId == rhs.attributeId
}

public func == (lhs: Service, rhs: CBService) -> Bool{
    return lhs._service.uuid == rhs.uuid
}

public func == (lhs: CBService, rhs: Service) -> Bool{
    return lhs.uuid == rhs._service.uuid
}
