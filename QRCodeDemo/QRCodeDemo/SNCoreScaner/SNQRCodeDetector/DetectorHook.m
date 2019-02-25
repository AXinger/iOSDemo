//
//  DetectorHook.m
//  SNQRCodeDetector
//
//  Created by zhangjie on 2017/9/5.
//  Copyright © 2017年 suning. All rights reserved.
//

#import "DetectorHook.h"
//#import <ZXingObjC/ZXingObjC.h>
#import "ZXingObjC.h"
#import <objc/runtime.h>
#import "SNQRCodeDetector.h"
#import "DetectorHelper.h"

@implementation ZXQRCodeDetector (hook)

- (ZXDetectorResult *)rep_processFinderPatternInfo:(ZXQRCodeFinderPatternInfo *)info error:(NSError **)error {
    // =========== hook start
    ZXQRCodeFinderPattern *topLeft = info.topLeft;
    ZXQRCodeFinderPattern *topRight = info.topRight;
    ZXQRCodeFinderPattern *bottomLeft = info.bottomLeft;
    
    float moduleSize = [self calculateModuleSize:topLeft topRight:topRight bottomLeft:bottomLeft];
    BOOL result = [DetectorHelper finderPatternHandler:moduleSize];
    if (!result) {
        return nil;
    }
    // ========== hook end
    
    return [self rep_processFinderPatternInfo:info error:error];
}

@end



@implementation DetectorHook

+ (void)startHook {
    // 交换方法，只交换一次
    static BOOL hasExchangeedImplementations = NO;
    if (!hasExchangeedImplementations) {
        hasExchangeedImplementations = YES;
        
        Method oriMethod = class_getInstanceMethod([ZXQRCodeDetector class], @selector(processFinderPatternInfo:error:));
        Method repMethod = class_getInstanceMethod([ZXQRCodeDetector class], @selector(rep_processFinderPatternInfo:error:));
        method_exchangeImplementations(oriMethod, repMethod);
    }
}

@end
