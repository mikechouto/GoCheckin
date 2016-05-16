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
    if ([self dataUpdateNeeded]) {
        [self updateGoStation];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GoStationUpdateFinishNotification" object:nil];
    }
}

- (void)updateGoStation {
    
    // Request GoStation from GOGORO API server.
    [self.httpClient getRequest:@"/vm/list" completion:^(NSDictionary *responseDict, NSError *error) {
        if (!error) {
            NSLog(@"%@", responseDict);
            [self.persistencyManager createOrUpdateGoStationWithData:responseDict];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GoStationUpdateFinishNotification" object:nil];
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Connection Error" , nil) message:NSLocalizedString(@"Connection Error.", nil) preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:cancelAction];
                [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController animated:NO completion:nil];
            });
        }
    }];
}

- (GoStationAnnotation *)updateCheckInDataWithStationUUID:(NSString *)uuid {
    [self.persistencyManager updateCheckInDataWithUUID:uuid];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"uuid==%@", uuid];
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
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"uuid==%@", uuid];
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
    
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:nil];
    
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
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"is_checkin==true"];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    return stations.count;
}

- (NSUInteger)getWorkingGoStationCount {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"state==%d", GoStationStatusNormal];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    return stations.count;
}

- (NSUInteger)getClosedGoStationCount {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"state==%d", GoStationStatusClosed];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    return stations.count;
}

- (NSUInteger)getConstructingGoStationCount {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"state==%d", GoStationStatusConstructing];
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:pred];
    return stations.count;
}

- (void)initUserDefaultsIfNeeded {
    [self.persistencyManager initUserDefaultsWithDefaultMapType:MapTypeApple];
}

- (void)changeDefaultMapToApple {
    [self.persistencyManager changeDefaultMapInUserDefaultsWithMapType:MapTypeApple];
}

- (void)changeDefaultMapToGoogle {
    [self.persistencyManager changeDefaultMapInUserDefaultsWithMapType:MapTypeGoogle];
}

- (NSUInteger)currentDefaultMapApplication {
    return [self.persistencyManager getCurrentDefaultMap];
}

#pragma mark internal functions

- (BOOL)dataUpdateNeeded {
    
    BOOL flag = NO;
    
    // Make the threshold to be 3 hr.
    long long lastThreshold = [[NSDate date] timeIntervalSince1970];
    lastThreshold = lastThreshold - (60 * (60 * 3));
    
    // Retrive all Station, if theres no station data then it'll return 0.
    RLMResults<GoStation *> *stations = [self.persistencyManager queryGoStationWithWithPredicate:nil];
    
    if (stations.count > 0) {
        // If there is data, check if data is needed to update.
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"update_time <= %i", lastThreshold];
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
