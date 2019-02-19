//
//  NoticeConfig.h
//  NoticeDemo
//
//  Created by AXing on 2019/2/19.
//  Copyright © 2019 liu.weixing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserNotifications/UserNotifications.h"
NS_ASSUME_NONNULL_BEGIN

__IOS_AVAILABLE(10.0) __OSX_AVAILABLE(10.14) __TVOS_PROHIBITED __WATCHOS_PROHIBITED
@interface NoticeConfig : NSObject


/**
 注册通知下拉样式,通知显示的样式不变,需要下拉通知才会显示
 */
+(void)registerCategoryStyle;

@end

NS_ASSUME_NONNULL_END
