//
//  GoCharger.h
//  GoCheckin
//
//  Created by Mike Chou on 8/29/16.
//
//

#import <Realm/Realm.h>

@interface GoCharger : RLMObject

// schema version 1
@property NSString *uuid;
@property long long update_time;
@property NSString *name_eng;
@property NSString *name_cht;
@property double latitude;
@property double longitude;
@property int state;
@property NSString *address_eng;
@property NSString *address_cht;
@property NSString *city_eng;
@property NSString *city_cht;
@property NSString *district_eng;
@property NSString *district_cht;
@property NSString *available_time;
@property NSString *phone_num;
@property NSString *homepage;


@end
