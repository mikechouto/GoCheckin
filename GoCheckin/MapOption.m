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

- (BOOL)isDefault {
    
    BOOL isDefault = NO;
    MapType current = [[APIManager sharedInstance] currentDefaultMapApplication];
    if (current == _type) {
        isDefault = YES;
    }
    return isDefault;
}

- (void)setToDefault {
    
    if (!self.isDefault) {
        switch (_type) {
            case MapTypeApple:
                [[APIManager sharedInstance] changeDefaultMapToApple];
                break;
            case MapTypeGoogle:
                [[APIManager sharedInstance] changeDefaultMapToGoogle];
            default:
                break;
        }
    }
}

@end
