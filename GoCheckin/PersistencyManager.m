//
//  PersistencyManager.m
//  GoCheckin
//
//  Created by Mike Chou on 4/11/16.
//
//

#import "PersistencyManager.h"
#import "NSJSONSerialization+ParseString.h"


// Gogoro API Keys
static NSString *const kResponseKeyStatus = @"result";
static NSString *const kResponseKeyContent = @"data";

static NSString *const kResponseKeyList = @"List";
static NSString *const kResponseKeyValue = @"Value";
static NSString *const kResponseKeyLanguage = @"Lang";
static NSString *const kResponseValueEnglish = @"en-US";
static NSString *const kResponseValueChinese = @"zh-TW";

static NSString *const kResponseKeyUUID = @"Id";
static NSString *const kResponseKeyAvailableTime = @"AvailableTime";
static NSString *const kResponseKeyAvailableTimeByte = @"AvailableTimeByte"; // Not used
static NSString *const kResponseKeyName = @"LocName";
static NSString *const kResponseKeyAddress = @"Address";
static NSString *const kResponseKeyCity = @"City";
static NSString *const kResponseKeyDistrict = @"District";
static NSString *const kResponseKeyLatitude = @"Latitude";
static NSString *const kResponseKeyLongitude = @"Longitude";
static NSString *const kResponseKeyZip = @"ZipCode";
static NSString *const kResponseKeyState = @"State";

// NSUserDefaults Keys
static NSString *const kFirstRunDate = @"initTimestamp";
static NSString *const kDefaultMapApplication = @"defaultMap";

@implementation PersistencyManager

- (void)createOrUpdateGoStationWithData:(NSDictionary *)stationDict {
    
    if ([[stationDict objectForKey:kResponseKeyStatus] boolValue]) {
        
        NSArray *stationDicts = [stationDict objectForKey:kResponseKeyContent];
        if (stationDicts.count > 0) {
            // Create realm pointing to default file which was set in AppDelegate.
            RLMRealm *realm = [RLMRealm defaultRealm];
            
            for (NSDictionary *stationDict in stationDicts) {
                
                
                NSString *uuid = [stationDict objectForKey:kResponseKeyUUID];
                NSString *available_time = [stationDict objectForKey:kResponseKeyAvailableTime];
                
                // Name
                NSString *name_eng, *name_cht;
                NSDictionary *nameDict = [NSJSONSerialization JSONObjectWithString:[stationDict objectForKey:kResponseKeyName]
                                                                         options:kNilOptions error:nil];
                if ([[nameDict objectForKey:kResponseKeyList] isKindOfClass:[NSArray class]]) {
                    NSArray *nameArray = [nameDict objectForKey:kResponseKeyList];
                    for (id name in nameArray) {
                        if ([name isKindOfClass:[NSDictionary class]]) {
                            
                            if ([[name objectForKey:kResponseKeyLanguage] isEqualToString:kResponseValueEnglish]) {
                                name_eng = [name objectForKey:kResponseKeyValue];
                            }
                            
                            if ([[name objectForKey:kResponseKeyLanguage] isEqualToString:kResponseValueChinese]) {
                                name_cht = [name objectForKey:kResponseKeyValue];
                            }
                        }
                    }
                }
                
                // Address
                NSString *address_eng, *address_cht;
                NSDictionary *addressDict = [NSJSONSerialization JSONObjectWithString:[stationDict objectForKey:kResponseKeyAddress]
                                                                            options:kNilOptions error:nil];
                if ([[addressDict objectForKey:kResponseKeyList] isKindOfClass:[NSArray class]]) {
                    NSArray *addressArray = [addressDict objectForKey:kResponseKeyList];
                    for (id address in addressArray) {
                        if ([address isKindOfClass:[NSDictionary class]]) {
                            
                            if ([[address objectForKey:kResponseKeyLanguage] isEqualToString:kResponseValueEnglish]) {
                                address_eng = [address objectForKey:kResponseKeyValue];
                            }
                            
                            if ([[address objectForKey:kResponseKeyLanguage] isEqualToString:kResponseValueChinese]) {
                                address_cht = [address objectForKey:kResponseKeyValue];
                            }
                        }
                    }
                }
                
                // City
                NSString *city_eng, *city_cht;
                NSDictionary *cityDict = [NSJSONSerialization JSONObjectWithString:[stationDict objectForKey:kResponseKeyCity]
                                                                         options:kNilOptions error:nil];
                if ([[cityDict objectForKey:kResponseKeyList] isKindOfClass:[NSArray class]]) {
                    NSArray *cityArray = [cityDict objectForKey:kResponseKeyList];
                    for (id city in cityArray) {
                        if ([city isKindOfClass:[NSDictionary class]]) {
                            
                            if ([[city objectForKey:kResponseKeyLanguage] isEqualToString:kResponseValueEnglish]) {
                                city_eng = [city objectForKey:kResponseKeyValue];
                            }
                            
                            if ([[city objectForKey:kResponseKeyLanguage] isEqualToString:kResponseValueChinese]) {
                                city_cht = [city objectForKey:kResponseKeyValue];
                            }
                        }
                    }
                }
                
                // District
                NSString *district_eng, *district_cht;
                NSDictionary *districtDict = [NSJSONSerialization JSONObjectWithString:[stationDict objectForKey:kResponseKeyDistrict]
                                                                             options:kNilOptions error:nil];
                if ([[districtDict objectForKey:kResponseKeyList] isKindOfClass:[NSArray class]]) {
                    NSArray *districtArray = [districtDict objectForKey:kResponseKeyList];
                    for (id district in districtArray) {
                        if ([district isKindOfClass:[NSDictionary class]]) {
                            
                            if ([[district objectForKey:kResponseKeyLanguage] isEqualToString:kResponseValueEnglish]) {
                                district_eng = [district objectForKey:kResponseKeyValue];
                            }
                            
                            if ([[district objectForKey:kResponseKeyLanguage] isEqualToString:kResponseValueChinese]) {
                                district_cht = [district objectForKey:kResponseKeyValue];
                            }
                        }
                    }
                }
                
                double latitude = 0, longitude = 0;
                int zip_code, state;
                
                if ([[stationDict objectForKey:kResponseKeyLatitude] isKindOfClass:[NSNumber class]]) {
                    latitude = [[stationDict objectForKey:kResponseKeyLatitude] doubleValue];
                }
                
                if ([[stationDict objectForKey:kResponseKeyLongitude] isKindOfClass:[NSNumber class]]) {
                    longitude = [[stationDict objectForKey:kResponseKeyLongitude] doubleValue];
                }
                
                if ([[stationDict objectForKey:kResponseKeyZip] isKindOfClass:[NSString class]]) {
                    zip_code = [[stationDict objectForKey:kResponseKeyZip] intValue];
                }
                
                if ([[stationDict objectForKey:kResponseKeyState] isKindOfClass:[NSNumber class]]) {
                    state = [[stationDict objectForKey:kResponseKeyState] intValue];
                }
                
                long long update_time = [[NSDate date] timeIntervalSince1970];
                
                // Create or update your object
                [realm beginWriteTransaction];
                [GoStation createOrUpdateInDefaultRealmWithValue:@{@"uuid": uuid,
                                                                 @"update_time": @(update_time),
                                                                 @"name_eng": name_eng,
                                                                 @"name_cht": name_cht,
                                                                 @"latitude": @(latitude),
                                                                 @"longitude": @(longitude),
                                                                 @"state": @(state),
                                                                 @"zip_code": @(zip_code),
                                                                 @"address_eng": address_eng,
                                                                 @"address_cht": address_cht,
                                                                 @"city_eng": city_eng,
                                                                 @"city_cht": city_cht,
                                                                 @"district_eng": district_eng,
                                                                 @"district_cht": district_cht,
                                                                 @"available_time": available_time
                                                                 }];
                [realm commitWriteTransaction];
            }
            
            [self removeDeprecatedGoStation];
        }
        
    } else {
        NSLog(@"updateGoStationWithStationData: something wrong with response data.");
    }
}

- (void)updateCheckInDataWithUUID:(NSString *)uuid {
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    GoStation *station = [[GoStation objectsWhere:@"uuid==%@",uuid] firstObject];
    [realm beginWriteTransaction];
    
    if (!station.is_checkin) {
        station.is_checkin = YES;
        station.checkin_date = [NSDate date];
    }
    station.last_checkin_date = [NSDate date];
    station.checkin_times = @([station.checkin_times integerValue] + 1);
    
    [realm commitWriteTransaction];
}

- (void)removeCheckInDataWithUUID:(NSString *)uuid {
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    GoStation *station = [[GoStation objectsWhere:@"uuid==%@",uuid] firstObject];
    
    NSInteger checkInTimes = [station.checkin_times integerValue];
    
    if (checkInTimes > 0) {
        
        [realm beginWriteTransaction];
        
        station.last_checkin_date = nil;
        
        checkInTimes--;
        
        station.checkin_times = @(checkInTimes);
        
        if (checkInTimes == 0) {
            station.is_checkin = NO;
            station.checkin_date = nil;
        }
        
        [realm commitWriteTransaction];
    }
    
}

- (RLMResults<GoStation *> *)queryGoStationWithWithPredicate:(NSPredicate *)predicate {
    
    // passing a nil predicate will result in returning all the Station data.
    
    RLMResults<GoStation *> *stations;
    if (predicate) {
        stations = [GoStation objectsWithPredicate:predicate];
    } else {
        stations = [GoStation allObjects];
    }
    
    return stations;
}

- (void)initUserDefaultsWithDefaultMapType:(NSUInteger)type {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (![userDefaults objectForKey:kFirstRunDate]) {
        [userDefaults setInteger:[[NSDate date] timeIntervalSince1970] forKey:kFirstRunDate];
        [userDefaults setInteger:type forKey:kDefaultMapApplication];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)changeDefaultMapInUserDefaultsWithMapType:(NSUInteger)type {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:type forKey:kDefaultMapApplication];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUInteger)getCurrentDefaultMap {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:kDefaultMapApplication];
}

#pragma mark - Private Functions
- (void)removeDeprecatedGoStation {
    
    // Make depercated GoStation threshold to be 2 days.
    long long depercatedThreshold = [[NSDate date] timeIntervalSince1970];
    depercatedThreshold = depercatedThreshold - (60 * (60 * 48));

    RLMResults<GoStation *> *stations = [GoStation objectsWhere:@"update_time <= %i && is_checkin ==  0 && state != 1", depercatedThreshold];
    
    if (stations.count > 0) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        
        [realm transactionWithBlock:^{
            [realm deleteObjects:stations];
        }];
    }
}

@end
