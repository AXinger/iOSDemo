//
//  StepNumberManager.h
//  StepNumberDemo
//
//  Created by AXing on 2019/2/20.
//  Copyright © 2019 liu.weixing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CMPedometer.h>

NS_ASSUME_NONNULL_BEGIN

@interface StepNumberManager : NSObject

/**
 * CoreMotion 获取步数
 * 使用的是CoreMotion中的api,就是iPhone数据,
 * 隐私策略 Privacy - Motion Usage Description 或 NSMotionUsageDescription
 * pedometerData.numberOfSteps 步数
 * pedometerData.distance 距离
 * pedometerData.floorsAscended 台阶
 *
 @param handler handler description
 
 */
-(void)todayPedometerHandler:(void(^)(CMPedometerData *pedometerData, NSError *error))handler;

/**
 * HealthKit 获取步数
 * 获取的是iPhone 健康APP 数据
 * 去除了第三方数据
 * 隐私策略  NSHealthShareUsageDescription  或 Privacy - Health Share Usage Description
 @param handler handler description
 */
- (void)todayHealthStepHandler:(void(^)(NSInteger setpCount,NSError *error))handler;

@end

NS_ASSUME_NONNULL_END
