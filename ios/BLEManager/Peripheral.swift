//
//  Peripheral.swift
//  BLEManager
//
//  Created by Bryce Jacobs on 4/18/17.
//
//

import Foundation
import CoreBluetooth

public class Peripheral: NSObject, CBPeripheralDelegate{
    public var _peripheral: CBPeripheral!
    
    init(peripheral: CBPeripheral){
        super.init()
        
        _peripheral = peripheral
        _peripheral.delegate = self
    }
    
    public var identifier: UUID {
        return _peripheral.identifier
    }
    
    public var name: String? {
        return _peripheral.name
    }
    
    public var services: [Service]? {
        return _peripheral.services?.map {
            Service(peripheral: self, service: $0)
        }
    }
    
    @available(iOS 9.0, *)
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        return _peripheral.maximumWriteValueLength(for: type)
    }
    

}

extension Peripheral{
    func toJSON(advertisementData: [String: Any], rssi: NSNumber) -> [String:AnyObject]{
        var peripheralData: [String:AnyObject] = [
            "uuid": _peripheral.identifier.uuidString as AnyObject,
            "address": "unknown" as AnyObject,
            "addressType": "unknown" as AnyObject,
            "connectable": " " as AnyObject,
            "advertisement": " " as AnyObject,
            "rssi": rssi as AnyObject,
        ]
        
        var advertisementData = [String:AnyObject]()
        if let advServiceData: [CBUUID:NSData] = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID : NSData] {
            var data = [String:String]()
            
            for (key, value) in advServiceData {
                data[key.uuidString] = String(data: value as Data, encoding: String.Encoding.utf8)
            }
            
            advertisementData["serviceData"] = data as AnyObject
        }
        
        if let manufacturerData: NSData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData{
            advertisementData["manufacturerData"] = String(data: manufacturerData as Data, encoding: String.Encoding.utf8) as AnyObject
        }
        
        if let advServiceUUIDs: [CBUUID] = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]{
            var data = [String]()
            
            for uuid in advServiceUUIDs{
                data.append(uuid.uuidString)
            }
            
            // Add the overflows onto the service uuids
            if let advOverflowUUIDs: [CBUUID] = advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]{
                
                for overflow in advOverflowUUIDs{
                    data.append(overflow.uuidString)
                }
            }
            
            advertisementData["serviceUuids"] = data as AnyObject
        }
        
        if let advSolicitedUUIDs: [CBUUID] = advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]{
            var data = [String]()
            
            for uuid in advSolicitedUUIDs{
                data.append(uuid.uuidString)
            }
            
            advertisementData["serviceSolicitationUuid"] = data as AnyObject
        }
        
        
        if let txPowerLevel: NSNumber = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber{
            advertisementData["txPowerLevel"] = txPowerLevel as AnyObject
        }
        
        if let localName: String = advertisementData[CBAdvertisementDataLocalNameKey] as? String{
            advertisementData["localName"] = localName as AnyObject
        }
        
        if let connectable: NSNumber = advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber{
            peripheralData["connectable"] = connectable as AnyObject
        }
        
        peripheralData["advertisement"] = advertisementData as AnyObject
        
        return peripheralData
    }

}

//extension Peripheral: Equatable { }

public func == (lhs: Peripheral, rhs: Peripheral) -> Bool{
    return lhs.identifier == rhs.identifier
}

public func == (lhs: Peripheral, rhs: CBPeripheral) -> Bool{
    return lhs._peripheral.identifier == rhs.identifier
}

public func == (lhs: CBPeripheral, rhs: Peripheral) -> Bool{
    return lhs.identifier == rhs._peripheral.identifier
}
