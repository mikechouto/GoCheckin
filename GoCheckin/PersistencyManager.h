//
//  PersistencyManager.h
//  GoCheckin
//
//  Created by Mike Chou on 4/11/16.
//
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>
#import "GoStation.h"
#import "GoCharger.h"

@class GoStation;

@interface PersistencyManager : NSObject

- (void)initUserDefaultsWithDefaultValuesMapType:(NSUInteger)type isShowDeprecatedStation:(BOOL)isShow updateInterval:(NSInteger)interval;
- (void)changeIsShowDeprecatedStationInUserDefault:(BOOL)isShow;
- (void)changeDefaultMapInUserDefaultsWithMapType:(NSUInteger)type;
- (void)changeUpdateIntervalInUserDefault:(NSInteger)interval;
- (BOOL)getIsShowDeprecatedStation;
- (NSUInteger)getCurrentDefaultMap;
- (NSInteger)getUpdateInterval;
- (void)createOrUpdateGoStationWithData:(NSDictionary *)dictionary;
- (void)createOrUpdateGoChargerWithData:(NSDictionary *)dictionary;
- (RLMResults<GoStation *> *)queryGoStationWithWithPredicate:(NSPredicate *)predicate;
- (RLMResults<GoCharger *> *)queryGoChargerWithWithPredicate:(NSPredicate *)predicate;
- (void)updateCheckInDataWithUUID:(NSString *)uuid;
- (void)removeCheckInDataWithUUID:(NSString *)uuid;



@end
