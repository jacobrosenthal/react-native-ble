import Foundation

@objc
public class BLEEvent: NSObject{
    static public let STATE_CHANGE = "stateChange"
    static public let ADDRESS_CHANGE = "addressChange"
    static public let SCAN_START = "scanStart"
    static public let SCAN_STOP = "scanStop"
    static public let DISCOVER = "discover"
    static public let CONNECT = "connect"
    static public let DISCONNECT = "disconnect"
    static public let RSSI_UPDATE = "rssiUpdate"
    static public let SERVICES_DISCOVER = "servicesDiscover"
    static public let INCLUDED_SERVICES_DISCOVER = "includedServicesDiscover"
    static public let CHARACTERISTICS_DISCOVER = "characteristicsDiscover"
    static public let READ = "read"
    static public let WRITE = "write"
    static public let BROADCAST = "broadcast"
    static public let NOTIFY = "notify"
    static public let DESCRIPTORS_DISCOVER = "descriptorsDiscover"
    static public let VALUE_READ = "valueRead"
    static public let VALUE_WRITE = "valueWrite"
    static public let HANDLE_READ = "handleRead"
    static public let HANDLE_WRITE = "handleWrite"
    static public let HANDLE_NOTIFY = "handleNotify"
    
    static public let events = [
        STATE_CHANGE,
        ADDRESS_CHANGE,
        SCAN_START,
        SCAN_STOP,
        DISCOVER,
        CONNECT,
        DISCONNECT,
        RSSI_UPDATE,
        SERVICES_DISCOVER,
        INCLUDED_SERVICES_DISCOVER,
        CHARACTERISTICS_DISCOVER,
        READ,
        WRITE,
        BROADCAST,
        NOTIFY,
        DESCRIPTORS_DISCOVER,
        VALUE_READ,
        VALUE_WRITE,
        HANDLE_READ,
        HANDLE_WRITE,
        HANDLE_NOTIFY,
    ]
}
