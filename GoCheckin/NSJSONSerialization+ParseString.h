//
//  NSJSONSerialization+ParseString.h
//  GoCheckin
//
//  Created by Mike Chou on 4/19/16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSJSONSerialization (ParseString)

+ (nullable id)JSONObjectWithString:(NSString *)string options:(NSJSONReadingOptions)opt error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
