//
//  PersistencyManager.m
//  GoCheckin
//
//  Created by Mike Chou on 4/11/16.
//
//

#import "PersistencyManager.h"
#import "NSJSONSerialization+ParseString.h"


// Gogoro API General Keys
static NSString *const kResponseKeyList = @"List";
static NSString *const kResponseKeyValue = @"Value";
static NSString *const kResponseKeyLanguage = @"Lang";
static NSString *const kResponseValueEnglish = @"en-US";
static NSString *const kResponseValueChinese = @"zh-TW";

static NSString *const kResponseKeyUUID = @"Id";
static NSString *const kResponseKeyCity = @"City";
static NSString *const kResponseKeyState = @"State";
static NSString *const kResponseKeyName = @"LocName";
static NSString *const kResponseKeyAddress = @"Address";
static NSString *const kResponseKeyDistrict = @"District";
static NSString *const kResponseKeyLatitude = @"Latitude";
static NSString *const kResponseKeyLongitude = @"Longitude";
static NSString *const kResponseKeyAvailableTime = @"AvailableTime";

// Station Specific Keys
static NSString *const kResponseKeyZip = @"ZipCode";
static NSString *const kResponseKeyStatus = @"result";
static NSString *const kResponseKeyStationContent = @"data";
static NSString *const kResponseKeyAvailableTimeByte = @"AvailableTimeByte"; // Not used


// Charger Specific Keys
static NSString *const kResponseKeyUrl = @"Url";
static NSString *const kResponseKeyPhoneNumber = @"Phone";
static NSString *const kResponseKeyChargerGeoPoint = @"GeoPoint";
static NSString *const kResponseKeyChargerContent = @"PublicHcDataList";

// NSUserDefaults Keys
static NSString *const kFirstRunDate = @"initTimestamp";
static NSString *const kUpdateInterval = @"updateInterval";
static NSString *const kDefaultMapApplication = @"defaultMap";
static NSString *const kIsShowDeprecatedStation = @"isShowDeprecated";

@implementation PersistencyManager

#pragma mark GoStation
- (void)createOrUpdateGoStationWithData:(NSDictionary *)dictionary {
    
    if ([[dictionary objectForKey:kResponseKeyStatus] boolValue]) {
        
        NSArray *stationDicts = [dictionary objectForKey:kResponseKeyStationContent];
        if (stationDicts.count > 0) {
            // Create realm pointing to default file which was set in AppDelegate.
            RLMRealm *realm = [RLMRealm defaultRealm];
            long long update_time = [[NSDate date] timeIntervalSince1970];
            
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
            
            [self checkStationState];
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

- (nonnull NSDictionary *)parseLocNameWithDictionary:(NSDictionary *)dictionary {
    
    NSDictionary *nameDict = [NSJSONSerialization JSONObjectWithString:[dictionary objectForKey:kResponseKeyName]
                                                               options:kNilOptions error:nil];
    id nameArray = [nameDict objectForKey:kResponseKeyList];
    return [self parseMultipleLanguageDataWithArray:nameArray];
}

- (nonnull NSDictionary *)parseAddressWithDictionary:(NSDictionary *)dictionary {
    NSDictionary *addressDict = [NSJSONSerialization JSONObjectWithString:[dictionary objectForKey:kResponseKeyAddress]
                                                                  options:kNilOptions error:nil];
    id addressArray = [addressDict objectForKey:kResponseKeyList];
    return [self parseMultipleLanguageDataWithArray:addressArray];
}

- (nonnull NSDictionary *)parseCityWithDictionary:(NSDictionary *)dictionary {
    NSDictionary *cityDict = [NSJSONSerialization JSONObjectWithString:[dictionary objectForKey:kResponseKeyCity]
                                                               options:kNilOptions error:nil];
    id cityArray = [cityDict objectForKey:kResponseKeyList];
    return [self parseMultipleLanguageDataWithArray:cityArray];
}

- (nonnull NSDictionary *)parseDistrictWithDictionary:(NSDictionary *)dictionary {
    NSDictionary *districtDict = [NSJSONSerialization JSONObjectWithString:[dictionary objectForKey:kResponseKeyDistrict]
                                                                   options:kNilOptions error:nil];
    
    id districtArray = [districtDict objectForKey:kResponseKeyList];
    return [self parseMultipleLanguageDataWithArray:districtArray];
}

- (nonnull NSDictionary *)parseMultipleLanguageDataWithArray:(NSArray *)array {
    NSMutableDictionary *tempDict;
    if (array && [array isKindOfClass:[NSArray class]]) {
        tempDict = [NSMutableDictionary dictionaryWithCapacity:[array count]];
        for (id data in array) {
            
            if ([data isKindOfClass:[NSDictionary class]]) {
                if ([[data objectForKey:kResponseKeyLanguage] isEqualToString:kResponseValueEnglish]) {
                    [tempDict setObject:[data objectForKey:kResponseKeyValue] forKey:kResponseValueEnglish];
                }
                
                if ([[data objectForKey:kResponseKeyLanguage] isEqualToString:kResponseValueChinese]) {
                    [tempDict setObject:[data objectForKey:kResponseKeyValue] forKey:kResponseValueChinese];
                }
            }
        }
    }
    return [NSDictionary dictionaryWithDictionary:tempDict];
}

#pragma mark GoCharger
- (void)createOrUpdateGoChargerWithData:(NSDictionary *)dictionary {
    NSArray *chargerDicts = [dictionary objectForKey:kResponseKeyChargerContent];
    if (chargerDicts.count > 0) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        long long update_time = [[NSDate date] timeIntervalSince1970];
        
        for (NSDictionary *chargerDict in chargerDicts) {
            
            NSString *uuid = [chargerDict objectForKey:kResponseKeyUUID];
            NSString *available_time = [chargerDict objectForKey:kResponseKeyAvailableTime];
            
            // Name
            NSDictionary *nameDict = [self parseLocNameWithDictionary:chargerDict];
            NSString *name_eng = [nameDict objectForKey:kResponseValueEnglish];
            NSString *name_cht = [nameDict objectForKey:kResponseValueChinese];

            
            // Address
            NSDictionary *addressDict = [self parseAddressWithDictionary:chargerDict];
            NSString *address_eng = [addressDict objectForKey:kResponseValueEnglish];
            NSString *address_cht = [addressDict objectForKey:kResponseValueChinese];
            
            // City
            NSDictionary *cityDict = [self parseCityWithDictionary:chargerDict];
            NSString *city_eng = [cityDict objectForKey:kResponseValueEnglish];
            NSString *city_cht = [cityDict objectForKey:kResponseValueChinese];
            
            
            // District
            NSDictionary *districtDict = [self parseDistrictWithDictionary:chargerDict];
            NSString *district_eng = [districtDict objectForKey:kResponseValueEnglish];
            NSString *district_cht = [districtDict objectForKey:kResponseValueChinese];
            
            double latitude = 0, longitude = 0;
            int state;
            
            NSDictionary *geoPoint = [chargerDict objectForKey:kResponseKeyChargerGeoPoint];
            if (geoPoint) {
                if ([[geoPoint objectForKey:kResponseKeyLatitude] isKindOfClass:[NSNumber class]]) {
                    latitude = [[geoPoint objectForKey:kResponseKeyLatitude] doubleValue];
                }
                
                if ([[geoPoint objectForKey:kResponseKeyLongitude] isKindOfClass:[NSNumber class]]) {
                    longitude = [[geoPoint objectForKey:kResponseKeyLongitude] doubleValue];
                }
            }
            
            if ([[chargerDict objectForKey:kResponseKeyState] isKindOfClass:[NSNumber class]]) {
                state = [[chargerDict objectForKey:kResponseKeyState] intValue];
            }
            
            NSString *phone_number = [chargerDict objectForKey:kResponseKeyPhoneNumber];
            NSString *homepage = [chargerDict objectForKey:kResponseKeyUrl];
            
            // Create or update your object
            [realm beginWriteTransaction];
            [GoCharger createInDefaultRealmWithValue:@{@"uuid": uuid,
                                                       @"update_time": @(update_time),
                                                       @"name_eng": name_eng,
                                                       @"name_cht": name_cht,
                                                       @"latitude": @(latitude),
                                                       @"longitude": @(longitude),
                                                       @"state": @(state),
                                                       @"address_eng": address_eng,
                                                       @"address_cht": address_cht,
                                                       @"city_eng": city_eng,
                                                       @"city_cht": city_cht,
                                                       @"district_eng": district_eng,
                                                       @"district_cht": district_cht,
                                                       @"available_time": available_time,
                                                       @"phone_num": phone_number,
                                                       @"homepage": homepage
                                                       }];
            [realm commitWriteTransaction];
        }
        NSLog(@"Charger finishtf");
    }
}

- (RLMResults<GoCharger *> *)queryGoChargerWithWithPredicate:(NSPredicate *)predicate {
    return nil;
}

#pragma mark NSUserDefaults
- (void)initUserDefaultsWithDefaultValuesMapType:(NSUInteger)type isShowDeprecatedStation:(BOOL)isShow updateInterval:(NSInteger)interval {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // version 1.0
    if (![userDefaults objectForKey:kFirstRunDate]) {
        [userDefaults setInteger:[[NSDate date] timeIntervalSince1970] forKey:kFirstRunDate];
        [userDefaults setInteger:type forKey:kDefaultMapApplication];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // version 1.1
    if (![userDefaults objectForKey:kIsShowDeprecatedStation] || ![userDefaults objectForKey:kUpdateInterval]) {
        [userDefaults setBool:isShow forKey:kIsShowDeprecatedStation];
        [userDefaults setInteger:interval forKey:kUpdateInterval];
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

- (void)changeIsShowDeprecatedStationInUserDefault:(BOOL)isShow {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:isShow forKey:kIsShowDeprecatedStation];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)getIsShowDeprecatedStation {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:kIsShowDeprecatedStation];
}

- (void)changeUpdateIntervalInUserDefault:(NSInteger)interval {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (interval == 1 || interval == 3 || interval == 6) {
        [userDefaults setInteger:interval forKey:kUpdateInterval];
    } else {
        [userDefaults setInteger:3 forKey:kUpdateInterval];
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)getUpdateInterval {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger interval = [userDefaults integerForKey:kUpdateInterval];
    
    if (interval == 1 || interval == 3 || interval == 6) {
        return [userDefaults integerForKey:kUpdateInterval];
    } else {
        return 3;
    }

}

#pragma mark - Private Functions
- (void)checkStationState {
    [self updateWorkingStationState];
    [self updateDeprecatedStationState];
    [self removeDeprecatedConstructingStation];
}

- (void)updateWorkingStationState {
    RLMResults<GoStation *> *stations = [GoStation objectsWhere:@"state == 1 && online_time == 0"];
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        for (GoStation *station in stations) {
            station.online_time = @(round([[NSDate date] timeIntervalSince1970]));
        }
    }];
    
    // Check if deprecated stations comes alive again
    stations = [GoStation objectsWhere:@"state == 1 && offline_time > 0"];
    if (stations.count > 0) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            for (GoStation *station in stations) {
                station.offline_time = @(0);
            }
        }];
    }
}

- (void)updateDeprecatedStationState {
    
    // Make depercated GoStation threshold to be 5 days.
    long long depercatedThreshold = [[NSDate date] timeIntervalSince1970];
    depercatedThreshold = depercatedThreshold - (60 * (60 * 24) * 5);
    
    RLMResults<GoStation *> *stations = [GoStation objectsWhere:@"online_time > 0 && offline_time == 0 && update_time <= %i", depercatedThreshold];
    if (stations.count > 0) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            for (GoStation *station in stations) {
                station.offline_time = @(station.update_time);
                station.state = 997; // GoStationStatusDeprecated
            }
        }];
    }
}

- (void)removeDeprecatedConstructingStation {
    
    // Make depercated GoStation threshold to be 5 days.
    long long depercatedThreshold = [[NSDate date] timeIntervalSince1970];
    depercatedThreshold = depercatedThreshold - (60 * (60 * 24) * 5);

    RLMResults<GoStation *> *stations = [GoStation objectsWhere:@"state != 1 && online_time == 0 && update_time <= %i", depercatedThreshold];
    
    if (stations.count > 0) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        
        [realm transactionWithBlock:^{
            [realm deleteObjects:stations];
        }];
    }
}

@end
