//
//  Station.m
//  GoCheckin
//
//  Created by Mike Chou on 4/14/16.
//
//

#import "GoStation.h"

@implementation GoStation

+ (NSString *)primaryKey {
    return @"uuid";
}

+ (NSArray<NSString *> *)requiredProperties {
    return @[@"uuid", @"name_eng", @"name_cht", @"address_eng", @"address_cht"];
}

+ (NSArray<NSString *> *)indexedProperties {
    return @[@"uuid"];
}

+ (NSDictionary *)defaultPropertyValues {
    return @{@"is_checkin":@NO, @"online_time":@(0), @"offline_time":@(0)};
}

@end
