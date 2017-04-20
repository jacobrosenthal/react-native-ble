//
//  BTDiscovery.swift
//  lxapp
//
//  Created by Bryce Jacobs on 8/19/15.
//  Copyright (c) 2015 Computrols. All rights reserved.
//

import Foundation
import CoreBluetooth

class BTDiscovery: NSObject, CBCentralManagerDelegate {
    private var peripherals: [CBPeripheral?] = []
    private var services: [BTService?] = []
    private var centralManager: CBCentralManager!
    
    override init(withQueue queue: DispatchQueue) {
        super.init()

        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    // MARK: CBCentralManagerDelegate
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        
        if let data = advertisementData[CBAdvertisementDataServiceUUIDsKey] {
            
            let solicitedUuids: [CBUUID] = data as! [CBUUID]
            for uuid in solicitedUuids {

            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
        if let pending = self.pending {
            // Check to see if this service already exists.
            if let service = services[pending]{
                if service != nil {
                    return
                }
            }
            
            // Create new service class, which hosts all peripheral information
            let service = BTService(initWithPeripheral: peripheral)
            services[pending] = service
            states[pending] = DeviceState.Connected
            
            // Start a query on the remote peripheral's services
            service.startDiscoveringServices()
            
            self.peripherals[BLEPendingIdentifier] = nil
            self.pending = nil
            
        } else {
            print("Central Manager Connect Delegate - No Pending Device")
        }
        
        self.startScanning()
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        for (key, periph) in peripherals {
            if periph == peripheral && error != nil{
                
                // Some error occurred, set the state so
                states[key] = DeviceState.Timeout
            }
        }
        
        // Start scanning for new devices
        self.startScanning()
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch (central.state) {
        case CBCentralManagerState.PoweredOff: break
            
        case CBCentralManagerState.Unauthorized:
            // Indicate to user that the iOS device does not support BLE.
            break
            
        case CBCentralManagerState.Unknown:
            // Wait for another event
            break
            
        case CBCentralManagerState.PoweredOn:
            self.startScanning()
            break
            
        case CBCentralManagerState.Resetting:
            break
        case CBCentralManagerState.Unsupported:
            break
        }
    }
    
    // MARK: NSNotification Callbacks
    func onConnectionRequest(name: String, key: String, rssi: NSNumber){
        NSNotificationCenter.defaultCenter().postNotificationName(BLEConnectionRequestNotification, object: self, userInfo: ["deviceName": name, "device": key, "RSSI": String(rssi)])
    }
    
}

// Have all local instantiated class methods in extension, to seperate from delegate / callback methods.
extension BTDiscovery {
    func clearAll(){
        disconnectFDPeripheral()
        disconnectWCPeripheral()
        
        peripherals[BLEFDIdentifier] = nil
        peripherals[BLEWCIdentifier] = nil
        peripherals[BLEPendingIdentifier] = nil
        
        services[BLEFDIdentifier] = nil
        services[BLEWCIdentifier] = nil
        
        states[BLEFDIdentifier] = nil
        states[BLEWCIdentifier] = nil
    }
    
    // Called whenever user accepts connection to peripheral, through prompting.
    func connectPeripheral(){
        
        // Make sure we have a pending device queued.
        if let pending = pending {
            
            // If there is already a device connected in this role, delete and replace. THIS DEVICE MAY BE DIFFERENT THAN CURRENT PENDING
            if let peripheral = peripherals[pending]! {
                disconnectPeripheral(peripheral, key: pending)
                
                // Only clear service, state, if the peripheral isn't the same one.
                services[pending] = nil
                states[pending] = nil
            }
            
            if let pendingPeripheral = pendingPeripheral {
                peripherals[pending] = pendingPeripheral
                
                // Disconnect, so other apps will lose connection and cache clears before connect.
                centralManager.cancelPeripheralConnection(pendingPeripheral)
                centralManager.connectPeripheral(pendingPeripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true]);
            }
        } else {
            print("Connect Peripheral - No Pending Device")
        }
    }
    
    var controllerPeripheral: CBPeripheral? {
        return peripherals[BLEWCIdentifier]!
    }
    
    // Return the Controller information for field devices
    var controller: WirelessController? {
        if let service = controllerService {
            return service.controller
        }
        
        return nil
    }
    
    
    // Mark - Private Instantiated Methods
    private func disconnectPeripheral(peripheral: CBPeripheral?, key: String){
        if let periph = peripheral {
            centralManager.cancelPeripheralConnection(periph)
        }
    }
    
    private var pendingPeripheral: CBPeripheral? {
        return peripherals[BLEPendingIdentifier]!
    }
    
    private func startScanning() {
        centralManager.scanForPeripheralsWithServices([WirelessControllerUUID, FieldDeviceUUID], options: nil)
    }
}

