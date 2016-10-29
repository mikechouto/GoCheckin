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
        _isInstalled = [self _isGoogleMapInstalled:type];
    }
    
    return self;
}

- (BOOL)_isGoogleMapInstalled:(MapType)type {
    BOOL isInstalled = YES;
    if (type == GoogleMap) {
         isInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]];
        
    }
    return isInstalled;
}

- (BOOL)isDefault {
    
    BOOL isDefault = NO;
    MapType current = [[APIManager sharedInstance] currentMapApplication];
    if (current == _type) {
        isDefault = YES;
    }
    return isDefault;
}

- (void)setToDefault {
    
    if (!self.isDefault) {
        switch (_type) {
            case AppleMap:
                [[APIManager sharedInstance] changeDefaultMapToApple];
                break;
            case GoogleMap:
                [[APIManager sharedInstance] changeDefaultMapToGoogle];
            default:
                break;
        }
    }
}

@end
