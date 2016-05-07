//
//  APIManager.h
//  GoCheckin
//
//  Created by Mike Chou on 4/11/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class GoStationAnnotation;

@interface APIManager : NSObject

+ (APIManager *)sharedInstance;
- (void)updateGoStationIfNeeded;
- (void)updateGoStation;
- (GoStationAnnotation *)updateCheckInDataWithStationUUID:(NSString *)uuid;
- (GoStationAnnotation *)removeCheckInDataWithStationUUID:(NSString *)uuid;
- (NSArray *)getGoStations;

- (void)initUserDefaultsIfNeeded;
- (void)changeDefaultMapToGoogle;
- (void)changeDefaultMapToApple;
- (NSUInteger)currentDefaultMapApplication;

@end
