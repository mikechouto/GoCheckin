//
//  AppDelegate.m
//  GoCheckin
//
//  Created by Mike Chou on 4/7/16.
//
//

#import "AppDelegate.h"
#import <Realm/Realm.h>
#import "APIManager.h"
#import "GoStation.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    // Use the default directory, but replace the filename with the username.
    NSString *databaseURL = [[[[config.fileURL absoluteString] stringByDeletingLastPathComponent]
                            stringByAppendingPathComponent:@"gocheckin"]
                            stringByAppendingPathExtension:@"realm"];
    config.fileURL = [NSURL URLWithString:databaseURL];
    
    /* 2016/08/08 issus #5
     * Update realm database schemaVersion and perform migration
     * Add new column online_date, offline_date
     */
    config.schemaVersion = 2;
    
    config.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        
        if (oldSchemaVersion < 1) {
            
            [migration enumerateObjects:GoStation.className block:^(RLMObject * _Nullable oldObject, RLMObject * _Nullable newObject) {
                if ([oldObject[@"state"] integerValue] == 1) {
                    newObject[@"online_time"] = oldObject[@"update_time"];
                }
                
                // Handle the only offline station uuid:27588f6e-8248-4bb5-8c66-fd009d6cdb17
                if ([oldObject[@"uuid"] isEqualToString:@"27588f6e-8248-4bb5-8c66-fd009d6cdb17"]) {
                    newObject[@"online_time"] = oldObject[@"update_time"];
                    newObject[@"offline_time"] = oldObject[@"update_time"];
                    newObject[@"state"] = @(997);
                }
            }];
        }
        
        if (oldSchemaVersion < 2) {
            [migration enumerateObjects:GoStation.className block:^(RLMObject * _Nullable oldObject, RLMObject * _Nullable newObject) {
                //1517702400 = 02/04/2018 12:00 utc
                if ([oldObject[@"update_time"] longLongValue] >= 1517702400) {
                    [migration deleteObject:oldObject];
                }
            }];
            
            [migration enumerateObjects:GoStation.className block:^(RLMObject * _Nullable oldObject, RLMObject * _Nullable newObject) {
                newObject[@"uuid"] = [oldObject[@"uuid"] uppercaseString];
            }];
        }
    };
    
    // Set this as the configuration used for the default Realm
    [RLMRealmConfiguration setDefaultConfiguration:config];
    
    // Set up NSUserDefaults it it's the first launch.
    [[APIManager sharedInstance] initUserDefaultsIfNeeded];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
