//
//  Station.h
//  GoCheckin
//
//  Created by Mike Chou on 4/14/16.
//
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface GoStation : RLMObject

// schema version 0
@property NSString *uuid;
@property long long update_time;
@property NSString *name_eng;
@property NSString *name_cht;
@property double latitude;
@property double longitude;
@property int state;
@property int zip_code;
@property NSString *address_eng;
@property NSString *address_cht;
@property NSString *city_eng;
@property NSString *city_cht;
@property NSString *district_eng;
@property NSString *district_cht;
@property NSString *available_time;
@property BOOL is_checkin;
@property NSNumber<RLMInt> *checkin_times;
@property NSDate *checkin_date;
@property NSDate *last_checkin_date;

// schema version 1
@property NSNumber<RLMDouble> *online_time;
@property NSNumber<RLMDouble> *offline_time;

@end
