//
//  HTTPClient.h
//  GoCheckin
//
//  Created by Mike Chou on 4/11/16.
//
//

#import <Foundation/Foundation.h>

@interface HTTPClient : NSObject

- (void)getRequestForStation:(NSString *)path completion:(void (^)(id response, NSError *error))completion;

@end
