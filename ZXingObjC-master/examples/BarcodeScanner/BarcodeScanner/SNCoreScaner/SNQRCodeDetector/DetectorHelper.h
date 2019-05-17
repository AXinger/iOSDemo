//
//  DetectorHelper.h
//  SNQRCodeDetector
//
//  Created by zhangjie on 2017/9/8.
//  Copyright © 2017年 suning. All rights reserved.
//

#import <UIKit/UIKit.h>

static BOOL isZoommed;

static BOOL enableAutoZoomWhenBarcodeDetectedIsSmall;

@interface DetectorHelper : NSObject

+ (BOOL)finderPatternHandler:(CGFloat)moduleSize;

// 设置是否已经缩放过
+ (void)setIsZoommed:(BOOL)isZoom;

// 扫到的二维码太小，自动拉近扫码距离，默认为NO
+ (void)setEnableAutoZoomWhenBarcodeDetectedIsSmall:(BOOL)isEnable;

@end
