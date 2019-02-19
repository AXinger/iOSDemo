//
//  NotificationService.h
//  NoticeService
//
//  Created by AXing on 2019/2/19.
//  Copyright © 2019 liu.weixing. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>
/**
 Notification Service是一个没有UI的Extension，用于增加或者替换远程推送内容的。
 */
__IOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0) __OSX_AVAILABLE(10.14) __TVOS_PROHIBITED
@interface NotificationService : UNNotificationServiceExtension

@end
