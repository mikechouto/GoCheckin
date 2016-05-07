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

@class GoStation;

@interface PersistencyManager : NSObject

- (void)createOrUpdateGoStationWithData:(NSDictionary *)stationDict;
- (void)updateCheckInDataWithUUID:(NSString *)uuid;
- (void)removeCheckInDataWithUUID:(NSString *)uuid;
- (RLMResults<GoStation *> *)queryGoStationWithWithPredicate:(NSPredicate *)predicate;

- (void)initUserDefaultsWithDefaultMapType:(NSUInteger)type;
- (void)changeDefaultMapInUserDefaultsWithMapType:(NSUInteger)type;
- (NSUInteger)getCurrentDefaultMap;

@end
