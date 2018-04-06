//
//  NSJSONSerialization+ParseString.m
//  GoCheckin
//
//  Created by Mike Chou on 4/19/16.
//
//

#import "NSJSONSerialization+ParseString.h"

@implementation NSJSONSerialization (ParseString)

+ (nullable id)JSONObjectWithString:(NSString *)string options:(NSJSONReadingOptions)opt error:(NSError **)error {
    
    id returnValue = nil;
    
    if (string) {
        if ([string isKindOfClass:[NSString class]]) {
            if (![string isEqualToString:@""]) {
                NSData *jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
                returnValue = [self JSONObjectWithData:jsonData options:opt error:error];
            }
        }
    }
    
    return returnValue;
}

@end
