//
//  RNBLE.m
//  RNBLE
//
//  Created by Bryce Jacobs on 4/17/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "RNBLE.m"
@import BLEManager;

@interface BLEManagerModule () <BLEManagerDelegate>
@property(nonatomic) BLEManager* manager;
@end

@implementation BLEManagerModule

@synthesize methodQueue = _methodQueue;

RCT_EXPORT_MODULE(BLEManager);

- (void)dispatchEvent:(NSString * _Nonnull)name value:(id _Nonnull)value {
    [self sendEventWithName:name body:value];
}

- (NSArray<NSString *> *)supportedEvents {
    return BLEEvent.events;
}

- (NSDictionary<NSString *,id> *)constantsToExport {
    NSMutableDictionary* consts = [NSMutableDictionary new];
    for (NSString* event in BLEEvent.events) {
        [consts setValue:event forKey:event];
    }
    return consts;
}

RCT_EXPORT_METHOD(createManager) {
    _manager = [[BLEManager alloc] initWithQueue:self.methodQueue];
    _manager.delegate = self;
}

RCT_EXPORT_METHOD(destroyManager) {
    [_manager invalidate];
    _manager = nil;
}

- (void)invalidate {
    [self destroyManager];
}

// Mark: Scanning ------------------------------------------------------------------------------------------------------

RCT_EXPORT_METHOD(startScanning:(NSArray*)serviceUUIDs
                  options:(NSDictionary*)options) {
    
    [_manager startScanning:serviceUUIDs options:options];
}

RCT_EXPORT_METHOD(stopScanning) {
    [_manager stopScanning];
}

// Mark: Connection management -----------------------------------------------------------------------------------------
RCT_EXPORT_METHOD(connect:(NSString*)deviceIdentifier
                  options:(NSDictionary*)options) {
    
    [_manager connect:deviceIdentifier
                      options:options];
}

RCT_EXPORT_METHOD(disconnect:(NSString*)deviceIdentifier) {
    [_manager disconnect:deviceIdentifier];
}

// Mark: Discovery -----------------------------------------------------------------------------------------------------
RCT_EXPORT_METHOD(discoverServices:(NSString*)deviceIdentifier
                  serviceUUIDs:(NSArray*)serviceUUIDs) {
    
    [_manager discoverServices:deviceIdentifier
                                serviceUUIDs:serviceUUIDs];
}


RCT_EXPORT_METHOD(discoverIncludedServices: (NSString*)deviceIdentifier
                  serviceIdentifier:(NSString*)serviceIdentifier
                  serviceUUIDs:(NSArray*)serviceUUIDs) {
    
    [_manager discoverIncludedServices:deviceIdentifier
                                        serviceUUID:serviceUUID
                                        serviceUUIDs:serviceUUIDs];
}

RCT_EXPORT_METHOD(discoverCharacteristics: (NSString*)deviceIdentifier
                  serviceUUID:(NSString*)serviceUUID
                  characteristicUUIDs:(NSArray*)characteristicUUIDs) {
    
    [_manager discoverCharacteristics:deviceIdentifier
                    serviceIdentifier:serviceIdentifier
                    characteristicUUIDs:characteristicUUIDs];
}

RCT_EXPORT_METHOD(discoverDescriptors: (NSString*)deviceIdentifier
                  serviceUUID:(NSString*)serviceUUID
                  characteristicUUID:(NSString*)characteristicUUID) {
    
    [_manager discoverDescriptors:deviceIdentifier
                    serviceUUID:serviceUUID
                    characteristicUUID:characteristicUUID];
}

// Mark: Characteristics operations ------------------------------------------------------------------------------------

RCT_EXPORT_METHOD(read:(NSString*)deviceIdentifier
                  serviceUUID:(NSString*)serviceUUID
                  characteristicUUID:(NSString*)characteristicUUID) {
    
    [_manager read:deviceIdentifier
                    serviceUUID:serviceUUID
                    characteristicUUID:characteristicUUID];
}

RCT_EXPORT_METHOD(write:(NSString*)deviceIdentifier
                  serviceUUID:(NSString*)serviceUUID
                  characteristicUUID:(NSString*)characteristicUUID
                  data:(NSString*)data
                  withoutResponse:(BOOL)response) {
    
    [_manager write:deviceIdentifier
                    serviceUUID:serviceUUID
                    characteristicUUID:characteristicUUID
                    data:data,
                    withoutResponse:withoutResponse];
}

RCT_EXPORT_METHOD(notify:(NSString*)deviceIdentifier
                  serviceUUID:(NSString*)serviceUUID
                  characteristicUUID:(NSString*)characteristicUUID
                  notify:(BOOL)notify) {
    
    [_manager notify:deviceIdentifier
                    serviceUUID:serviceUUID
                    characteristicUUID:characteristicUUID
                    notify:notify];
}

RCT_EXPORT_METHOD(readValue:(NSString*)deviceIdentifier
                  serviceUUID:(NSString*)serviceUUID
                  characteristicUUID:(NSString*)characteristicUUID
                  descriptorUUID:(NSString*)descriptorUUID) {
    
    [_manager readValue:deviceIdentifier
                    serviceUUID:serviceUUID
                    characteristicUUID:characteristicUUID
                    descriptorUUID:descriptorUUID];
}

RCT_EXPORT_METHOD(writeValue:(NSString*)deviceIdentifier
                  serviceUUID:(NSString*)serviceUUID
                  characteristicUUID:(NSString*)characteristicUUID
                  descriptorUUID:(NSString*)descriptorUUID
                  data:(NSString*)data) {
    
    [_manager writeValue:deviceIdentifier
                    serviceUUID:serviceUUID
                    characteristicUUID:characteristicUUID
                    descriptorUUID:descriptorUUID
                    data:data];
}
@end
