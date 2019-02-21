//
//  StepNumberManager.m
//  StepNumberDemo
//
//  Created by AXing on 2019/2/20.
//  Copyright © 2019 liu.weixing. All rights reserved.
//

#import "StepNumberManager.h"
#import <CoreMotion/CoreMotion.h>
#import <HealthKit/HealthKit.h>
#import <UIKit/UIKit.h>
@interface StepNumberManager ()

@property (nonatomic, strong) CMPedometer *pedometer;

@property (nonatomic, strong) HKHealthStore *healthStore;

@end

@implementation StepNumberManager

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
-(void)todayPedometerHandler:(void(^)(CMPedometerData *pedometerData, NSError *error))handler{
    
    //判断记步功能
    if (![CMPedometer isStepCountingAvailable]) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"不支持健康数据"};
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:userInfo];
        handler(nil,error);
        return;
    }
    
    NSDate *endDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:endDate];
    NSDate *startDate = [calendar dateFromComponents:components];
    [self.pedometer queryPedometerDataFromDate:startDate toDate:endDate withHandler:handler];
    
    
}



/**
 * HealthKit 获取步数
 * 获取的是iPhone 健康APP 数据
 * 去除了第三方数据
 * 隐私策略  NSHealthShareUsageDescription  或 Privacy - Health Share Usage Description
 @param handler handler description
 */
- (void)todayHealthStepHandler:(void(^)(NSInteger setpCount,NSError *error))handler {
    
    if (![HKHealthStore isHealthDataAvailable]) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"不支持健康数据"};
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:userInfo];
        handler(0,error);
        return;
    }
    
    NSSet *readDataTypes = [self dataTypesRead];
    
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:readDataTypes completion:^(BOOL success, NSError * _Nullable error) {
        
        if (error) {
            handler(0,error);
            return ;
        }
        
        HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        
        NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
        
        HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:stepType predicate:[self predicateForSamplesToday] limit:HKObjectQueryNoLimit sortDescriptors:@[timeSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
            
            NSInteger totleSteps = 0;
            for(HKQuantitySample *sample in results){
                if ([sample.source.name isEqualToString:[UIDevice currentDevice].name]) {
                    HKQuantity *quantity = sample.quantity;
                    NSInteger usersHeight = (NSInteger)[quantity doubleValueForUnit:[HKUnit countUnit]];
                    totleSteps += usersHeight;
                }
            }
            handler(totleSteps,nil);
        }];
        
        [self.healthStore executeQuery:query];
        
        
    }];
    
    
}

/*!
 *  @brief  当天时间段
 *
 *  @return 时间段
 */
- (NSPredicate *)predicateForSamplesToday {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond: 0];
    
    NSDate *startDate = [calendar dateFromComponents:components];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    return predicate;
}

- (NSSet *)dataTypesRead{
//    HKQuantityType *activeEnergyType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    HKQuantityType *stepCountType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
//    HKQuantityType *floorCountType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
//    HKQuantityType *WalkingRunningType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
//    return [NSSet setWithObjects:stepCountType,floorCountType,activeEnergyType,WalkingRunningType, nil];
       return [NSSet setWithObjects:stepCountType, nil];
}


-(CMPedometer *)pedometer {
    if (nil == _pedometer) {
        _pedometer = [[CMPedometer alloc]init];
    }
    return _pedometer;
}

- (HKHealthStore *)healthStore {
    if (nil == _healthStore) {
        _healthStore = [[HKHealthStore alloc]init];
    }
    return _healthStore;
}
@end
