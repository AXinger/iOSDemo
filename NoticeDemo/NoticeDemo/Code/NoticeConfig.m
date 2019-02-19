//
//  NoticeConfig.m
//  NoticeDemo
//
//  Created by AXing on 2019/2/19.
//  Copyright © 2019 liu.weixing. All rights reserved.
//

#import "NoticeConfig.h"

@implementation NoticeConfig

+(void)registerCategoryStyle {
    
    /**options
     UNNotificationActionOptionAuthenticationRequired  用于文本
     UNNotificationActionOptionForeground  前台模式，进入APP
     UNNotificationActionOptionDestructive  销毁模式，不进入APP
     */
    
    NSArray *actionsArray = @[
                              [UNTextInputNotificationAction actionWithIdentifier:@"noticeTextInput" title:@"输入" options:UNNotificationActionOptionAuthenticationRequired textInputButtonTitle:@"发送" textInputPlaceholder:@"说点什么吧？"],
                              [UNNotificationAction actionWithIdentifier:@"open" title:@"打开" options:UNNotificationActionOptionForeground],
                              [UNNotificationAction actionWithIdentifier:@"cancel" title:@"取消" options:UNNotificationActionOptionDestructive]];
    
    //注意注册的category的标识符为,需要在NoticeDemoContent info里面配置NSExtension-NSExtensionAttributes
    UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:@"myNotificationCategory" actions:actionsArray intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
    
    NSSet *set = [NSSet setWithObjects:category,nil];
    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:set];
}


@end
