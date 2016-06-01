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
- (void)updateGoStationIfNeeded;
- (void)updateGoStation;
- (GoStationAnnotation *)updateCheckInDataWithStationUUID:(NSString *)uuid;
- (GoStationAnnotation *)removeCheckInDataWithStationUUID:(NSString *)uuid;
- (NSArray *)getGoStations;
- (NSUInteger)getTotalCheckedInCount;
- (NSUInteger)getWorkingGoStationCount;
- (NSUInteger)getClosedGoStationCount;
- (NSUInteger)getConstructingGoStationCount;
- (NSDate * _Nullable)getFirstCheckinDate;
- (NSDate * _Nullable)getLatestCheckinDate;

- (void)initUserDefaultsIfNeeded;
- (void)changeDefaultMapToGoogle;
- (void)changeDefaultMapToApple;
- (NSUInteger)currentDefaultMapApplication;

NS_ASSUME_NONNULL_END

@end
