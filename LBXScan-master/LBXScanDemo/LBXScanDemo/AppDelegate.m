//
//  AppDelegate.m
//  LBXScanDemo
//
//  Created by lbxia on 2017/1/4.
//  Copyright © 2017年 lbx. All rights reserved.
//

#import "AppDelegate.h"
#import "DemoListTableViewController.h"
#import "MainViewController.h"
#import "ViewController.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    ViewController *list = [[ViewController alloc]init];
    
//    MainViewController *list = [[MainViewController alloc]init];
    
    self.window.rootViewController = [[UINavigationController alloc]initWithRootViewController:list];
    [self.window makeKeyAndVisible];
    
    
    return YES;
}

@end
