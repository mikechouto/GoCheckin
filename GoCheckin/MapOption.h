//
//  MapOptions.h
//  GoCheckin
//
//  Created by Mike Chou on 5/5/16.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MapType) {
    MapTypeApple = 0,
    MapTypeGoogle,
};

@interface MapOption : NSObject

@property (strong, nonatomic, readonly) NSString *name;
@property (assign, nonatomic, readonly) BOOL isDefault;
@property (assign, nonatomic, readonly) MapType type;

// Only works if type is MapTypeGoogle
@property (assign, nonatomic, readonly) BOOL isInstalled;

- (instancetype)initWithName:(NSString *)name MapType:(MapType)type;
- (void)setToDefault;

@end
