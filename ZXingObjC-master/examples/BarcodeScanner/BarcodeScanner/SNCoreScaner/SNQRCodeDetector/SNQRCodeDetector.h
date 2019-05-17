//
//  SNQRCodeDetector.h
//  SNQRCodeDetector
//
//  Created by zhangjie on 2017/9/1.
//  Copyright © 2017年 suning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SNCoreScaner.h"

@class AVCaptureSession;

@protocol SNQRCodeDetectorDelegate <NSObject>

- (void)detectorDidDetectBarcode:(NSString *)codeContent codeType:(NSString *)codeType;

- (void)detectorDidDetectDarkImage;

/** 环境亮度值回调 -5~12 7.1.0新增加*/
- (void)detectorDidDetectDarkValue:(float)brightnessValue;

//实时传递buffer
- (void)passBuffer4ARScan:(CMSampleBufferRef)sampleBufferRef;

@end


@interface SNQRCodeDetector : NSObject

@property (nonatomic, strong) AVCaptureDevice *captureDevice;

@property (nonatomic, weak) id<SNQRCodeDetectorDelegate> delegate;

//识别区域，不传值默认识别整个图像
@property (nonatomic) CGRect scanRect;

//亮度阈值，默认值为-1，图像亮度小于阈值是会调用回调detectorDidDetectDarkImage
@property (nonatomic) CGFloat brightnessThreshold;

@property (nonatomic, assign) int camera;//设置摄像头，0-后置，1-前置

//是否开启zxing辅助扫码，实现二维码拉近功能
@property (nonatomic,assign) BOOL enableZXing;

//开启自动对焦，在图像画面变化时自动重新对焦
- (void)enableAutoFocus;


- (NSError *)startWithCaptureSession:(AVCaptureSession *)session;

/**
 设置rectOfInterest
 
 @param size 父view的size
 @param scanRect 扫描区域
 */
- (void)setRectOfInterestWithSize:(CGSize)size scanRect:(CGRect)scanRect scanType:(SNCoreScanerScanType)scanType;

// 扫到的二维码太小，自动拉近扫码距离，默认为NO
- (void)setEnableAutoZoomWhenBarcodeDetectedIsSmall:(BOOL)isEnable;

@end
