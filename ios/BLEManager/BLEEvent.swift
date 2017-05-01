import Foundation

@objc
public class BLEEvent: NSObject{
    static public let STATE_CHANGE = "stateChangeEvent"
    static public let ADDRESS_CHANGE = "addressChangeEvent"
    static public let SCAN_START = "scanStartEvent"
    static public let SCAN_STOP = "scanStopEvent"
    static public let DISCOVER = "discoverEvent"
    static public let CONNECT = "connectEvent"
    static public let DISCONNECT = "disconnectEvent"
    static public let RSSI_UPDATE = "rssiUpdateEvent"
    static public let SERVICES_DISCOVER = "servicesDiscoverEvent"
    static public let INCLUDED_SERVICES_DISCOVER = "includedServicesDiscoverEvent"
    static public let CHARACTERISTICS_DISCOVER = "characteristicsDiscoverEvent"
    static public let READ = "readEvent"
    static public let WRITE = "writeEvent"
    static public let BROADCAST = "broadcastEvent"
    static public let NOTIFY = "notifyEvent"
    static public let DESCRIPTORS_DISCOVER = "descriptorsDiscoverEvent"
    static public let VALUE_READ = "valueReadEvent"
    static public let VALUE_WRITE = "valueWriteEvent"
    static public let HANDLE_READ = "handleReadEvent"
    static public let HANDLE_WRITE = "handleWriteEvent"
    static public let HANDLE_NOTIFY = "handleNotifyEvent"
    
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
