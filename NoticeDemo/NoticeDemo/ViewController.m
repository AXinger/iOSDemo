//
//  ViewController.m
//  NoticeDemo
//
//  Created by AXing on 2019/2/19.
//  Copyright © 2019 liu.weixing. All rights reserved.
//

#import "ViewController.h"
#import "UserNotifications/UserNotifications.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)authorizeAction:(id)sender {
    
    if (@available(iOS 10.0, *)) {
        
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError *__nullable error){
            
            if (granted) {
                NSLog(@"开通成功");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                    
                });
            } else {
                NSLog(@"开通失败");
            }
        }];
        
    } else {
        
        
        // 1. 创建消息上要添加的动作，以按钮的形式显示
        // 1.1 接受按钮
        UIMutableUserNotificationAction *acceptAction = [UIMutableUserNotificationAction new];
        acceptAction.identifier = @"acceptAction"; // 添加标识
        acceptAction.title = @"接受"; // 设置按钮上显示的文字
        acceptAction.activationMode = UIUserNotificationActivationModeForeground; // 当点击的时候启动程序
        
        // 1.2 拒绝按钮
        UIMutableUserNotificationAction *rejectAction = [UIMutableUserNotificationAction new];
        rejectAction.identifier = @"rejectAction";
        rejectAction.title = @"拒绝";
        rejectAction.activationMode = UIUserNotificationActivationModeBackground; // 当点击的时候不启动程序
        rejectAction.authenticationRequired = YES; // 需要解锁才能处理，如果 rejectAction.activationMode = UIUserNotificationActivationModeForeground; 那么这个属性将被忽略
        rejectAction.destructive = YES; // 按钮事件是否是不可逆转的
        
        
        
        // 2. 创建动作的类别集合
        UIMutableUserNotificationCategory *categorys = [UIMutableUserNotificationCategory new];
        categorys.identifier = @"alert"; // 动作集合的标识
        [categorys setActions:@[acceptAction, rejectAction]
                   forContext:UIUserNotificationActionContextMinimal]; // 把两个按钮添加到动作的集合中，并设置上下文样式
        
        // 3. 创建UIUserNotificationSettings，并设置消息的显示类型
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound) categories:[NSSet setWithObjects:categorys, nil]];
        
        // 4. 注册通知
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        
        
    }
}

- (IBAction)backstageAction:(id)sender {
    
    if (@available(iOS 10.0, *)) {
        
        //创建通知内容
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"iOS10title";
        content.body = @"我是body";
        content.categoryIdentifier = @"myNotificationCategory";
        content.userInfo = @{@"name":@"jim"};
        //创建发送触发
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5 repeats:NO];
        
        //设置一个发送请求标识符
        NSString *identifier = @"timeInterVal";
        
        //创建一个发送请求
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger ];
        
        
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError *error){
            if (error) {
                NSLog(@"发送失败%@",error);
            } else {
                NSLog(@"发送成功%@",error);
            }
        }];
    }else {
        
        
        UILocalNotification *loc = [[UILocalNotification alloc] init];
        
        
        if (@available(iOS 8.2, *)) {
            loc.alertTitle = @"alertTitle";
        } else {
        }
        
        loc.alertBody = @"ios10前alertBody";
        // 锁屏界面显示的小标题(完整小标题:“滑动来” + alertAction)
        loc.alertAction = @"查看消息";
        loc.soundName = UILocalNotificationDefaultSoundName;
        loc.alertLaunchImage = @"onevcat" ;
        loc.category = @"alert";
        //立即触发一个通知
        //            [[UIApplication sharedApplication] presentLocalNotificationNow:loc];
        
        //调度本地推送通知(调度完毕后,推送通知会在特地时间fireDate发出)
        loc.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
        loc.timeZone = [NSTimeZone defaultTimeZone];
        //    loc.repeatInterval = NSCalendarUnitSecond;
        
        [[UIApplication sharedApplication] scheduleLocalNotification:loc];
        NSLog(@"IOS10以前发送通知");
    }
}

- (IBAction)imageAction:(id)sender {
    
    if (@available(iOS 10.0, *)) {
        //创建通知内容
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"iOS 10title";
        content.body = @"iOS 10body";
        content.categoryIdentifier = @"ljtAction";
        
        //添加附件图片资源
        
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"onevcat" ofType:@"jpg"];
        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"image" URL:[NSURL fileURLWithPath:imagePath] options:nil error:nil];
        
        content.attachments = @[attachment];
        
        
        //创建时间触发,一般用于延时
        //    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5.0 repeats:NO];
        
        
        NSString *identifier = @"ljtAction";
        //创建一个发送请求
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:nil ];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            //将发送请求添加到发送中心
            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError *error){
                if (error) {
                    NSLog(@"发送失败%@",error);
                } else {
                    NSLog(@"发送成功%@",error);
                }
            }];
        });
        
        
    }
}

@end
