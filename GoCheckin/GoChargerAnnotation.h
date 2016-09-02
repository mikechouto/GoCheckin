//
//  GoChargerAnnotation.h
//  GoCheckin
//
//  Created by Mike Chou on 8/31/16.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface GoChargerAnnotation : NSObject<MKAnnotation>

@property (strong, nonatomic, readonly) NSString *uuid;
@property (strong, nonatomic, readonly) NSString *phone;
@property (strong, nonatomic, readonly) NSString *homepage;
@property (assign, nonatomic, readonly) double latitude;
@property (assign, nonatomic, readonly) double longitude;
@property (strong, nonatomic, readonly) NSDictionary *name;
@property (strong, nonatomic, readonly) NSDictionary *address;
@property (strong, nonatomic, readonly) NSDictionary *city;
@property (strong, nonatomic, readonly) NSDictionary *district;

@property (copy, nonatomic, readonly) NSString *title;
@property (copy, nonatomic, readonly) NSString *subtitle;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (instancetype)initWithUUID:(NSString *)uuid
                       Phone:(NSString *)phone
                    Homepage:(NSString *)homepage
                 ChargerName:(NSDictionary *)chargerName
                     Address:(NSDictionary *)address
                        City:(NSDictionary *)city
                    District:(NSDictionary *)district
                    Latitude:(double)latitude
                   Longitude:(double)longitude;

@end
