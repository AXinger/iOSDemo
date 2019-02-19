//
//  NoticeHandler.m
//  NoticeDemo
//
//  Created by AXing on 2019/2/19.
//  Copyright © 2019 liu.weixing. All rights reserved.
//

#import "NoticeHandler.h"
#import <UIKit/UIKit.h>
@implementation NoticeHandler

//iOS10新增：处理前台收到通知的代理方法
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    
    NSLog(@"收到通知>>>>");
    
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        NSLog(@"iOS10 前台收到远程通知");
        
    } else {
        // 判断为本地通知 NSLog(@"iOS10 前台收到本地通知:
         NSLog(@"iOS10 前台收到本地通知");
    }
    
    UNNotificationPresentationOptions options = UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert;
    
    //设置完成之后必须调用这个回调，
    completionHandler(options);
}

// 通知的点击事件
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler{
    
    NSString *categoryIdentifier = response.notification.request.content.categoryIdentifier;
    
     NSLog(@"response.actionIdentifier：%@",response.actionIdentifier);
    
    NSLog(@"点击通知: %@",categoryIdentifier);
    NSLog(@"点击通知: %@",response.notification.request.content.userInfo);
    
   
    completionHandler();
    
   
}





@end
