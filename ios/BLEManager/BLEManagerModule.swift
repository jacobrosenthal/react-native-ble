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
        manager = CentralManager(withQueue: queue, dispatchDelegate: delegate!)
        super.init()
    }
    
    // Mark: Connections
    open func connect(deviceIdentifier: String, options: [String:AnyObject]?) {
        
        // Connect to peripheral indicated by identifier
        manager.connectPeripheral(peripheralUUID: UUID(uuidString: deviceIdentifier)!)
    }
    
    open func disconnect(deviceIdentifier: String){
        
        // Disconnect from peripheral indicated by identifier
        manager.disconnectPeripheral(peripheralUUID: CBUUID(string: deviceIdentifier))
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
            
            for uuid in serviceUUIDs {
                uuids?.append(CBUUID(string: uuid))
            }
            
        }
        
        // Start scanning from the central manager.
        manager.scanForPeripherals(serviceUUIDs: uuids, scanOptions: scanOptions);
        
        // Send event to noble for scan start
        dispatchEvent(BLEEvent.SCAN_START.description, value: " " as Any)
    }
    
    open func stopScanning() {
        manager.stopScanForPeripherals();
        
        // Send event to noble for scan stop
        dispatchEvent(BLEEvent.SCAN_STOP, value: " " as Any)
    }

    
    
    // MARK: Private interface -----------------------------------------------------------------------------------------
    fileprivate func dispatchEvent(_ event: String, value: Any) {
        delegate?.dispatchEvent(event, value: value as AnyObject)
    }
}
