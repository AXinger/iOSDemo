//
//  AppDelegate.m
//  NoticeDemo
//
//  Created by AXing on 2019/2/19.
//  Copyright © 2019 liu.weixing. All rights reserved.
//

#import "AppDelegate.h"
#import "NoticeHandler.h"
#import "NoticeConfig.h"


@interface AppDelegate ()

@property (strong, nonatomic) NoticeHandler *handler API_AVAILABLE(ios(10.0));

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    NSLog(@"launchOptions>> %@",launchOptions);
    
    
    //设置代理,未授权时也可以设置代理
    if (@available(iOS 10.0, *)) {
        [NoticeConfig registerCategoryStyle];
        self.handler = [[NoticeHandler alloc] init];
        [UNUserNotificationCenter currentNotificationCenter].delegate = self.handler;
    } else {
        
    }
    return YES;
}


//iOS10之前 App处于前台时收到本地通知回调
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSLog(@"iOS10之前 App处于前台时收到本地通知回调");
}

//iOS10之前 通知回调
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
     NSLog(@"iOS10之前 通知回调");
    completionHandler(UIBackgroundFetchResultNoData);
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
