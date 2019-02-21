//
//  ViewController.m
//  StepNumberDemo
//
//  Created by AXing on 2019/2/20.
//  Copyright © 2019 liu.weixing. All rights reserved.
//

#import "ViewController.h"
#import "StepNumberManager.h"

@interface ViewController ()
@property(nonatomic,strong)  StepNumberManager *setp;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
self.setp = [ [StepNumberManager alloc]init];
    
//    [self.setp getTodayPedometerHandler:^(CMPedometerData * _Nonnull pedometerData, NSError * _Nonnull error) {
//        if (error) {
//            NSLog(@"error====%@",error);
//        }else {
//            NSLog(@"步数====%@",pedometerData.numberOfSteps);
//            NSLog(@"距离====%@",pedometerData.distance);
//            NSLog(@"距离====%@",pedometerData.floorsAscended);
//
//        }
//    }];
    
   
//    [self.setp todayHealthStepHandler:^(NSInteger setpCount, NSError * _Nonnull error) {
//        NSLog(@"setpCount>> %@",error);
//        NSLog(@"setpCount>> %ld",setpCount);
//    }];
    
    [self.setp todayPedometerHandler:^(CMPedometerData * _Nonnull pedometerData, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
}


@end
