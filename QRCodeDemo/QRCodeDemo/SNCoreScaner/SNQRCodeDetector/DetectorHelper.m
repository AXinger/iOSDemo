//
//  DetectorHelper.m
//  SNQRCodeDetector
//
//  Created by zhangjie on 2017/9/8.
//  Copyright © 2017年 suning. All rights reserved.
//

#import "DetectorHelper.h"
#import <AVFoundation/AVFoundation.h>

#define MaxBarcodeModuleSize   5.0f

@implementation DetectorHelper

+(BOOL)finderPatternHandler:(CGFloat)moduleSize {
    // 如果不开启扫到的二维码太小，自动拉近扫码距离功能，返回zxing继续处理
    if (!enableAutoZoomWhenBarcodeDetectedIsSmall) {
        return YES;
    }
    
    //    NSLog(@"========== finderPatternHandler");
    BOOL shouldContinue = YES;
    AVCaptureDevice *captureDevice =[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([captureDevice isRampingVideoZoom]) {
        shouldContinue = NO;
    }else{
        if (isZoommed == NO) {
            if (moduleSize < MaxBarcodeModuleSize) {
                isZoommed = YES;
                shouldContinue = NO;
                NSError *cerror = nil;
                [captureDevice lockForConfiguration:&cerror];
                CGFloat videoMaxZoomFactor = 3.0f;
                if (captureDevice.activeFormat.videoMaxZoomFactor < videoMaxZoomFactor) {
                    videoMaxZoomFactor = captureDevice.activeFormat.videoMaxZoomFactor;
                }
                [captureDevice rampToVideoZoomFactor:videoMaxZoomFactor withRate:6.0f];
                [captureDevice unlockForConfiguration];
            }
        }
    }
    
    return shouldContinue;
}

+ (void)setIsZoommed:(BOOL)isZoom {
    isZoommed = isZoom;
}

+ (void)setEnableAutoZoomWhenBarcodeDetectedIsSmall:(BOOL)isEnable {
    enableAutoZoomWhenBarcodeDetectedIsSmall = isEnable;
}

@end
