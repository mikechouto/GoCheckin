//
//  GoStation.h
//  GoCheckin
//
//  Created by Mike Chou on 4/7/16.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

typedef NS_ENUM(NSUInteger, GoStationState) {
    GoStationStateNormal = 1,
    GoStationStateClosed = 996,
    GoStationStateConstructing = 99,
    GoStationStateUnknown = -1,
};

@interface GoStationAnnotation : NSObject<MKAnnotation>

@property (strong, nonatomic, readonly) NSString *uuid;
@property (strong, nonatomic, readonly) NSDictionary *name;
@property (assign, nonatomic, readonly) double latitude;
@property (assign, nonatomic, readonly) double longitude;
@property (assign, nonatomic, readonly) GoStationState state;
@property (assign, nonatomic, readonly) NSUInteger zipCode;
@property (strong, nonatomic, readonly) NSDictionary *address;
@property (strong, nonatomic, readonly) NSDictionary *city;
@property (strong, nonatomic, readonly) NSDictionary *district;
@property (strong, nonatomic, readonly) NSString *availableTime;

@property (assign, nonatomic, readonly) BOOL isCheckIn;
@property (assign, nonatomic, readonly) NSUInteger checkInTimes;
@property (strong, nonatomic, readonly) NSString *lastCheckInDate;

@property (copy, nonatomic, readonly) NSString *title;
@property (copy, nonatomic, readonly) NSString *subtitle;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (instancetype)initWithUUID:(NSString *)uuid
                 StationName:(NSDictionary *)stationName
                     Address:(NSDictionary *)address
                        City:(NSDictionary *)city
                    District:(NSDictionary *)district
                     ZipCode:(NSUInteger)zipCode
               AvailableTime:(NSString *)availbaleTime
                    Latitude:(double)latitude
                   Longitude:(double)longitude
                       State:(GoStationState) state
                   isCheckIn:(BOOL)isCheckIn
                checkInTimes:(NSUInteger)checkInTimes
             lastCheckInDate:(NSDate *)lastCheckInDate;

@end
