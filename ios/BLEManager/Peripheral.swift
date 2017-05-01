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
    fileprivate var _delegate: BLEManagerDelegate!
    public var _services: [Service] = []
    
    init(peripheral: CBPeripheral, delegate: BLEManagerDelegate){
        super.init()
        _delegate = delegate
        _peripheral = peripheral
        _peripheral.delegate = self
    }
    
    public var identifier: UUID {
        return _peripheral.identifier
    }
    
    public var name: String? {
        return _peripheral.name
    }
    
    @available(iOS 9.0, *)
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        return _peripheral.maximumWriteValueLength(for: type)
    }
    
    // MARK: Discovery
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        guard let services: [CBService] = peripheral.services else {
            return
        }
        
        var uuids: [Int: String] = [:]
        for service in services {
            
            var _service: Service
            if let idx = _services.index(where: { $0._service.uuid == service.uuid }){
                _service = _services[idx]
            } else {
                _service = Service(peripheral: self, service: service)
                _services.append(_service)
            }
            
            uuids[_service.attributeId] = service.uuid.uuidString
        }
        
        let payload = [
            "peripheralUuid": _peripheral.identifier.uuidString as Any,
            "uuids": uuids as Any
        ]
        
        // Noble: send JS services discover event
        dispatchEvent(BLEEvent.SERVICES_DISCOVER.description, value: payload)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?){
        guard let includedServices: [CBService] = service.includedServices else {
            return
        }
        
        guard let _serviceIdx = _services.index(where: { $0._service.uuid == service.uuid }) else {
            return
        }
        let _service = _services[_serviceIdx]
        
        var uuids: [Int: String] = [:]
        for service in includedServices {
            
            var _includedService: Service
            if let idx = _service._includedServices.index(where: { $0._service.uuid == service.uuid }){
                _includedService = _service._includedServices[idx]
            } else {
                _includedService = Service(peripheral: self, service: service)
                _service._includedServices.append(_includedService)
            }
            
            uuids[_service.attributeId] = service.uuid.uuidString
        }
        
        let payload = [
            "peripheralUuid": _peripheral.identifier.uuidString as Any,
            "serviceUuid": _service._service.uuid.uuidString as Any,
            "uuids": uuids as Any
        ]
        
        // Noble: send JS included services discover
        dispatchEvent(BLEEvent.INCLUDED_SERVICES_DISCOVER.description, value: payload)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        guard let characteristics: [CBCharacteristic] = service.characteristics else {
            return
        }
        
        guard let _serviceIdx = _services.index(where: { $0._service.uuid == service.uuid }) else {
            return
        }
        let _service = _services[_serviceIdx]
        
        var uuids: [Int: String] = [:]
        for characteristic in characteristics {
            
            var _characteristic: Characteristic
            if let idx = _service._characteristics.index(where: { $0._characteristic.uuid == characteristic.uuid }){
                _characteristic = _service._characteristics[idx]
            } else {
                _characteristic = Characteristic(peripheral: self, service: _service, characteristic: characteristic)
                _service._characteristics.append(_characteristic)
            }
            
            uuids[_characteristic.attributeId] = characteristic.uuid.uuidString
        }
        
        let payload = [
            "peripheralUuid": _peripheral.identifier.uuidString as Any,
            "serviceUuid": _service._service.uuid.uuidString as Any,
            "uuids": uuids as Any
        ]
        
        // Noble: send JS included services discover
        dispatchEvent(BLEEvent.CHARACTERISTICS_DISCOVER.description, value: payload)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?){
        guard let descriptors: [CBDescriptor] = characteristic.descriptors else {
            return
        }
        
        guard let _serviceIdx = _services.index(where: { $0._service.uuid == characteristic.service.uuid }) else {
            return
        }
        let _service = _services[_serviceIdx]
        
        guard let _characteristicIdx = _service._characteristics.index(where: { $0._characteristic.uuid == characteristic.uuid }) else {
            return
        }
        let _characteristic = _service._characteristics[_characteristicIdx]
        
        var uuids: [Int: String] = [:]
        for descriptor in descriptors {
            
            var _descriptor: Descriptor
            if let idx = _characteristic._descriptors.index(where: { $0._descriptor.uuid == descriptor.uuid }){
                _descriptor = _characteristic._descriptors[idx]
            } else {
                _descriptor = Descriptor(peripheral: self, service: _service, characteristic: _characteristic, descriptor: descriptor)
                _characteristic._descriptors.append(_descriptor)
            }
            
            uuids[_descriptor.attributeId] = descriptor.uuid.uuidString
        }
        
        let payload = [
            "peripheralUuid": _peripheral.identifier.uuidString as Any,
            "serviceUuid": _service._service.uuid.uuidString as Any,
            "characteristicUuid": _characteristic._characteristic.uuid.uuidString as Any,
            "uuids": uuids as Any
        ]
        
        // Noble: send JS included services discover
        dispatchEvent(BLEEvent.DESCRIPTORS_DISCOVER.description, value: payload)
    }
    
    // MARK: Read / Write
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        guard let serviceIdx = _services.index(where: { $0 == characteristic.service }) else {
            return
        }
        let _service = _services[serviceIdx]
        
        guard let characteristicIdx = _service._characteristics.index(where: { $0 == characteristic }) else {
            return
        }
        let _characteristic = _service._characteristics[characteristicIdx]
        
        let payload = [
            "peripheralUuid": _peripheral.identifier.uuidString as Any,
            "serviceUuid": [_service.attributeId: _service._service.uuid.uuidString] as Any,
            "characteristicUuid": [_characteristic.attributeId: _characteristic._characteristic.uuid.uuidString] as Any,
            "data": _characteristic.value as Any,
            "isNotifying": _characteristic._characteristic.isNotifying as Any,
        ]
        dispatchEvent(BLEEvent.READ.description, value: payload)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?){
        guard let serviceIdx = _services.index(where: { $0 == descriptor.characteristic.service }) else {
            return
        }
        let _service = _services[serviceIdx]
        
        guard let characteristicIdx = _service._characteristics.index(where: { $0 == descriptor.characteristic }) else {
            return
        }
        let _characteristic = _service._characteristics[characteristicIdx]
        
        guard let descriptorIdx = _characteristic._descriptors.index(where: { $0 == descriptor }) else {
            return
        }
        let _descriptor = _characteristic._descriptors[descriptorIdx]
        
        
        let payload = [
            "peripheralUuid": _peripheral.identifier.uuidString as Any,
            "serviceUuid": [_service.attributeId: _service._service.uuid.uuidString] as Any,
            "characteristicUuid": [_characteristic.attributeId: _characteristic._characteristic.uuid.uuidString] as Any,
            "descriptorUuid": [_descriptor.attributeId: _descriptor._descriptor.uuid.uuidString] as Any,
            "data": _characteristic.value as Any,
        ]
        dispatchEvent(BLEEvent.VALUE_READ.description, value: payload)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        if error != nil {
            return
        }
        
        guard let serviceIdx = _services.index(where: { $0 == characteristic.service }) else {
            return
        }
        let _service = _services[serviceIdx]
        
        guard let characteristicIdx = _service._characteristics.index(where: { $0 == characteristic }) else {
            return
        }
        let _characteristic = _service._characteristics[characteristicIdx]
        
        let payload = [
            "peripheralUuid": _peripheral.identifier.uuidString as Any,
            "serviceUuid": [_service.attributeId: _service._service.uuid.uuidString] as Any,
            "characteristicUuid": [_characteristic.attributeId: _characteristic._characteristic.uuid.uuidString] as Any
        ]
        dispatchEvent(BLEEvent.WRITE.description, value: payload)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?){
        if error != nil {
            return
        }
        
        guard let serviceIdx = _services.index(where: { $0 == descriptor.characteristic.service }) else {
            return
        }
        let _service = _services[serviceIdx]
        
        guard let characteristicIdx = _service._characteristics.index(where: { $0 == descriptor.characteristic }) else {
            return
        }
        let _characteristic = _service._characteristics[characteristicIdx]
        
        guard let descriptorIdx = _characteristic._descriptors.index(where: { $0 == descriptor }) else {
            return
        }
        let _descriptor = _characteristic._descriptors[descriptorIdx]
        
        let payload = [
            "peripheralUuid": _peripheral.identifier.uuidString as Any,
            "serviceUuid": [_service.attributeId: _service._service.uuid.uuidString] as Any,
            "characteristicUuid": [_characteristic.attributeId: _characteristic._characteristic.uuid.uuidString] as Any,
            "descriptorUuid": [_descriptor.attributeId: _descriptor._descriptor.uuid.uuidString] as Any
        ]
        dispatchEvent(BLEEvent.VALUE_WRITE.description, value: payload)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic,error: Error?){
        if error != nil {
            return
        }
        
        guard let serviceIdx = _services.index(where: { $0 == characteristic.service }) else {
            return
        }
        let _service = _services[serviceIdx]
        
        guard let characteristicIdx = _service._characteristics.index(where: { $0 == characteristic }) else {
            return
        }
        let _characteristic = _service._characteristics[characteristicIdx]
        
        let payload = [
            "peripheralUuid": _peripheral.identifier.uuidString as Any,
            "serviceUuid": [_service.attributeId: _service._service.uuid.uuidString] as Any,
            "characteristicUuid": [_characteristic.attributeId: _characteristic._characteristic.uuid.uuidString] as Any,
            "state": characteristic.isNotifying as Any
        ]
        dispatchEvent(BLEEvent.NOTIFY.description, value: payload)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?){
        if error != nil {
            return
        }
        
        let payload = [
            "peripheralUuid": _peripheral.identifier.uuidString as Any,
            "rssi": RSSI as Any
        ]
        dispatchEvent(BLEEvent.RSSI_UPDATE, value: payload)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]){
        
    }
    
    // MARK: Private interface -----------------------------------------------------------------------------------------
    fileprivate func dispatchEvent(_ event: String, value: Any) {
        _delegate.dispatchEvent(event, value: value as AnyObject)
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
    
    func findService(uuidString: String) -> Service?{
        guard let serviceIdx = _services.index(where: { $0._service.uuid.uuidString == uuidString }) else {
            return nil
        }
        
        return _services[serviceIdx]
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
