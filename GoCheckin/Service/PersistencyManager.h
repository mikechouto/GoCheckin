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

- (void)createUserDefaultsWithMap:(NSUInteger)type showDeprecated:(BOOL)isShow interval:(NSInteger)interval;
- (void)setShowDeprecated:(BOOL)isShow;
- (void)setDefaultMap:(NSUInteger)type;
- (void)setUpdateInterval:(NSInteger)interval;
- (BOOL)getShowDeprecated;
- (NSUInteger)getDefaultMap;
- (NSInteger)getUpdateInterval;
- (void)createOrUpdateGoStationWithData:(id)stationData;
- (RLMResults<GoStation *> *)queryGoStationWithWithPredicate:(NSPredicate *)predicate;
- (GoStation *)updateCheckInDataWithUUID:(NSString *)uuid;
- (GoStation *)removeCheckInDataWithUUID:(NSString *)uuid;

@end
