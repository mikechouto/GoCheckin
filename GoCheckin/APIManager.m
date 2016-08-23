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

- (void)updateGoStationIfNeeded {
    [self updateGoCharger];
    if ([self dataUpdateNeeded]) {
        [self updateGoStation];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GoStationUpdateFinishNotification" object:nil];
    }
}

- (void)updateGoStation {
    
    // Request GoStation from GOGORO API server.
    [self.httpClient getRequestForStation:@"/vm/list" completion:^(NSDictionary *responseDict, NSError *error) {
        if (!error) {
//            NSLog(@"%@", responseDict);
            [self.persistencyManager createOrUpdateGoStationWithData:responseDict];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GoStationUpdateFinishNotification" object:nil];
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Connection Error" , nil) message:NSLocalizedString(@"Connection Error.", nil) preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:okAction];
                [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController animated:NO completion:nil];
            });
        }
    }];
}

- (void)updateGoCharger {
    [self.httpClient getRequestForChargerWithCompletion:^(NSDictionary *responseDict, NSError *error) {
        if (!error) {
            NSLog(@"%@", responseDict);
        }
    }];
}

- (GoStationAnnotation *)updateCheckInDataWithStationUUID:(NSString *)uuid {
    [self.persistencyManager updateCheckInDataWithUUID:uuid];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    
    GoStation *s = [stations firstObject];
    GoStationAnnotation *goStation;
    if (s) {
        goStation = [[GoStationAnnotation alloc] initWithUUID:s.uuid
                                                   StationName:@{@"en": s.name_eng,
                                                                 @"zh": s.name_cht}
                                                       Address:@{@"en": s.address_eng,
                                                                 @"zh": s.address_cht}
                                                          City:@{@"en": s.city_eng,
                                                                 @"zh": s.city_cht}
                                                      District:@{@"en": s.district_eng,
                                                                 @"zh": s.district_cht}
                                                       ZipCode:s.zip_code
                                                 AvailableTime:s.available_time
                                                      Latitude:s.latitude
                                                     Longitude:s.longitude
                                                         Status:s.state
                                                     isCheckIn:s.is_checkin
                                                  checkInTimes:[s.checkin_times integerValue]
                                               lastCheckInDate:s.last_checkin_date];
    }
    
    return goStation;
}

- (GoStationAnnotation *)removeCheckInDataWithStationUUID:(NSString *)uuid {
    [self.persistencyManager removeCheckInDataWithUUID:uuid];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    
    GoStation *s = [stations firstObject];
    GoStationAnnotation *goStation;
    if (s) {
        goStation = [[GoStationAnnotation alloc] initWithUUID:s.uuid
                                                  StationName:@{@"en": s.name_eng,
                                                                @"zh": s.name_cht}
                                                      Address:@{@"en": s.address_eng,
                                                                @"zh": s.address_cht}
                                                         City:@{@"en": s.city_eng,
                                                                @"zh": s.city_cht}
                                                     District:@{@"en": s.district_eng,
                                                                @"zh": s.district_cht}
                                                      ZipCode:s.zip_code
                                                AvailableTime:s.available_time
                                                     Latitude:s.latitude
                                                    Longitude:s.longitude
                                                        Status:s.state
                                                    isCheckIn:s.is_checkin
                                                 checkInTimes:[s.checkin_times integerValue]
                                              lastCheckInDate:s.last_checkin_date];
    }
    
    return goStation;
}

- (NSArray *)getGoStations {
    
    NSMutableArray *goStations = [NSMutableArray array];
    
    RLMResults<GoStation *> *stations;
    if ([self shouldShowDeprecatedStation]) {
        stations = [self.persistencyManager queryGoStationWithWithPredicate:nil];
    } else {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"state != %d", GoStationStatusDeprecated];
        stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    }

    
    if (stations.count > 0) {
        for (GoStation *s in stations) {
            GoStationAnnotation *goStation = [[GoStationAnnotation alloc] initWithUUID:s.uuid
                                                       StationName:@{@"en": s.name_eng,
                                                                     @"zh": s.name_cht}
                                                           Address:@{@"en": s.address_eng,
                                                                     @"zh": s.address_cht}
                                                              City:@{@"en": s.city_eng,
                                                                     @"zh": s.city_cht}
                                                          District:@{@"en": s.district_eng,
                                                                     @"zh": s.district_cht}
                                                           ZipCode:s.zip_code
                                                     AvailableTime:s.available_time
                                                          Latitude:s.latitude
                                                         Longitude:s.longitude
                                                             Status:s.state
                                                         isCheckIn:s.is_checkin
                                                      checkInTimes:[s.checkin_times integerValue]
                                                   lastCheckInDate:s.last_checkin_date];
            [goStations addObject:goStation];
        }
    }
    
    return goStations;
}

- (NSUInteger)getTotalCheckedInCount {
    // Not counting the deprecated stations
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"is_checkin == true && state != %d", GoStationStatusDeprecated];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    return stations.count;
}

- (NSUInteger)getWorkingGoStationCount {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"state == %d", GoStationStatusNormal];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    return stations.count;
}

- (NSUInteger)getClosedGoStationCount {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"state == %d", GoStationStatusClosed];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    return stations.count;
}

- (NSUInteger)getConstructingGoStationCount {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"state == %d OR state == %d", GoStationStatusConstructing, GoStationStatusPreparing];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    return stations.count;
}

- (NSDate * _Nullable ) getFirstCheckinDate {
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"is_checkin == true"];
    RLMResults<GoStation *> *stations = [[self.persistencyManager queryGoStationWithWithPredicate:pred] sortedResultsUsingProperty:@"checkin_date" ascending:YES];
    
    return stations.count > 0 ? [stations firstObject].checkin_date : nil;
}

- (NSDate * _Nullable ) getLatestCheckinDate {
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"is_checkin == true"];
    RLMResults<GoStation *> *stations = [[self.persistencyManager queryGoStationWithWithPredicate:pred] sortedResultsUsingProperty:@"last_checkin_date" ascending:NO];
    
    return stations.count > 0 ? [stations firstObject].last_checkin_date : nil;
}

- (void)initUserDefaultsIfNeeded {
    [self.persistencyManager initUserDefaultsWithDefaultValuesMapType:MapTypeApple isShowDeprecatedStation:NO updateInterval:3];
}

- (void)changeDefaultMapToApple {
    [self.persistencyManager changeDefaultMapInUserDefaultsWithMapType:MapTypeApple];
}

- (void)changeDefaultMapToGoogle {
    [self.persistencyManager changeDefaultMapInUserDefaultsWithMapType:MapTypeGoogle];
}

- (NSUInteger)currentMapApplication {
    return [self.persistencyManager getCurrentDefaultMap];
}

- (void)changeShowDeprecatedStation:(BOOL)isShow {
    [self.persistencyManager changeIsShowDeprecatedStationInUserDefault:isShow];
}

- (BOOL)shouldShowDeprecatedStation {
    return [self.persistencyManager getIsShowDeprecatedStation];
}

- (void)changeUpdateInterval:(NSInteger)interval {
    [self.persistencyManager changeUpdateIntervalInUserDefault:interval];
}

- (NSInteger)currentUpdateInterval {
    return [self.persistencyManager getUpdateInterval];
}

#pragma mark internal functions

- (BOOL)dataUpdateNeeded {
    
    BOOL flag = NO;
    
    // Calculate if data needs to be updated.
    long long lastThreshold = [[NSDate date] timeIntervalSince1970];
    lastThreshold = lastThreshold - (60 * (60 * [self currentUpdateInterval]));
    
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
