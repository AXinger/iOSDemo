//
//  NoticeHandler.h
//  NoticeDemo
//
//  Created by AXing on 2019/2/19.
//  Copyright © 2019 liu.weixing. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "UserNotifications/UserNotifications.h"

NS_ASSUME_NONNULL_BEGIN
__IOS_AVAILABLE(10.0) __OSX_AVAILABLE(10.14) __TVOS_PROHIBITED __WATCHOS_PROHIBITED
@interface NoticeHandler : NSObject<UNUserNotificationCenterDelegate>

@end

NS_ASSUME_NONNULL_END
