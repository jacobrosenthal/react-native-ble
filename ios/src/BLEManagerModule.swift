import Foundation
import CoreBluetooth

@objc
public protocol BLEManagerDelegate {
    func dispatchEvent(_ name: String, value: AnyObject)
}

@objc
public class BLEManager : NSObject {
    public var delegate: BLEManagerDelegate?
    fileprivate let manager : CentralManager
    
    // MARK: Public interface
    public init(queue: DispatchQueue) {
        manager = CentralManager(queue: queue)
        super.init()
    }
    
    // MARK: CBCentralManagerDelegate
    open func state(_ resolve: Resolve, reject: Reject) {
        resolve(manager.state.asJSObject as AnyObject?)
    }
    
    // Mark: Scanning --------------------------------------------------------------------------------------------------
    open func startScanning(_ serviceUUIDs: [String]?, options:[String:AnyObject]?) {
        
        var scanOptions = [String:AnyObject]()
        if let options = options {
            if ((options["allowDuplicates"]?.isEqual(to: NSNumber(value: true as Bool))) ?? false) {
                scanOptions[CBCentralManagerScanOptionAllowDuplicatesKey] = true as AnyObject?
            }
        }
        
        var uuids: [CBUUID]? = nil
        if let serviceUUIDs = serviceUUIDs {
            scanOptions[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] = true as AnyObject?
            
            if let cbuuids = serviceUUIDs.toCBUUIDS() {
                uuids = cbuuids
            }
        }
        
        // Start scanning from the central manager.
        manager.centralManager.scanForPeripherals(uuids, scanOptions);
    }
    
    open func stopScanning() {
        manager.stopScanning();
    }
    
    // Mark: Connection management -------------------------------------------------------------------------------------
    open func connectToDevice(_ deviceIdentifier: String,
                              options:[String: AnyObject]?,
                              resolve: @escaping Resolve,
                              reject: @escaping Reject) {
        
        guard let deviceId = UUID(uuidString: deviceIdentifier) else {
            BleError.invalidUUID(deviceIdentifier)
            return
        }
        

    }
    
    
    open func cancelDeviceConnection(_ deviceIdentifier: String, resolve: @escaping Resolve, reject: @escaping Reject) {
        guard let deviceId = UUID(uuidString: deviceIdentifier) else {
            BleError.invalidUUID(deviceIdentifier).callReject(reject)
            return
        }
        
        if let device = connectedDevices[deviceId] {
            _ = device.cancelConnection()
                .subscribe(
                    onNext: nil,
                    onError: { error in
                        error.bleError.callReject(reject)
                },
                    onCompleted: {
                        resolve(device.asJSObject)
                },
                    onDisposed: { [weak self] in
                        self?.connectedDevices[deviceId] = nil
                    }
            );
        } else {
            connectingDevices.removeDisposable(deviceId)
            BleError.cancelled().callReject(reject)
        }
    }
    
    
    // Mark: Discovery -------------------------------------------------------------------------------------------------
    open func discoverAllServicesAndCharacteristicsForDevice(_ deviceIdentifier: String,
                                                             resolve: @escaping Resolve,
                                                             reject: @escaping Reject) {
        
        guard let deviceId = UUID(uuidString: deviceIdentifier) else {
            BleError.invalidUUID(deviceIdentifier).callReject(reject)
            return
        }
        
        guard let device = connectedDevices[deviceId] else {
            BleError.peripheralNotConnected(deviceIdentifier).callReject(reject)
            return
        }
        
    }
    
    // Mark: Service and characteristic getters ------------------------------------------------------------------------
    open func servicesForDevice(_ deviceIdentifier: String, resolve: Resolve, reject: Reject) {
        
        guard let deviceId = UUID(uuidString: deviceIdentifier) else {
            BleError.invalidUUID(deviceIdentifier).callReject(reject)
            return
        }
        
        guard let device = connectedDevices[deviceId] else {
            BleError.peripheralNotConnected(deviceIdentifier).callReject(reject)
            return
        }
        
        let services = device.services?.map { $0.asJSObject } ?? []
        resolve(services as AnyObject?)
    }
    
    open func characteristicsForDevice(_ deviceIdentifier: String,
                                       serviceUUID: String,
                                       resolve: Resolve,
                                       reject: Reject) {
        
        guard let deviceId = UUID(uuidString: deviceIdentifier),
            let serviceId = serviceUUID.toCBUUID() else {
                BleError.invalidUUIDs([deviceIdentifier, serviceUUID]).callReject(reject)
                return
        }
        
        guard let device = connectedDevices[deviceId] else {
            BleError.peripheralNotConnected(deviceIdentifier).callReject(reject)
            return
        }
        
        let services = device.services?.filter { serviceId == $0.uuid } ?? []
        let characteristics = services
            .flatMap { $0.characteristics ?? [] }
            .map { $0.asJSObject }
        
        resolve(characteristics as AnyObject)
    }
    
    // Mark: Reading ---------------------------------------------------------------------------------------------------
    open func readCharacteristicForDevice(_ deviceIdentifier: String,
                                          serviceUUID: String,
                                          characteristicUUID: String,
                                          transactionId: String,
                                          resolve: @escaping Resolve,
                                          reject: @escaping Reject) {
        guard let deviceId = UUID(uuidString: deviceIdentifier),
            let serviceId = serviceUUID.toCBUUID(),
            let characteristicId = characteristicUUID.toCBUUID() else {
                BleError.invalidUUIDs([deviceIdentifier, serviceUUID, characteristicUUID]).callReject(reject)
                return
        }
        

    }
    
    // MARK: Writing ---------------------------------------------------------------------------------------------------
    open func writeCharacteristicForDevice(  _ deviceIdentifier: String,
                                             serviceUUID: String,
                                             characteristicUUID: String,
                                             valueBase64: String,
                                             response: Bool,
                                             transactionId: String) {
        
        guard let deviceId = UUID(uuidString: deviceIdentifier),
            let serviceId = serviceUUID.toCBUUID(),
            let characteristicId = characteristicUUID.toCBUUID() else {
                BleError.invalidUUIDs([deviceIdentifier, serviceUUID, characteristicUUID]).callReject(reject)
                return
        }
        
        guard let value = Data(base64Encoded: valueBase64, options: .ignoreUnknownCharacters) else {
            return BleError.invalidWriteDataForCharacteristic(characteristicUUID, data: valueBase64).callReject(reject)
        }
        
    }
    
    
    // MARK: Monitoring ------------------------------------------------------------------------------------------------
    open func monitorCharacteristicForDevice(  _ deviceIdentifier: String,
                                               serviceUUID: String,
                                               characteristicUUID: String,
                                               transactionId: String,
                                               resolve: @escaping Resolve,
                                               reject: @escaping Reject) {
        
        guard let deviceId = UUID(uuidString: deviceIdentifier),
            let serviceId = serviceUUID.toCBUUID(),
            let characteristicId = characteristicUUID.toCBUUID() else {
                BleError.invalidUUIDs([deviceIdentifier, serviceUUID, characteristicUUID]).callReject(reject)
                return
        }
        
    }
    
    
    // MARK: Private interface -----------------------------------------------------------------------------------------
    fileprivate func dispatchEvent(_ event: String, value: Any) {
        delegate?.dispatchEvent(event, value: value as AnyObject)
    }
}
