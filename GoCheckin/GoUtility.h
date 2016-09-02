//
//  GoUtility.h
//  GoCheckin
//
//  Created by Mike Chou on 8/18/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GoUtility : NSObject

+ (UIImage *)normalImage;
+ (UIImage *)normalCheckinImage;
+ (UIImage *)closedImage;
+ (UIImage *)closedCheckinImage;
+ (UIImage *)constructingImage;
+ (UIImage *)deprecatedImage;
+ (UIImage *)deprecatedCheckinImage;
+ (UIImage *)chargerImage;

@end
