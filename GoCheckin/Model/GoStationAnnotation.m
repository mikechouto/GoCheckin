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
@property (assign, nonatomic) GoStationStatus status;

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
        _availableTime = @"24HR";//[station.available_time copy];
        _latitude = station.latitude;
        _longitude = station.longitude;
        _status = station.state;
        _isCheckIn = station.is_checkin;
        _checkInTimes = [station.checkin_times integerValue];
        _lastCheckInDate = [station.last_checkin_date copy];
        _status = station.state;
    }
    _locale = [[NSLocale preferredLanguages] objectAtIndex:0];
    return self;
}

- (GoStationStatus)status
{
    switch (_status) {
        case 1:
            if (![self isBusinessHour:self.availableTime]) {
                return GoStationStatusClosed;
            } else {
                return GoStationStatusNormal;
            }
        case 99:
            return GoStationStatusConstructing;
        case 100:
            return GoStationStatusPreparing;
        case 997:
            return GoStationStatusDeprecated;
        default:
            return GoStationStatusUnknown;
    }
    return GoStationStatusUnknown;
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
