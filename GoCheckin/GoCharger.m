//
//  GoCharger.m
//  GoCheckin
//
//  Created by Mike Chou on 8/29/16.
//
//

#import "GoCharger.h"

@implementation GoCharger

+ (NSString *)primaryKey {
    return @"uuid";
}

+ (NSArray<NSString *> *)requiredProperties {
    return @[@"uuid", @"name_eng", @"name_cht", @"address_eng", @"address_cht"];
}

+ (NSArray<NSString *> *)indexedProperties {
    return @[@"uuid"];
}

@end
