#import "RNBLE.h"
#import "RCTEventDispatcher.h"
#import "RCTLog.h"
#import "RCTConvert.h"
#import "RCTCONVERT+CBUUID.h"
#import "RCTUtils.h"

@interface RNBLE () <CBCentralManagerDelegate, CBPeripheralDelegate> {
  CBCentralManager *centralManager;
  dispatch_queue_t centralEventQueue;
  NSMutableDictionary *peripherals;
}
@end

@implementation RNBLE

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

#pragma mark Initialization

- (instancetype)init
{
  if (self = [super init]) {
    centralEventQueue = dispatch_queue_create("com.openble.mycentral", DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(centralEventQueue, dispatch_get_main_queue());
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralEventQueue options:@{ CBCentralManagerOptionRestoreIdentifierKey:@"myCentralManagerIdentifier" }];

    peripherals = [NSMutableDictionary new];
  }
  return self;
}

RCT_EXPORT_METHOD(startScanning:(CBUUIDArray *)uuids allowDuplicates:(BOOL)allowDuplicates)
{
  NSMutableDictionary *scanOptions = [NSMutableDictionary dictionaryWithObject:@NO
                                      forKey:CBCentralManagerScanOptionAllowDuplicatesKey];

  if(allowDuplicates){
    [scanOptions setObject:@YES forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
  }

  [centralManager scanForPeripheralsWithServices:uuids options:scanOptions];
}

RCT_EXPORT_METHOD(stopScanning)
{
  [centralManager stopScan];
}

RCT_EXPORT_METHOD(getState)
{
  [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.stateChange" body:[self NSStringForCBCentralManagerState:[centralManager state]]];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
   advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
  [peripherals setObject:peripheral forKey:peripheral.identifier.UUIDString];
  NSDictionary *advertisementDictionary = [self dictionaryForAdvertisementData:advertisementData fromPeripheral:peripheral];
  [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.discover" body:@{
                                        @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                        @"advertisement": advertisementDictionary,
                                        @"connectable": @([advertisementData[CBAdvertisementDataIsConnectable] boolValue]),
                                        @"rssi": RSSI
                                        }];
}

- (void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict
{

}

RCT_EXPORT_METHOD(connect:(NSString *)peripheralUuid)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];

  if (peripheral) {
    [centralManager connectPeripheral:peripheral options:nil];
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}

RCT_EXPORT_METHOD(disconnect:(NSString *)peripheralUuid)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];

  if (peripheral) {
    [centralManager cancelPeripheralConnection:peripheral];
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
  peripheral.delegate = self;
  [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.connect" body:@{
                                         @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString]}];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
  NSMutableDictionary *eventData = [NSMutableDictionary new];
  [eventData setObject:[self toNobleUuid:peripheral.identifier.UUIDString] forKey:@"peripheralUuid"];
  if (error != nil) {
    [eventData setObject:RCTJSErrorFromNSError(error) forKey:@"error"];
  }
  [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.disconnect" body:eventData];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
  [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.connect" body:@{
                                         @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                         @"error": RCTJSErrorFromNSError(error)
                                         }];
}

RCT_EXPORT_METHOD(updateRssi:(NSString *)peripheralUuid)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];

  if (peripheral) {
    [peripheral readRSSI];
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 80000

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
  if (error == nil) {
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.rssiUpdate" body:@{
                                            @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                            @"rssi": peripheral.RSSI
                                            }];
  }
}

#else

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
  if (error == nil) {
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.rssiUpdate" body:@{
                                            @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                            @"rssi": RSSI
                                            }];
  }
}

#endif

RCT_EXPORT_METHOD(discoverServices:(NSString *)peripheralUuid serviceUuids:(CBUUIDArray *)serviceUuids)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];

  if (peripheral) {
    [peripheral discoverServices:serviceUuids];
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}

RCT_EXPORT_METHOD(discoverIncludedServices:(NSString *)peripheralUuid serviceUuid:(NSString *)serviceUuid serviceUuids:(CBUUIDArray *)serviceUuids)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];

  if (peripheral) {
    CBService *targetService = [self getTargetService:peripheral serviceUuid:serviceUuid];
    if (targetService) {
      [peripheral discoverIncludedServices:serviceUuids forService:targetService];
    } else {
      NSLog(@"Could not find service %@ for peripheral %@", serviceUuid, peripheralUuid);
    }
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
  if (error == nil) {
    NSMutableArray *serviceUuids = [NSMutableArray new];
    for (CBService *service in peripheral.services) {
      [serviceUuids addObject:[self toNobleUuid:service.UUID.UUIDString]];
    }
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.servicesDiscover" body:@{
                                              @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                              @"serviceUuids": serviceUuids
                                              }];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error
{
  if (error == nil) {
    NSMutableArray *includedServiceUuids = [NSMutableArray new];
    for (CBService *includedService in service.includedServices) {
      [includedServiceUuids addObject:[self toNobleUuid:includedService.UUID.UUIDString]];
    }
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.includedServicesDiscover" body:@{
                                                  @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                                  @"serviceUuid": [self toNobleUuid:service.UUID.UUIDString],
                                                  @"includedServiceUuids": includedServiceUuids
                                                  }];
  }
}

RCT_EXPORT_METHOD(discoverCharacteristics:(NSString *)peripheralUuid serviceUuid:(NSString *)serviceUuid characteristicUuids:(CBUUIDArray *)characteristicUuids)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];
  if (peripheral) {
    CBService *targetService = [self getTargetService:peripheral serviceUuid:serviceUuid];
    if (targetService) {
      [peripheral discoverCharacteristics:characteristicUuids forService:targetService];
    } else {
      NSLog(@"Could not find service %@ for peripheral %@", serviceUuid, peripheralUuid);
    }
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}

RCT_EXPORT_METHOD(discoverDescriptors:(NSString *)peripheralUuid serviceUuid:(NSString *)serviceUuid characteristicUuid:(NSString *)characteristicUuid)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];
  if (peripheral) {
    CBCharacteristic *targetCharacteristic = [self getTargetCharacteristic:peripheral serviceUuid:serviceUuid characteristicUuid:characteristicUuid];
    if (targetCharacteristic) {
      [peripheral discoverDescriptorsForCharacteristic:targetCharacteristic];
    } else {
      NSLog(@"Could not find characteristic for UUID: %@", characteristicUuid);
    }
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
  if (error == nil) {
    NSMutableArray *characteristics = [NSMutableArray new];
    for (CBCharacteristic *characteristic in service.characteristics) {
      NSMutableDictionary *characteristicObject = [NSMutableDictionary new];
      [characteristicObject setValue:[self toNobleUuid:characteristic.UUID.UUIDString] forKey:@"uuid"];

      NSMutableArray *properties = [NSMutableArray new];

      if (characteristic.properties & CBCharacteristicPropertyBroadcast) {
        [properties addObject:@"broadcast"];
      }

      if (characteristic.properties & CBCharacteristicPropertyRead) {
        [properties addObject:@"read"];
      }

      if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        [properties addObject:@"writeWithoutResponse"];
      }

      if (characteristic.properties & CBCharacteristicPropertyWrite) {
        [properties addObject:@"write"];
      }

      if (characteristic.properties & CBCharacteristicPropertyNotify) {
        [properties addObject:@"notify"];
      }

      if (characteristic.properties & CBCharacteristicPropertyIndicate) {
        [properties addObject:@"indicate"];
      }

      if (characteristic.properties & CBCharacteristicPropertyAuthenticatedSignedWrites) {
        [properties addObject:@"authenticatedSignedWrites"];
      }

      if (characteristic.properties & CBCharacteristicPropertyExtendedProperties) {
        [properties addObject:@"extendedProperties"];
      }

      if (characteristic.properties & CBCharacteristicPropertyNotifyEncryptionRequired) {
        [properties addObject:@"notifyEncryptionRequired"];
      }

      if (characteristic.properties & CBCharacteristicPropertyIndicateEncryptionRequired) {
        [properties addObject:@"indicateEncryptionRequired"];
      }

      [characteristicObject setValue:properties forKey:@"properties"];
      [characteristics addObject:characteristicObject];
    }

    [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.characteristicsDiscover" body:@{
                                                   @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                                   @"serviceUuid": [self toNobleUuid:service.UUID.UUIDString],
                                                   @"characteristics": characteristics
                                                   }];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  if (error == nil) {
    NSMutableArray *descriptors = [NSMutableArray new];
    for (CBDescriptor *descriptor in characteristic.descriptors) {
      [descriptors addObject:[self toNobleUuid:descriptor.UUID.UUIDString]];
    }
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.descriptorsDiscover" body:@{
                                                 @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                                 @"serviceUuid": [self toNobleUuid:characteristic.service.UUID.UUIDString],
                                                 @"characteristicUuid": [self toNobleUuid:characteristic.UUID.UUIDString],
                                                 @"descriptors": descriptors
                                                 }];
  }
}

RCT_EXPORT_METHOD(read:(NSString *)peripheralUuid serviceUuid:(NSString *)serviceUuid characteristicUuid:(NSString *)characteristicUuid descriptorUuid:(NSString *)descriptorUuid)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];
  if (peripheral) {
    CBCharacteristic *targetCharacteristic = [self getTargetCharacteristic:peripheral serviceUuid:serviceUuid characteristicUuid:characteristicUuid];
    if (targetCharacteristic) {
      [peripheral readValueForCharacteristic:targetCharacteristic];
    } else {
      NSLog(@"Could not find characteristic for UUID: %@", characteristicUuid);
    }
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}

RCT_EXPORT_METHOD(readValue:(NSString *)peripheralUuid serviceUuid:(NSString *)serviceUuid characteristicUuid:(NSString *)characteristicUuid descriptorUuid:(NSString *)descriptorUuid)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];
  if (peripheral) {
    CBCharacteristic *targetCharacteristic = [self getTargetCharacteristic:peripheral serviceUuid:serviceUuid characteristicUuid:characteristicUuid];
    if (targetCharacteristic) {
      CBDescriptor *targetDescriptor = [self getTargetDescriptor:peripheral serviceUuid:serviceUuid characteristicUuid:characteristicUuid descriptorUuid:descriptorUuid];
      if (targetDescriptor) {
        [peripheral readValueForDescriptor:targetDescriptor];
      }else {
        NSLog(@"Could not find descriptor for UUID: %@", descriptorUuid);
      }
    } else {
      NSLog(@"Could not find characteristic for UUID: %@", characteristicUuid);
    }
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}

RCT_EXPORT_METHOD(read:(NSString *)peripheralUuid serviceUuid:(NSString *)serviceUuid characteristicUuid:(NSString *)characteristicUuid)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];
  if (peripheral) {
    CBCharacteristic *targetCharacteristic = [self getTargetCharacteristic:peripheral serviceUuid:serviceUuid characteristicUuid:characteristicUuid];
    if (targetCharacteristic) {
      [peripheral readValueForCharacteristic:targetCharacteristic];
    } else {
      NSLog(@"Could not find characteristic for UUID: %@", characteristicUuid);
    }
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}


RCT_EXPORT_METHOD(writeValue:(NSString *)peripheralUuid serviceUuid:(NSString *)serviceUuid characteristicUuid:(NSString *)characteristicUuid descriptorUuid:(NSString *)descriptorUuid data:(NSString *)data)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];
  if (peripheral) {
    CBCharacteristic *targetCharacteristic = [self getTargetCharacteristic:peripheral serviceUuid:serviceUuid characteristicUuid:characteristicUuid];
    if (targetCharacteristic) {
      CBDescriptor *targetDescriptor = [self getTargetDescriptor:peripheral serviceUuid:serviceUuid characteristicUuid:characteristicUuid descriptorUuid:descriptorUuid];
      if (targetDescriptor) {
        [peripheral writeValue:[[NSData alloc] initWithBase64EncodedString:data options:0] forDescriptor:targetDescriptor];
      }else {
        NSLog(@"Could not find descriptor for UUID: %@", descriptorUuid);
      }
    } else {
      NSLog(@"Could not find characteristic for UUID: %@", characteristicUuid);
    }
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}


RCT_EXPORT_METHOD(write:(NSString *)peripheralUuid serviceUuid:(NSString *)serviceUuid characteristicUuid:(NSString *)characteristicUuid data:(NSString *)data withoutResponse:(BOOL)withoutResponse)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];
  if (peripheral) {
    CBCharacteristic *targetCharacteristic = [self getTargetCharacteristic:peripheral serviceUuid:serviceUuid characteristicUuid:characteristicUuid];
    if (targetCharacteristic) {
      [peripheral writeValue:[[NSData alloc] initWithBase64EncodedString:data options:0] forCharacteristic:targetCharacteristic type:withoutResponse ? CBCharacteristicWriteWithoutResponse : CBCharacteristicWriteWithResponse];
    } else {
      NSLog(@"Could not find characteristic for UUID: %@", characteristicUuid);
    }
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}

RCT_EXPORT_METHOD(notify:(NSString *)peripheralUuid serviceUuid:(NSString *)serviceUuid characteristicUuid:(NSString *)characteristicUuid notify:(BOOL)notify)
{
  CBPeripheral *peripheral = peripherals[peripheralUuid];
  if (peripheral) {
    CBCharacteristic *targetCharacteristic = [self getTargetCharacteristic:peripheral serviceUuid:serviceUuid characteristicUuid:characteristicUuid];
    if (targetCharacteristic) {
      [peripheral setNotifyValue:notify forCharacteristic:targetCharacteristic];
    } else {
      NSLog(@"Could not find characteristic for UUID: %@", characteristicUuid);
    }
  } else {
    NSLog(@"Could not find peripheral for UUID: %@", peripheralUuid);
  }
}


- (CBDescriptor *)getTargetDescriptor:(CBPeripheral *)peripheral serviceUuid:(NSString *)serviceUuid characteristicUuid:(NSString *)characteristicUuid descriptorUuid:(NSString *)descriptorUuid
{
  CBDescriptor *targetDescriptor;
  CBCharacteristic *targetCharacteristic = [self getTargetCharacteristic:peripheral serviceUuid:serviceUuid characteristicUuid:characteristicUuid];
  if (targetCharacteristic) {
    for (CBDescriptor *descriptor in targetCharacteristic.descriptors) {
      if ([descriptor.UUID.UUIDString isEqualToString:descriptorUuid]) {
        targetDescriptor = descriptor;
        break;
      }
    }
  }
  return targetDescriptor;
}

- (CBCharacteristic *)getTargetCharacteristic:(CBPeripheral *)peripheral serviceUuid:(NSString *)serviceUuid characteristicUuid:(NSString *)characteristicUuid
{
  CBCharacteristic *targetCharacteristic;
  CBService *targetService = [self getTargetService:peripheral serviceUuid:serviceUuid];
  if (targetService) {
    for (CBCharacteristic *characteristic in targetService.characteristics) {
      if ([characteristic.UUID.UUIDString isEqualToString:characteristicUuid]) {
        targetCharacteristic = characteristic;
        break;
      }
    }
  }
  return targetCharacteristic;
}

- (CBService *)getTargetService:(CBPeripheral *)peripheral serviceUuid:(NSString *)serviceUuid
{
  CBService *targetService;
  for (CBService *service in peripheral.services) {
    if ([service.UUID.UUIDString isEqualToString:serviceUuid]) {
      targetService = service;
      break;
    }
  }
  return targetService;
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  if (error == nil) {
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.notify" body:@{
                                          @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                          @"serviceUuid": [self toNobleUuid:characteristic.service.UUID.UUIDString],
                                          @"characteristicUuid": [self toNobleUuid:characteristic.UUID.UUIDString],
                                          @"state": @(characteristic.isNotifying)
                                          }];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  if (error == nil) {
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.data" body:@{
                                        @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                        @"serviceUuid": [self toNobleUuid:characteristic.service.UUID.UUIDString],
                                        @"characteristicUuid": [self toNobleUuid:characteristic.UUID.UUIDString],
                                        @"data": [characteristic.value base64EncodedStringWithOptions:0],
                                        @"isNotification": @(characteristic.isNotifying)
                                        }];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
  if (error == nil) {
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.valueUpdate" body:@{
                                             @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                             @"serviceUuid": [self toNobleUuid:descriptor.characteristic.service.UUID.UUIDString],
                                             @"characteristicUuid": [self toNobleUuid:descriptor.characteristic.UUID.UUIDString],
                                             @"descriptorUuid": [self toNobleUuid:descriptor.UUID.UUIDString],
                                             @"data": [descriptor.value base64EncodedStringWithOptions:0]
                                             }];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
  if (error == nil) {
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.valueWrite" body:@{
                                            @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                            @"serviceUuid": [self toNobleUuid:descriptor.characteristic.service.UUID.UUIDString],
                                            @"characteristicUuid": [self toNobleUuid:descriptor.characteristic.UUID.UUIDString],
                                            @"descriptorUuid": [self toNobleUuid:descriptor.UUID.UUIDString]
                                            }];
  }
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  if (error == nil) {
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.write" body:@{
                                         @"peripheralUuid": [self toNobleUuid:peripheral.identifier.UUIDString],
                                         @"serviceUuid": [self toNobleUuid:characteristic.service.UUID.UUIDString],
                                         @"characteristicUuid": [self toNobleUuid:characteristic.UUID.UUIDString]
                                         }];
  }
}

- (NSDictionary *)dictionaryForAdvertisementData:(NSDictionary *)advertisementData fromPeripheral:(CBPeripheral *)peripheral
{
  NSMutableDictionary *advertisement = [NSMutableDictionary new];
  
  if (advertisementData[CBAdvertisementDataLocalNameKey] != nil) {
    advertisement[@"localName"] = advertisementData[CBAdvertisementDataLocalNameKey];
  }
  
  if (advertisementData[CBAdvertisementDataManufacturerDataKey] != nil) {
    advertisement[@"manufacturerData"] = [advertisementData[CBAdvertisementDataManufacturerDataKey] base64EncodedStringWithOptions:0];
  }
  
  if (advertisementData[CBAdvertisementDataServiceDataKey] != nil) {
    advertisement[@"serviceData"] = [NSMutableArray new];
    for (CBUUID *uuid in advertisementData[CBAdvertisementDataServiceDataKey]) {
      [advertisement[@"serviceData"] addObject:@{
                             @"uuid": [self toNobleUuid:uuid.UUIDString],
                             @"data": [advertisementData[CBAdvertisementDataServiceDataKey][uuid] base64EncodedStringWithOptions:0]
                             }];
    }
  }
  
  if (advertisementData[CBAdvertisementDataServiceUUIDsKey] != nil) {
    advertisement[@"serviceUuids"] = [NSMutableArray new];
    for (CBUUID *uuid in advertisementData[CBAdvertisementDataServiceUUIDsKey]) {
      [advertisement[@"serviceUuids"] addObject:[self toNobleUuid:uuid.UUIDString]];
    }
  }
  
  if (advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] != nil) {
    advertisement[@"overflowServiceUuids"] = [NSMutableArray new];
    for (CBUUID *uuid in advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey]) {
      [advertisement[@"overflowServiceUuids"] addObject:[self toNobleUuid:uuid.UUIDString]];
    }
  }
  
  if (advertisementData[CBAdvertisementDataTxPowerLevelKey] != nil) {
    advertisement[@"txPowerLevel"] = advertisementData[CBAdvertisementDataTxPowerLevelKey];
  }
  
  if (advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] != nil) {
    advertisement[@"solicitedServiceUuids"] = [NSMutableArray new];
    for (CBUUID *uuid in advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey]) {
      [advertisement[@"solicitedServiceUuids"] addObject:[self toNobleUuid:uuid.UUIDString]];
    }
  }
  
  return advertisement;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
  [self.bridge.eventDispatcher sendDeviceEventWithName:@"ble.stateChange" body:[self NSStringForCBCentralManagerState:[central state]]];
}

- (NSString *)toNobleUuid:(NSString *)uuidString
{
  NSString *noDashes = [uuidString stringByReplacingOccurrencesOfString:@"-" withString:@""];
  return [noDashes lowercaseString];
}

- (NSString *)NSStringForCBCentralManagerState:(CBCentralManagerState)state
{
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

@end
