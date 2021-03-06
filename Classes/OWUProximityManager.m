//
//  OWUBlueBeaconServiceManager.m
//  Beaconing
//
//  Created by David Ohayon on 10/11/13.
//  Copyright (c) 2013 ohwutup software. All rights reserved.
//

#import "OWUProximityManager.h"
#import "OWUClientManager.h"
#import "OWUServerManager.h"

@interface OWUProximityManager (Delegates) <OWUProximityClientDelegate, OWUProximityServerDelegate>

@end

@implementation OWUProximityManager

+ (instancetype)shared {
    static OWUProximityManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OWUProximityManager alloc] init];
    });
    
    return _sharedInstance;
}

- (void)teardownService {
    [[OWUClientManager shared] teardownClient];
    [[OWUServerManager shared] teardownServer];
}

#pragma mark - OWUClient

- (void)startupClientWithDelegate:(id)delegate {
    self.delegate = delegate;
    [[OWUClientManager shared] startupClient];
    [OWUClientManager shared].desiredProximity = self.desiredProximity;
    [OWUClientManager shared].delegate = self;
}

- (void)postToServerWithDictionary:(NSDictionary*)dictionary {
    [[OWUClientManager shared] updateCharactaristicValueWithDictionary:dictionary];
}

#pragma mark - OWUServer

- (void)startupServerWithDelegate:(id)delegate {
    self.delegate = delegate;
    [[OWUServerManager shared] startupServer];
    [OWUServerManager shared].delegate = self;
}

#pragma mark - OWUClientManagerDelegate

- (void)clientManagerIsPublishingToCentral {
    [self.delegate proximityClientDidConnectToServer];
}

- (void)clientManagerDidEnterBeaconRegion {
    [self.delegate proximityClientDidEnterRegion];
}

- (void)clientManagerDidExitBeaconRegion {
    [self.delegate proximityClientDidExitRegion];
}

- (void)clientManagerDidRangeBeacon:(CLBeacon*)beacon inRegion:(CLBeaconRegion*)region {
    [self.delegate proximityClientDidRangeBeacon:beacon];
    switch (beacon.proximity) {
        case CLProximityFar:
            if (self.desiredProximity == CLProximityFar) {
                [[OWUClientManager shared] startupConnectionToServerInRegion:region];
            }
            break;
        case CLProximityNear:
            if (self.desiredProximity == CLProximityNear || !self.desiredProximity) {
                [[OWUClientManager shared] startupConnectionToServerInRegion:region];
            }
            break;
        case CLProximityImmediate:
            if (self.desiredProximity == CLProximityImmediate) {
                [[OWUClientManager shared] startupConnectionToServerInRegion:region];
            }
            break;
        case CLProximityUnknown:
            
            break;
        default:
            break;
    }
}

- (void)clientManagerDidDetermineRegionState:(CLRegionState)state {
    
}

#pragma mark - OWUServerManagerDelegate

- (void)serverManagerDidSubscribeToCharacteristic {
    [self.delegate proximityServerDidConnectToClient];
}

- (void)serverManagerDidReceiveUpdateToCharacteristicValue:(NSDictionary*)JSONDictionary {
    [self.delegate proximityServerDidReceiveNewDictionary:JSONDictionary];
}

@end
