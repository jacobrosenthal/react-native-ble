import Foundation
import CoreBluetooth

@objc
public protocol BLEManagerDelegate {
    func dispatchEvent(_ name: String, value: AnyObject)
}

@objc
public class BLEManager : NSObject, CBCentralManagerDelegate {
    public var delegate: BLEManagerDelegate?
    fileprivate var _manager : CBCentralManager!
    fileprivate var _peripherals: [Peripheral] = []
    
    // MARK: Public interface
    public init(queue: DispatchQueue = .main) {
        super.init()
        
        _manager = CBCentralManager(delegate: self, queue: queue)
    }
    
    open func destroy(){
        
    }
    
    // MARK: Discovery
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        if _peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            return
        }
        
        // Store the peripheral for later.
        let periph = Peripheral(peripheral: peripheral, delegate: delegate!)
        _peripherals.append(periph)
        
        // Noble: send JS discovery event
        dispatchEvent(BLEEvent.DISCOVER.description, value: periph.toJSON(advertisementData: advertisementData, rssi: RSSI))
    }
    
    // MARK: Connections
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        let event = ["peripheralUuid": peripheral.identifier.uuidString]
        
        // Noble: send JS connect event
        dispatchEvent(BLEEvent.CONNECT.description, value: event)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
        let event = ["peripheralUuid": peripheral.identifier.uuidString]
        
        // Noble: send JS disconnect event
        dispatchEvent(BLEEvent.DISCONNECT.description, value: event)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?){
        let payload = [
            "peripheralUuid": peripheral.identifier.uuidString,
            "error": error?.localizedDescription
        ]
        
        // Noble: send JS error connect event
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
        
        // Noble: send JS state event
        dispatchEvent(BLEEvent.STATE_CHANGE.description, value: payload)
    }
    
    // MARK: Private interface -----------------------------------------------------------------------------------------
    fileprivate func dispatchEvent(_ event: String, value: Any) {
        delegate?.dispatchEvent(event, value: value as AnyObject)
    }
}

// Module stubs
extension BLEManager{
    // Mark: Connections
    open func connect(_ deviceIdentifier: String, options: [String:AnyObject]?) {
        guard let peripheral = findPeripheral(deviceIdentifier: deviceIdentifier) else {
            return
        }
        
        // Connect to peripheral indicated by identifier
        _manager.connect(peripheral._peripheral, options: options)
    }
    
    open func disconnect(_ deviceIdentifier: String){
        guard let peripheral = findPeripheral(deviceIdentifier: deviceIdentifier) else {
            return
        }
        
        // Disconnect from peripheral indicated by identifier
        _manager.cancelPeripheralConnection(peripheral._peripheral)
    }
    
    // Mark: Scanning --------------------------------------------------------------------------------------------------
    open func startScanning(_ serviceUUIDs: [String]?, options:[String:AnyObject]?) {
        
        var scanOptions = [String:Bool]()
        if let options = options {
            if ((options["allowDuplicates"]?.isEqual(to: NSNumber(value: true as Bool))) ?? false) {
                scanOptions[CBCentralManagerScanOptionAllowDuplicatesKey] = true
            }
        }
        
        var uuids: [CBUUID] = []
        if let serviceUUIDs = serviceUUIDs {
            for uuid in serviceUUIDs {
                uuids.append(CBUUID(string: uuid))
            }
            
        }
        
        // Start scanning from the central manager.
        _manager.scanForPeripherals(withServices:uuids, options: scanOptions);
    }
    
    open func stopScanning() {
        _manager.stopScan()
    }
    
    // Mark: Discovery
    open func discoverServices(_ deviceIdentifier: String, serviceUUIDs: [String]?) {
        guard let peripheral = findPeripheral(deviceIdentifier: deviceIdentifier) else {
            return
        }
        
        var uuids: [CBUUID]?
        if let scanServices = serviceUUIDs{
            uuids = scanServices.map { CBUUID(string: $0) }
        }
        
        // Initiate the discovery
        peripheral._peripheral.discoverServices(uuids)
    }
    
    open func discoverIncludedServices(_ deviceIdentifier: String, serviceUUID: String, serviceUUIDs: [String]?) {
        guard let peripheral = findPeripheral(deviceIdentifier: deviceIdentifier) else {
            return
        }
        
        // Index of the service that we're performing discovery on.
        guard let service = peripheral.findService(uuidString: serviceUUID) else {
            return
        }
        
        var uuids: [CBUUID]?
        if let scanServices = serviceUUIDs {
            uuids = scanServices.map { CBUUID(string: $0) }
        }
        
        // Initiate a discovery for the service's included services
        peripheral._peripheral.discoverIncludedServices(uuids, for: service._service)
    }
    
    open func discoverCharacteristics(_ deviceIdentifier: String, serviceUUID: String, characteristicUUIDs: [String]?) {
        guard let peripheral = findPeripheral(deviceIdentifier: deviceIdentifier) else {
            return
        }
        
        guard let service = peripheral.findService(uuidString: serviceUUID) else {
            return
        }
        
        var uuids: [CBUUID]?
        if let scanCharacteristics = characteristicUUIDs {
            uuids = scanCharacteristics.map { CBUUID(string: $0) }
        }
        
        // Initiate a discovery for the service's included services
        peripheral._peripheral.discoverCharacteristics(uuids, for: service._service)
    }
    
    open func discoverDescriptors(_ deviceIdentifier: String, serviceUUID: String, characteristicUUID: String) {
        guard let peripheral = findPeripheral(deviceIdentifier: deviceIdentifier) else {
            return
        }
        
        guard let service = peripheral.findService(uuidString: serviceUUID) else {
            return
        }
        
        guard let characteristic = service.findCharacteristic(uuidString: characteristicUUID) else {
            return
        }
        
        // Initiate a discovery for the characteristic's descriptors
        peripheral._peripheral.discoverDescriptors(for: characteristic._characteristic)
    }
    
    // Mark: Read & Write
    open func read(_ deviceIdentifier: String, serviceUUID: String, characteristicUUID: String) {
        guard let peripheral = findPeripheral(deviceIdentifier: deviceIdentifier) else {
            return
        }
        
        guard let service = peripheral.findService(uuidString: serviceUUID) else {
            return
        }
        
        guard let characteristic = service.findCharacteristic(uuidString: characteristicUUID) else {
            return
        }
        
        // Initiate a discovery for the characteristic's descriptors
        peripheral._peripheral.readValue(for: characteristic._characteristic)
    }
    
    open func write(_ deviceIdentifier: String, serviceUUID: String, characteristicUUID: String, data: String, withoutResponse: Bool) {
        guard let peripheral = findPeripheral(deviceIdentifier: deviceIdentifier) else {
            return
        }
        
        guard let service = peripheral.findService(uuidString: serviceUUID) else {
            return
        }
        
        guard let characteristic = service.findCharacteristic(uuidString: characteristicUUID) else {
            return
        }
        
        // Cast to data type.
        guard let valueData = data.data(using: String.Encoding.utf8) else {
            return
        }
        
        // Write to the characteristic value
        peripheral._peripheral.writeValue(valueData, for: characteristic._characteristic, type: withoutResponse ? CBCharacteristicWriteType.withoutResponse : CBCharacteristicWriteType.withResponse)
    }
    
    open func notify(_ deviceIdentifier: String, serviceUUID: String, characteristicUUID: String, notify: Bool){
        guard let peripheral = findPeripheral(deviceIdentifier: deviceIdentifier) else {
            return
        }
        
        guard let service = peripheral.findService(uuidString: serviceUUID) else {
            return
        }
        
        guard let characteristic = service.findCharacteristic(uuidString: characteristicUUID) else {
            return
        }
        
        // Set the notify value for the given characteristic
        peripheral._peripheral.setNotifyValue(notify, for: characteristic._characteristic)
    }
    
    open func readValue(_ deviceIdentifier: String, serviceUUID: String, characteristicUUID: String, descriptorUUID: String) {
        guard let peripheral = findPeripheral(deviceIdentifier: deviceIdentifier) else {
            return
        }
        
        guard let service = peripheral.findService(uuidString: serviceUUID) else {
            return
        }
        
        guard let characteristic = service.findCharacteristic(uuidString: characteristicUUID) else {
            return
        }
        
        guard let descriptor = characteristic.findDescriptor(uuidString: descriptorUUID) else {
            return
        }
        
        // Initiate a read for the descriptor value.
        peripheral._peripheral.readValue(for: descriptor._descriptor)
    }
    
    open func writeValue(_ deviceIdentifier: String, serviceUUID: String, characteristicUUID: String, descriptorUUID: String, data: String) {
        guard let peripheral = findPeripheral(deviceIdentifier: deviceIdentifier) else {
            return
        }
        
        guard let service = peripheral.findService(uuidString: serviceUUID) else {
            return
        }
        
        guard let characteristic = service.findCharacteristic(uuidString: characteristicUUID) else {
            return
        }
        
        guard let descriptor = characteristic.findDescriptor(uuidString: descriptorUUID) else {
            return
        }
        
        // Cast string to data type
        guard let valueData = data.data(using: String.Encoding.utf8) else {
            return
        }
        
        // Write to the descriptor value
        peripheral._peripheral.writeValue(valueData, for: descriptor._descriptor)
    }
    
    // Mark: Private helper methods
    fileprivate func findPeripheral(deviceIdentifier: String) -> Peripheral?{
        guard let idx = _peripherals.index(where: { $0._peripheral.identifier.uuidString == deviceIdentifier })else {
            return nil
        }
        
        
        return _peripherals[idx]
    }
    

}
