//
//  APIManager.h
//  GoCheckin
//
//  Created by Mike Chou on 4/11/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class GoStationAnnotation;

@interface APIManager : NSObject

+ (APIManager *)sharedInstance;
- (void)updateEnergyNetworkIfNeeded;
- (void)updateEnergyNetwork;
- (GoStationAnnotation *)updateCheckInDataWithStationUUID:(NSString *)uuid;
- (GoStationAnnotation *)removeCheckInDataWithStationUUID:(NSString *)uuid;
- (NSArray *)getGoStations;
- (NSUInteger)totalCheckedInCount;
- (NSUInteger)workingGoStationCount;
- (NSUInteger)closedGoStationCount;
- (NSUInteger)constructingGoStationCount;
- (NSDate * _Nullable)firstCheckinDate;
- (NSDate * _Nullable)latestCheckinDate;

- (void)initUserDefaultsIfNeeded;
- (void)changeDefaultMapToGoogle;
- (void)changeDefaultMapToApple;
- (NSUInteger)currentMapApplication;
- (void)showDeprecatedStation:(BOOL)isShow;
- (BOOL)isShowDeprecatedStation;
- (void)changeUpdateInterval:(NSInteger)interval;
- (NSInteger)updateInterval;

NS_ASSUME_NONNULL_END

@end
