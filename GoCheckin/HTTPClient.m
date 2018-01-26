//
//  HTTPClient.m
//  GoCheckin
//
//  Created by Mike Chou on 4/11/16.
//
//

#import "HTTPClient.h"

@implementation HTTPClient

static NSString * const GoStationAPIServer = @"https://webapi.gogoro.com/api";

//https://wapi.gogoro.com/tw/api/vm/list
- (void)getRequestForStation:(NSString *)path completion:(void (^)(id response, NSError *error))completion {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", GoStationAPIServer, path]];
    [self _getRequest:url completion:completion];
}

- (void)_getRequest:(NSURL *)url completion:(void (^)(id response, NSError *error))completion {
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!error) {
            NSError *err;
            id responsData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&err];
            
            // return dict and err, handel later.
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(responsData, err);
            });
            
        } else {
            
            // if the api contains error return error, handel later.
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
        }
        
    }];
    
    [dataTask resume];
}

@end
