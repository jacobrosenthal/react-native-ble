//
//  BTDiscovery.swift
//  lxapp
//
//  Created by Bryce Jacobs on 8/19/15.
//  Copyright (c) 2015 Computrols. All rights reserved.
//

import Foundation
import CoreBluetooth

class CentralManager: NSObject, CBCentralManagerDelegate {
    fileprivate var _peripherals: [Peripheral] = []
    fileprivate var _manager: CBCentralManager!
    fileprivate var _dispatch: BLEManagerDelegate!
    
    public init(withQueue queue: DispatchQueue, dispatchDelegate: BLEManagerDelegate) {
        super.init()
        _dispatch = dispatchDelegate
        _manager = CBCentralManager(delegate: self, queue: queue)
    }
    
    // MARK: Discovery
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        if _peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            return
        }
        
        // Store the peripheral for later.
        let periph = Peripheral(peripheral: peripheral, delegate: _dispatch)
        _peripherals.append(periph)
        
        
        dispatchEvent(BLEEvent.DISCOVER.description, value: periph.toJSON(advertisementData: advertisementData, rssi: RSSI))
    }
    
    // MARK: Connections
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        dispatchEvent(BLEEvent.CONNECT.description, value: [ "peripheralUuid": peripheral.identifier.uuidString as AnyObject])
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
        dispatchEvent(BLEEvent.DISCONNECT.description, value: [ "peripheralUuid": peripheral.identifier.uuidString as AnyObject])
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?){
        let payload = [
            "peripheralUuid": peripheral.identifier.uuidString as AnyObject,
            "error": error?.localizedDescription as AnyObject
        ]
        
        dispatchEvent(BLEEvent.CONNECT.description, value: payload)
    }
    
    // MARK: State
    public func centralManagerDidUpdateState(_ central: CBCentralManager){
        var payload = ["state": " "]
        if #available(iOS 10.0, *) {
            switch (central.state) {
            case CBManagerState.poweredOff:
                payload["state"] = "poweredOff"
                break
            case CBManagerState.unauthorized:
                payload["state"] = "unauthorized"
                break
            case CBManagerState.unknown:
                payload["state"] = "unknown"
                break
            case CBManagerState.poweredOn:
                payload["state"] = "poweredOn"
                break
            case CBManagerState.resetting:
                payload["state"] = "resetting"
                break
            case CBManagerState.unsupported:
                payload["state"] = "unsupported"
                break
            }
        } else{
            let state = CBCentralManagerState(rawValue: central.state.rawValue)
            switch (state!){
            case CBCentralManagerState.poweredOff:
                payload["state"] = "poweredOff"
                break
            case CBCentralManagerState.unauthorized:
                payload["state"] = "unauthorized"
                break
            case CBCentralManagerState.unknown:
                payload["state"] = "unknown"
                break
            case CBCentralManagerState.poweredOn:
                payload["state"] = "poweredOn"
                break
            case CBCentralManagerState.resetting:
                payload["state"] = "resetting"
                break
            case CBCentralManagerState.unsupported:
                payload["state"] = "unsupported"
                break
            }
        }
        print(payload)
        dispatchEvent(BLEEvent.STATE_CHANGE.description, value: payload)
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]){
        
    }
    
    // MARK: Private interface -----------------------------------------------------------------------------------------
    fileprivate func dispatchEvent(_ event: String, value: Any) {
        _dispatch.dispatchEvent(event, value: value as AnyObject)
    }
}


extension CentralManager {
    func clearAll(){

    }
    
    // MARK: Connection Helper methods
    func connectPeripheral(peripheralUUID: UUID){
        guard let idx = _peripherals.index(where: { $0.identifier == peripheralUUID }) else {
            return
        }
        
        // Connect the central manager
        _manager.connect(_peripherals[idx]._peripheral)
    }
    
    func disconnectPeripheral(peripheralUUID: CBUUID){
//        if let periph = peripheral {
//            self.centralManager.cancelPeripheralConnection(periph)
//        }
    }
    
    // MARK: Discovery Helper methods
    func scanForPeripherals(serviceUUIDs: [CBUUID]?, scanOptions: [String:AnyObject]) {
        _manager.scanForPeripherals(withServices: serviceUUIDs, options: scanOptions)
    }
    
    func stopScanForPeripherals(){
        _manager.stopScan()
    }
}

