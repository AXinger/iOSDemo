//
//  NotificationViewController.m
//  NoticeDemoContent
//
//  Created by AXing on 2019/2/19.
//  Copyright © 2019 liu.weixing. All rights reserved.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>

@interface NotificationViewController () <UNNotificationContentExtension>

@property IBOutlet UILabel *label;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any required interface initialization here.
}

- (void)didReceiveNotification:(UNNotification *)notification{
    
    self.label.text = notification.request.content.body;
}
- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response
                     completionHandler:(void (^)(UNNotificationContentExtensionResponseOption))completion{
    
    NSString *categoryIdentifier = response.notification.request.content.categoryIdentifier;
    //在NoticeConfig中设置的
    if ([categoryIdentifier isEqualToString:@"myNotificationCategory"]) {
        //交互逻辑
        [self handlerAction:response];
    }
}

- (void)handlerAction:(UNNotificationResponse *)response {
    NSString *textStr = nil;
    NSString *actionIdentifier = response.actionIdentifier;
    if (actionIdentifier == nil || [actionIdentifier isEqualToString:@""]) {
        return;
    }
    
    if ([actionIdentifier isEqualToString:@"noticeTextInput"]) {
        
        textStr = [(UNTextInputNotificationResponse *)response userText];
    } else if ([actionIdentifier isEqualToString:@"open"]) {
        textStr = @"open";
        
    } else {
        textStr = @"cancel";
    }
    NSLog(@"收到通知：%@",textStr);
}

@end
