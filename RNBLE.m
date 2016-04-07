#import "RNBLE.h"
#import "RCTEventDispatcher.h"
#import "RCTLog.h"
#import "RCTConvert.h"
#import "RCTCONVERT+CBUUID.h"

@interface RNBLE () <CBCentralManagerDelegate, CBPeripheralDelegate> {
	CBCentralManager    *centralManager;
	dispatch_queue_t eventQueue;
    NSMutableDictionary *_peripherals;
	CBPeripheral *_connectedPeripheral;
}
@end

@implementation RNBLE

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

#pragma mark Initialization

- (instancetype)init
{
    if (self = [super init]) {

	}
	_connectedPeripheral = nil;
	return self;
}

RCT_EXPORT_METHOD(setup)
{
    eventQueue = dispatch_queue_create("com.openble.mycentral", DISPATCH_QUEUE_SERIAL);

    dispatch_set_target_queue(eventQueue, dispatch_get_main_queue());
    
    _peripherals = [NSMutableDictionary dictionary];
    
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:eventQueue options:@{}];
}

RCT_EXPORT_METHOD(startScanning:(CBUUIDArray *)uuids allowDuplicates:(BOOL)allowDuplicates)
{
//	RCTLogInfo(@"startScanning %@ %d", uuids, allowDuplicates);

	NSMutableDictionary *scanOptions = [NSMutableDictionary dictionaryWithObject:@NO
	                                                      forKey:CBCentralManagerScanOptionAllowDuplicatesKey];

	if(allowDuplicates){
		[scanOptions setObject:@YES forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
	}

//    RCTLogInfo(@"startScanning %@ %@", uuids, scanOptions);

    [centralManager scanForPeripheralsWithServices:uuids options:scanOptions];
}

RCT_EXPORT_METHOD(stopScanning)
{
//	RCTLogInfo(@"stopScanning");

	[centralManager stopScan];
}

RCT_EXPORT_METHOD(connect:(NSString *)peripheralUuid)
{
    CBPeripheral *peripheral = [_peripherals objectForKey:peripheralUuid];
    
    if (peripheral) {
        RCTLogInfo(@"connecting");
        [centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    RCTLogInfo(@"Connected");
    peripheral.delegate = self;
	_connectedPeripheral = peripheral;
	_connectedPeripheral.delegate = self;
	[self.bridge.eventDispatcher sendDeviceEventWithName:@"connect" body:peripheral.identifier.UUIDString];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    RCTLogInfo(@"didDisconnectPeripheral");
	_connectedPeripheral = nil;
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    RCTLogInfo(@"failed to connect");
	_connectedPeripheral = nil;
}

RCT_EXPORT_METHOD(getState)
{
   // RCTLogInfo(@"getState");
    
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"stateChange" body:[self NSStringForCBCentralManagerState:[centralManager state]]];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
			advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    [_peripherals setObject: peripheral forKey: peripheral.identifier.UUIDString];

    NSDictionary *advertisementDictionary = [self dictionaryForAdvertisementData:advertisementData fromPeripheral:peripheral];
    
    NSDictionary *event = @{
                            @"kCBMsgArgDeviceUUID": peripheral.identifier.UUIDString,
                            @"kCBMsgArgAdvertisementData": advertisementDictionary,
                            @"kCBMsgArgName": @"",
                            @"kCBMsgArgRssi": RSSI
                            };

    [self.bridge.eventDispatcher sendDeviceEventWithName:@"discover" body:event];
}

-(NSDictionary *)dictionaryForPeripheral:(CBPeripheral*)peripheral
{
    return @{ @"identifier" : peripheral.identifier.UUIDString, @"name" : peripheral.name ? peripheral.name : @"", @"state" : [self nameForCBPeripheralState:peripheral.state] };
}

-(NSDictionary *)dictionaryForAdvertisementData:(NSDictionary*)advertisementData fromPeripheral:(CBPeripheral*)peripheral
{
//	RCTLogInfo(@"dictionaryForAdvertisementData %@ %@", advertisementData, peripheral);
 
    NSString *localNameString = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
    localNameString = localNameString ? localNameString : @"";

    NSData *manufacturerData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
    NSString *manufacturerDataString = [manufacturerData base64EncodedStringWithOptions:0];
    manufacturerDataString = manufacturerDataString ? manufacturerDataString : @"";

    NSDictionary *serviceDataDictionary = [advertisementData objectForKey:@"kCBAdvDataServiceData"];
    NSMutableDictionary *stringServiceDataDictionary = [NSMutableDictionary new];
    
    for (CBUUID *cbuuid in serviceDataDictionary)
    {
        NSString *uuidString = cbuuid.UUIDString;
        NSData *serviceData =  [serviceDataDictionary objectForKey:cbuuid];
        NSString *serviceDataString = [serviceData base64EncodedStringWithOptions:0];
        
//        RCTLogInfo(@"stringServiceDataDictionary %@ %@", serviceDataString, uuidString);
        [stringServiceDataDictionary setObject:serviceDataString forKey:uuidString];
    }
//    RCTLogInfo(@"stringServiceDataDictionary %@", stringServiceDataDictionary);

    NSMutableArray *serviceUUIDsStringArray = [NSMutableArray new];
    for (CBUUID *cbuuid in [advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"])
    {
        [serviceUUIDsStringArray addObject:cbuuid.UUIDString];
    }
    
    NSDictionary *advertisementDataDictionary = @{ @"identifier" : @"",
                            @"kCBAdvDataIsConnectable" : [advertisementData objectForKey:@"kCBAdvDataIsConnectable"],
                            @"kCBAdvDataLocalName" : localNameString,
                            @"kCBAdvDataManufacturerData" : manufacturerDataString,
                            @"kCBAdvDataServiceData" : stringServiceDataDictionary,
                            @"kCBAdvDataServiceUUIDs" : serviceUUIDsStringArray,
                            @"kCBAdvDataTxPowerLevel" : [advertisementData objectForKey:@"kCBAdvDataTxPowerLevel"] ? [advertisementData objectForKey:@"kCBAdvDataTxPowerLevel"] : @""
                            };
    
    return advertisementDataDictionary;
}


- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"stateChange" body:[self NSStringForCBCentralManagerState:[central state]]];
}

- (NSString*) NSStringForCBCentralManagerState:(CBCentralManagerState)state{
    NSString *stateString = [NSString new];
    
    switch (state) {
        case CBCentralManagerStateResetting:
            stateString = @"resetting";
            break;
        case CBCentralManagerStateUnsupported:
            stateString = @"unsupported";
            break;
        case CBCentralManagerStateUnauthorized:
            stateString = @"unauthorized";
            break;
        case CBCentralManagerStatePoweredOff:
            stateString = @"poweredOff";
            break;
        case CBCentralManagerStatePoweredOn:
            stateString = @"poweredOn";
            break;
        case CBCentralManagerStateUnknown:
        default:
            stateString = @"unknown";
    }
    return stateString;
}

-(NSString *)nameForCBPeripheralState:(CBPeripheralState)state{
    switch (state) {
        case CBPeripheralStateDisconnected:
            return @"CBPeripheralStateDisconnected";

        case CBPeripheralStateConnecting:
            return @"CBPeripheralStateConnecting";

        case CBPeripheralStateConnected:
            return @"CBPeripheralStateConnected";
            
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
        case CBPeripheralStateDisconnecting:
            return @"CBPeripheralStateDisconnecting";
#endif
    }
}

-(NSString *)nameForCBCentralManagerState:(CBCentralManagerState)state{
    switch (state) {
        case CBCentralManagerStateUnknown:
            return @"CBCentralManagerStateUnknown";

        case CBCentralManagerStateResetting:
            return @"CBCentralManagerStateResetting";

        case CBCentralManagerStateUnsupported:
            return @"CBCentralManagerStateUnsupported";

        case CBCentralManagerStateUnauthorized:
            return @"CBCentralManagerStateUnauthorized";

        case CBCentralManagerStatePoweredOff:
            return @"CBCentralManagerStatePoweredOff";

        case CBCentralManagerStatePoweredOn:
            return @"CBCentralManagerStatePoweredOn";
    }
}

RCT_EXPORT_METHOD(discoverServices:(NSString *)peripheralUuid)
{
	CBPeripheral *peripheral = [_peripherals objectForKey:peripheralUuid];
	
	if (peripheral) {
		RCTLogInfo(@"Discovering services");
		[peripheral discoverServices:nil];
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
	
	if (error) {
		NSLog(@"Error discovering services: %@", [error localizedDescription]);
		return;
	}
	NSLog(@"%@", peripheral.services);
	NSMutableArray *servicesUUID = [NSMutableArray new];
	
	
	// Loop through the newly filled peripheral.services array, just in case there's more than one.
	for (CBService *service in peripheral.services) {
//		[peripheral discoverCharacteristics:nil forService:service];
		[servicesUUID addObject:service.UUID.UUIDString];
	//	NSLog(service);
		NSLog(@"---%@--", service.UUID.UUIDString);
	}
	[self.bridge.eventDispatcher sendDeviceEventWithName:@"services" body:servicesUUID];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
	
	if (error) {
		NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
		return;
	}
	//[self.bridge.eventDispatcher sendDeviceEventWithName:@"connect" body:peripheral.identifier.UUIDString];
	
	// Again, we loop through the array, just in case.
//	for (CBCharacteristic *characteristic in service.characteristics) {
//		NSLog(characteristic.UUID.UUIDString);
//		if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A5B"]]) {
//			// If it is, subscribe to it
//			//[peripheral setNotifyValue:YES forCharacteristic:characteristic];
//		}
//	}
}

@end
