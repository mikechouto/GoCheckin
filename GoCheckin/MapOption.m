//
//  MapOptions.m
//  GoCheckin
//
//  Created by Mike Chou on 5/5/16.
//
//

#import "MapOption.h"
#import "APIManager.h"

@implementation MapOption

- (instancetype)initWithName:(NSString *)name MapType:(MapType)type {
    self = [super init];
    
    if (self) {
        _name = name;
        _type = type;
        _isDefault = [self checkIsDefault:type];
        _isInstalled = [self isGoogleMapInstalled:type];
    }
    
    return self;
}

- (BOOL)isGoogleMapInstalled:(MapType)type {
    BOOL isInstalled = YES;
    if (type == MapTypeGoogle) {
         isInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]];
        
    }
    return isInstalled;
}

- (BOOL)checkIsDefault:(MapType)type {
    BOOL isDefault = NO;
    MapType current = [[APIManager sharedInstance] currentDefaultMapApplication];
    if (current == type) {
        isDefault = YES;
    }
    return isDefault;
}

@end
