//
//  APIManager.m
//  GoCheckin
//
//  Created by Mike Chou on 4/11/16.
//
//

#import "APIManager.h"
#import "HTTPClient.h"
#import "PersistencyManager.h"
#import "GoStationAnnotation.h"
#import "GoChargerAnnotation.h"
#import "MapOption.h"

@interface APIManager()

@property (strong, nonatomic) HTTPClient *httpClient;
@property (strong, nonatomic) PersistencyManager *persistencyManager;

@end

@implementation APIManager

+ (APIManager *)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _httpClient = [[HTTPClient alloc] init];
        _persistencyManager = [[PersistencyManager alloc] init];
    }
    return self;
}

- (void)updateEnergyNetworkIfNeeded {
    // MARK: for developing porpurse will move in after finish
    [self updateEnergyNetwork];
    
    if ([self _dataUpdateNeeded]) {

    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GoStationUpdateFinishNotification" object:nil];
    }
}

- (void)updateEnergyNetwork {
    dispatch_group_t requestGroup = dispatch_group_create();
    [self _updateGoChargerWithGroup:requestGroup];
    [self _updateGoStationWithGroup:requestGroup];
    dispatch_group_notify(requestGroup, dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GoStationUpdateFinishNotification" object:nil];
    });
}

- (GoStationAnnotation *)updateCheckInDataWithStationUUID:(NSString *)uuid {
    
    GoStation *updatedStation = [self.persistencyManager updateCheckInDataWithUUID:uuid];
    
    GoStationAnnotation *updatedAnnotation;
    if (updatedStation) {
        updatedAnnotation = [[GoStationAnnotation alloc] initWithGoStation:updatedStation];
    }
    
    return updatedAnnotation;
}

- (GoStationAnnotation *)removeCheckInDataWithStationUUID:(NSString *)uuid {
    
    GoStation *updatedStation = [self.persistencyManager removeCheckInDataWithUUID:uuid];
    
    GoStationAnnotation *updatedAnnotation;
    if (updatedStation) {
        updatedAnnotation = [[GoStationAnnotation alloc] initWithGoStation:updatedStation];
    }
    
    return updatedAnnotation;
}

- (NSArray *)getGoStations {
    
    NSMutableArray *annotations = [NSMutableArray array];
    
    RLMResults<GoStation *> *stations;
    if ([self isShowDeprecatedStation]) {
        stations = [self.persistencyManager queryGoStationWithWithPredicate:nil];
    } else {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"state != %d", GoStationStatusDeprecated];
        stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    }

    
    if (stations.count > 0) {
        for (GoStation *s in stations) {
            GoStationAnnotation *annotation = [[GoStationAnnotation alloc] initWithGoStation:s];
            [annotations addObject:annotation];
        }
    }
    
    return [NSArray arrayWithArray:annotations];
}

- (NSArray *)getGoChargers {
    NSMutableArray *goChargers = [NSMutableArray array];
    RLMResults<GoCharger *> *chargers;
    chargers = [self.persistencyManager queryGoChargerWithWithPredicate:nil];
    if (chargers.count > 0) {
        for (GoCharger *c in chargers) {
            GoChargerAnnotation *goCharger = [[GoChargerAnnotation alloc] initWithUUID:c.uuid
                                                                                 Phone:c.phone_num
                                                                              Homepage:c.homepage
                                                                           ChargerName:@{@"en": c.name_eng,
                                                                                         @"zh": c.name_cht}
                                                                               Address:@{@"en": c.address_eng,
                                                                                         @"zh": c.address_cht}
                                                                                  City:@{@"en": c.city_eng,
                                                                                         @"zh": c.city_cht}
                                                                              District:@{@"en": c.district_eng,
                                                                                         @"zh": c.district_cht}
                                                                              Latitude:c.latitude
                                                                             Longitude:c.longitude];
            [goChargers addObject:goCharger];
        }
    }
    return [NSArray arrayWithArray:goChargers];
}

- (NSUInteger)totalCheckedInCount {
    // Not counting the deprecated stations
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"is_checkin == true && state != %d", GoStationStatusDeprecated];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    return stations.count;
}

- (NSUInteger)workingGoStationCount {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"state == %d", GoStationStatusNormal];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    return stations.count;
}

- (NSUInteger)closedGoStationCount {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"state == %d", GoStationStatusClosed];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    return stations.count;
}

- (NSUInteger)constructingGoStationCount {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"state == %d OR state == %d", GoStationStatusConstructing, GoStationStatusPreparing];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    return stations.count;
}

- (NSDate * _Nullable )firstCheckinDate {
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"is_checkin == true"];
    RLMResults<GoStation *> *stations = [[self.persistencyManager queryGoStationWithWithPredicate:pred] sortedResultsUsingProperty:@"checkin_date" ascending:YES];
    
    return stations.count > 0 ? [stations firstObject].checkin_date : nil;
}

- (NSDate * _Nullable )latestCheckinDate {
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"is_checkin == true"];
    RLMResults<GoStation *> *stations = [[self.persistencyManager queryGoStationWithWithPredicate:pred] sortedResultsUsingProperty:@"last_checkin_date" ascending:NO];
    
    return stations.count > 0 ? [stations firstObject].last_checkin_date : nil;
}

- (void)initUserDefaultsIfNeeded {
    [self.persistencyManager createUserDefaultsWithMap:AppleMap showDeprecated:NO interval:3];
}

- (void)changeDefaultMapToApple {
    [self.persistencyManager setDefaultMap:AppleMap];
}

- (void)changeDefaultMapToGoogle {
    [self.persistencyManager setDefaultMap:GoogleMap];
}

- (NSUInteger)currentMapApplication {
    return [self.persistencyManager getDefaultMap];
}

- (void)showDeprecatedStation:(BOOL)isShow {
    [self.persistencyManager setShowDeprecated:isShow];
}

- (BOOL)isShowDeprecatedStation {
    return [self.persistencyManager getShowDeprecated];
}

- (void)changeUpdateInterval:(NSInteger)interval {
    [self.persistencyManager setUpdateInterval:interval];
}

- (NSInteger)updateInterval {
    return [self.persistencyManager getUpdateInterval];
}

- (void)_updateGoStationWithGroup:(dispatch_group_t)requestGroup {
    if (requestGroup) {
        dispatch_group_enter(requestGroup);
    }
    
    // Request GoStation from GOGORO API server.
    [self.httpClient getRequestForStation:@"/vm/list" completion:^(NSDictionary *responseDict, NSError *error) {
        if (!error) {
            //            NSLog(@"%@", responseDict);
            [self.persistencyManager createOrUpdateGoStationWithData:responseDict];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Connection Error" , nil) message:NSLocalizedString(@"Connection Error.", nil) preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:okAction];
                [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController animated:NO completion:nil];
            });
        }
        
        if (requestGroup) {
            dispatch_group_leave(requestGroup);
        }
    }];
}

- (void)_updateGoChargerWithGroup:(dispatch_group_t)requestGroup {
    if (requestGroup) {
        dispatch_group_enter(requestGroup);
    }
    [self.httpClient getRequestForChargerWithCompletion:^(NSDictionary *responseDict, NSError *error) {
        if (!error) {
            NSLog(@"%@", responseDict);
            [self.persistencyManager createOrUpdateGoChargerWithData:responseDict];
        }
        if (requestGroup) {
            dispatch_group_leave(requestGroup);
        }
    }];
}

- (BOOL)_dataUpdateNeeded {
    
    BOOL flag = NO;
    
    // Calculate if data needs to be updated.
    long long lastThreshold = [[NSDate date] timeIntervalSince1970];
    lastThreshold = lastThreshold - (60 * (60 * [self updateInterval]));
    
    // Retrive all Station, if theres no station data then it'll return 0.
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"state == %d", GoStationStatusNormal];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    
    if (stations.count > 0) {
        // If there is data, check if data is needed to update.
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"state == %d && update_time <= %i", GoStationStatusNormal, lastThreshold];
        stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
        
        if (stations.count > 0) {
            flag = YES;
        }
        
    } else {
        // The data is empty update.
        flag = YES;
    }
    
    return flag;
}

@end
