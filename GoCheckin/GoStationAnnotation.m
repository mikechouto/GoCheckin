//
//  GoStation.m
//  GoCheckin
//
//  Created by Mike Chou on 4/7/16.
//
//

#import "GoStationAnnotation.h"
#import "GoStation.h"

@interface GoStationAnnotation()

@property (strong, nonatomic) NSString *locale;

@end

@implementation GoStationAnnotation

- (instancetype)initWithGoStation:(GoStation *)station {
    
    self = [super init];
    if (self) {
        _uuid = [station.uuid copy];
        _name = @{@"en": [station.name_eng copy],
                  @"zh": [station.name_cht copy]};
        _address = @{@"en": [station.address_eng copy],
                     @"zh": [station.address_cht copy]};
        _city = @{@"en": [station.city_eng copy],
                  @"zh": [station.city_cht copy]};
        _district = @{@"en": [station.district_eng copy],
                      @"zh": [station.district_cht copy]};
        _zipCode = station.zip_code;
        _availableTime = [station.available_time copy];
        _latitude = station.latitude;
        _longitude = station.longitude;
        _status = station.state;
        _isCheckIn = station.is_checkin;
        _checkInTimes = [station.checkin_times integerValue];
        _lastCheckInDate = [station.last_checkin_date copy];
    }
    return self;
}

- (instancetype)initWithUUID:(NSString *)uuid StationName:(NSDictionary *)stationName Address:(NSDictionary *)address City:(NSDictionary *)city District:(NSDictionary *)district ZipCode:(NSUInteger)zipCode AvailableTime:(NSString *)availableTime Latitude:(double)latitude Longitude:(double)longitude Status:(GoStationStatus)status isCheckIn:(BOOL)isCheckIn checkInTimes:(NSUInteger)checkInTimes lastCheckInDate:(NSDate *)lastCheckInDate {
    
    self = [super init];
    
    if (self) {
        _uuid = uuid;
        _name = [stationName copy];
        _address = [address copy];
        _city = [city copy];
        _district = [district copy];
        _zipCode = zipCode;
        _availableTime = availableTime;
        _latitude = latitude;
        _longitude = longitude;
        _isCheckIn = isCheckIn;
        _checkInTimes = checkInTimes;
        _lastCheckInDate = [self _formateDateToString:lastCheckInDate];
        
        switch (status) {
            case 1:
                _status = GoStationStatusNormal;
                if (![self isBusinessHour:availableTime]) {
                    _status = GoStationStatusClosed;
                }
                break;
            case 99:
                _status = GoStationStatusConstructing;
                break;
            case 100:
                _status = GoStationStatusPreparing;
                break;
            case 997:
                _status = GoStationStatusDeprecated;
                break;
            default:
                _status = GoStationStatusUnknown;
                break;
        }
        
        _locale = [[NSLocale preferredLanguages] objectAtIndex:0];
    }
    return self;
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

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(_latitude, _longitude);
}

- (BOOL)isBusinessHour:(NSString *)availableTime {
    
    BOOL isOpen = YES;
    
    if ([availableTime caseInsensitiveCompare:@"24HR"] != NSOrderedSame) {
        NSString *tempAvailableTime = availableTime;
        
        tempAvailableTime = [availableTime stringByReplacingOccurrencesOfString:@" " withString:@""];
        tempAvailableTime = [availableTime stringByReplacingOccurrencesOfString:@":" withString:@""];
        
        NSArray<NSString *> *availbaleTimes = [tempAvailableTime componentsSeparatedByString:@"~"];
        if (availbaleTimes.count == 2) {
            
            NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            [calendar setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Taipei"]];
            NSDateComponents *components = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:[NSDate date]];
            NSInteger currentTime = [components hour] * 100 + [components minute];
            
            NSInteger openTime = [availbaleTimes[0] integerValue];
            NSInteger closeTime = [availbaleTimes[1] integerValue];
            
            if (currentTime < openTime || currentTime >= closeTime) {
                isOpen = NO;
            }
            
        }
    }
    return isOpen;
}

- (NSString *)_formateDateToString:(NSDate *)date {
    NSString *dateString = @"";
    if (date) {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy/MM/dd"];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Taipei"]];
        dateString = [dateFormat stringFromDate:date];
    }
    return dateString;
}

@end
