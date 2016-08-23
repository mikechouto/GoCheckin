//
//  HTTPClient.m
//  GoCheckin
//
//  Created by Mike Chou on 4/11/16.
//
//

#import "HTTPClient.h"

@implementation HTTPClient

static NSString * const GoStationAPIServer = @"http://wapi.gogoroapp.com/tw/api";
static NSString * const GoChargerAPIServer = @"https://raw.githubusercontent.com/mikechouto/GoCheckin-data/master/list.json";

- (void)getRequest:(NSURL *)url completion:(void (^)(NSDictionary *responseDict, NSError *error))completion {
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!error) {
            NSError *err;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&err];
            
            // return dict and err, handel later.
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(dict, err);
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

//http://wapi.gogoroapp.com/tw/api/vm/list
- (void)getRequestForStation:(NSString *)path completion:(void (^)(NSDictionary *responseDict, NSError *error))completion {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", GoStationAPIServer, path]];
    [self getRequest:url completion:completion];
}

//https://raw.githubusercontent.com/mikechouto/GoCheckin-data/master/list.json
- (void)getRequestForChargerWithCompletion:(void (^)(NSDictionary *responseDict, NSError *error))completion {
    NSURL *url = [NSURL URLWithString:GoChargerAPIServer];
    [self getRequest:url completion:completion];
}



@end
