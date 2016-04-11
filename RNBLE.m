#import "RNBLE.h"
#import "RCTEventDispatcher.h"
#import "RCTLog.h"
#import "RCTConvert.h"
#import "RCTCONVERT+CBUUID.h"

@interface RNBLE () <CBCentralManagerDelegate, CBPeripheralDelegate> {
	CBCentralManager    *centralManager;
	dispatch_queue_t eventQueue;
	NSMutableDictionary *_peripherals;
	//CBPeripheral *_connectedPeripheral;
	//NSString *_askedCharacteristicUUID;
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
	
	//_connectedPeripheral.delegate = self;
	[self.bridge.eventDispatcher sendDeviceEventWithName:@"connect" body:peripheral.identifier.UUIDString];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
	RCTLogInfo(@"didDisconnectPeripheral");
	//_connectedPeripheral = nil;
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
	RCTLogInfo(@"failed to connect");
	//_connectedPeripheral = nil;
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
	NSMutableArray *servicesUUID = [NSMutableArray new];
	
	// Loop through the newly filled peripheral.services array, just in case there's more than one.
	for (CBService *service in peripheral.services) {
		//		[peripheral discoverCharacteristics:nil forService:service];
		[servicesUUID addObject:service.UUID.UUIDString];
		//[_peripheralServices setObject:service forKey:service.UUID.UUIDString];
	}
	
	NSDictionary *dict = @{
						   @"peripheralUuid": peripheral.identifier.UUIDString,
						   @"servicesUuid": servicesUUID
						   };
	
	[self.bridge.eventDispatcher sendDeviceEventWithName:@"services" body:dict];
}

RCT_EXPORT_METHOD(discoverCharacteristics:(NSString *)peripheralUuid forService:(NSArray *)servicesUUID andCharacteristics:(NSArray *)characteristics)
{
	CBPeripheral *peripheral = [_peripherals objectForKey:peripheralUuid];
	
	if (peripheral) {
		RCTLogInfo(@"Discovering characteristics");
		for (NSString *serviceUUID in servicesUUID) {
			CBService *service = nil;
			for (CBService *serv in peripheral.services) {
				if ([serv.UUID.UUIDString isEqualToString:serviceUUID]) {
					service = serv;
					break;
				}
			}
			if (service) {
				[peripheral discoverCharacteristics:nil forService:service];
			}
			else {
				// Send that asked service not available
			}
		}
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
	
	if (error) {
		NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
		return;
	}
	NSMutableArray *characteristicsUUID = [NSMutableArray new];
	for (CBCharacteristic *characteristic in service.characteristics) {
		NSLog(characteristic.UUID.UUIDString);
		[characteristicsUUID addObject:characteristic.UUID.UUIDString];
		//[peripheral readValueForCharacteristic:characteristic];
	}
	NSLog(@"-%@-", peripheral.services[0].characteristics);
	[self.bridge.eventDispatcher sendDeviceEventWithName:@"characteristics" body:characteristicsUUID];
}

RCT_EXPORT_METHOD(readCharacteristic:(NSString *)peripheralUuid forService:(NSString *)serviceUUID andCharacteristic:(NSString *)characteristicUUID)
{
	CBPeripheral *peripheral = [_peripherals objectForKey:peripheralUuid];
	
	if (peripheral) {
		RCTLogInfo(@"Reading characteristics");
		CBService *service = nil;
		for (CBService *serv in peripheral.services) {
			if ([serv.UUID.UUIDString isEqualToString:serviceUUID]) {
				service = serv;
				break;
			}
		}
		if (service) {
			CBCharacteristic *characteristic = nil;
			NSLog(@"LEs char : ", service.characteristics);
			for (CBCharacteristic *characteri in service.characteristics ) {
				if ([characteri.UUID.UUIDString isEqualToString:characteristicUUID]) {
					characteristic = characteri;
					break;
				}
			}
			if (characteristic) {
				[peripheral readValueForCharacteristic:characteristic];
			}
			else {
				// Send that asked characteristic not available
			}
		}
		else {
			// Send that asked service not available
		}
	}
}

RCT_EXPORT_METHOD(subscribeCharacteristic:(NSString *)peripheralUuid forService:(NSString *)serviceUUID andCharacteristic:(NSString *)characteristicUUID)
{
	CBPeripheral *peripheral = [_peripherals objectForKey:peripheralUuid];
	
	if (peripheral) {
		RCTLogInfo(@"Reading characteristics");
		CBService *service = nil;
		for (CBService *serv in peripheral.services) {
			if ([serv.UUID.UUIDString isEqualToString:serviceUUID]) {
				service = serv;
				break;
			}
		}
		if (service) {
			CBCharacteristic *characteristic = nil;
			NSLog(@"LEs char : ", service.characteristics);
			for (CBCharacteristic *characteri in service.characteristics ) {
				if ([characteri.UUID.UUIDString isEqualToString:characteristicUUID]) {
					characteristic = characteri;
					break;
				}
			}
			if (characteristic) {
				[peripheral setNotifyValue:YES forCharacteristic:characteristic];
			}
			else {
				// Send that asked characteristic not available
			}
		}
		else {
			// Send that asked service not available
		}
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
	
	NSString *str = [[NSString alloc] initWithData:characteristic.value encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8)];
	NSLog(@"--%@--", [self NSDataToHex:characteristic.value]);
	
	if ([characteristic isNotifying] == true) {
		[self.bridge.eventDispatcher sendDeviceEventWithName:@"notify" body:[self NSDataToHex:characteristic.value]];
	}
	else {
		[self.bridge.eventDispatcher sendDeviceEventWithName:@"read" body:[self NSDataToHex:characteristic.value]];
	}
	
	
	//	if ([characteristic.UUID isEqual:_photoUUID]) {
	//		NSArray * photos = [NSKeyedUnarchiver unarchiveObjectWithData:characteristic.value];
	//	}
}

static inline char itoh(int i) {
	if (i > 9) return 'A' + (i - 10);
	return '0' + i;
}

-(NSString *)NSDataToHex:(NSData *)data {
	NSUInteger i, len;
	unsigned char *buf, *bytes;
	
	len = data.length;
	bytes = (unsigned char*)data.bytes;
	buf = malloc(len*2);
	
	for (i=0; i<len; i++) {
		buf[i*2] = itoh((bytes[i] >> 4) & 0xF);
		buf[i*2+1] = itoh(bytes[i] & 0xF);
	}
	
	return [[NSString alloc] initWithBytesNoCopy:buf
										  length:len*2
										encoding:NSASCIIStringEncoding
									freeWhenDone:YES];
}

- (NSDictionary *)errorHandler:(NSString *)message {
	NSDictionary *dict = @{
		@"error": message
	};
	return dict;
}

@end
