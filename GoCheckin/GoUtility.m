//
//  GoUtility.m
//  GoCheckin
//
//  Created by Mike Chou on 8/18/16.
//
//

#import "GoUtility.h"

@implementation GoUtility

+ (UIImage *)normalImage {
    static dispatch_once_t once;
    static UIImage *image;
    dispatch_once(&once, ^{
        image = [UIImage imageNamed:@"pin_station_normal"];
    });
    return image;
}

+ (UIImage *)normalCheckinImage {
    static dispatch_once_t once;
    static UIImage *image;
    dispatch_once(&once, ^{
        image = [UIImage imageNamed:@"pin_station_checkin_normal"];
    });
    return image;
}

+ (UIImage *)closedImage {
    static dispatch_once_t once;
    static UIImage *image;
    dispatch_once(&once, ^{
        image = [UIImage imageNamed:@"pin_station_closed"];
    });
    return image;
}

+ (UIImage *)closedCheckinImage {
    static dispatch_once_t once;
    static UIImage *image;
    dispatch_once(&once, ^{
        image = [UIImage imageNamed:@"pin_station_checkin_closed"];
    });
    return image;
}

+ (UIImage *)constructingImage {
    static dispatch_once_t once;
    static UIImage *image;
    dispatch_once(&once, ^{
        image = [UIImage imageNamed:@"pin_station_constructing"];
    });
    return image;
}

+ (UIImage *)deprecatedImage {
    static dispatch_once_t once;
    static UIImage *image;
    dispatch_once(&once, ^{
        image = [UIImage imageNamed:@"pin_station_retired"];
    });
    return image;
}

+ (UIImage *)deprecatedCheckinImage {
    static dispatch_once_t once;
    static UIImage *image;
    dispatch_once(&once, ^{
        image = [UIImage imageNamed:@"pin_station_checkin_retired"];
    });
    return image;
}

+ (UIImage *)chargerImage {
    static dispatch_once_t once;
    static UIImage *image;
    dispatch_once(&once, ^{
        image = [UIImage imageNamed:@"pin_charger_normal"];
    });
    return image;
}

@end
