//
//  GoChargerAnnotation.m
//  GoCheckin
//
//  Created by Mike Chou on 8/31/16.
//
//

#import "GoChargerAnnotation.h"

@interface GoChargerAnnotation()

@property (strong, nonatomic) NSString *locale;

@end

@implementation GoChargerAnnotation

- (instancetype)initWithUUID:(NSString *)uuid Phone:(NSString *)phone Homepage:(NSString *)homepage ChargerName:(NSDictionary *)chargerName Address:(NSDictionary *)address City:(NSDictionary *)city District:(NSDictionary *)district Latitude:(double)latitude Longitude:(double)longitude {
    
    self = [super init];
    
    if (self) {
        _uuid = uuid;
        _phone = phone;
        _homepage = homepage;
        _name = [chargerName copy];
        _address = [address copy];
        _city = [city copy];
        _district = [district copy];
        _latitude = latitude;
        _longitude = longitude;
        _locale = [[NSLocale preferredLanguages] objectAtIndex:0];
    }
    return self;
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(_latitude, _longitude);
}

- (NSString *)title {
    
    NSString *title = [_name objectForKey:@"en"];
    
    if ([_locale containsString:@"zh"]) {
        title = [_name objectForKey:@"zh"];
    }
    
    return [NSString stringWithFormat:@"%@", title];
}

- (NSString *)subtitle {
    
    NSString *address = [_address objectForKey:@"en"];
    
    if ([_locale containsString:@"zh"]) {
        address = [_address objectForKey:@"zh"];
    }
    
    return address;
}

@end
