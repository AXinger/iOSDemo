//
//  SNCoreScaner.h
//  SuningEBuy
//
//  Created by xzoscar on 15/12/23.
//  Copyright © 2015年 苏宁易购. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


/**
 检测环境亮暗

 @param brightnessValue 亮暗值-5~12 临界值~~-1
 */
typedef void(^SNCoreScanerBrightnessBlock)(float brightnessValue);

typedef void (^SNCoreScanerAVCaptureScanOutputComplete)(NSString *stringValue, NSString *type, NSError *error);


/*
 * SNCoreScanerScanType
 * 识别扫码区域类型
 */
typedef NS_ENUM(NSInteger, SNCoreScanerScanType) {
    SNCoreScanerScanTypeDefault     = 0,//默认，只识别扫描区域
    SNCoreScanerScanTypeFullWidth   = 1 //识别整个屏幕款对
};

/*
 * 扫码核心代码
 * 2015/12/23
 * @xzoscar
 */

@interface SNCoreScaner : NSObject

@property (nonatomic,strong) AVCaptureSession *captureSession;

// 父视图layer
@property (nonatomic,weak) CALayer *superPreviewLayer;

// callback 当摄像头初始化完成
@property (nonatomic,copy) void (^AVCaptureInitComplete)(NSError *error);

// callback 当摄像头开始扫码
@property (nonatomic,copy) void (^AVCaptureScanStarted)();

//实时回调buffer 提供给AR扫
@property (nonatomic,copy) void (^AVCaptureScanOutputingBuffer)(CMSampleBufferRef buffer);

/*
 * 扫码输出
 * @paras stringValue 输出的扫码字符串
 * @type  输出扫码类型 @"org.iso.QRCode"为二维码
 * @paras error 成功输出nil
 */

// 扫到结果回调
@property (nonatomic,copy) SNCoreScanerAVCaptureScanOutputComplete avCaptureScanOutputComplete;

@property (nonatomic,copy) BOOL (^CustomAVCaptureScanOutputComplete)(NSString *stringValue,NSString *type,NSError *error);

@property(nonatomic, readonly, getter=isRunning) BOOL running;

@property (nonatomic,strong) AVCaptureMetadataOutput    *captureOutput;

@property (nonatomic, assign) int camera;//设置摄像头，0-后置，1-前置

@property (nonatomic,assign) BOOL enableSound;//扫码成功声音提示，默认为NO

@property (nonatomic,assign) BOOL enableZXing;//zxing辅助扫码，默认为NO

@property (nonatomic,assign) BOOL enableAutoZoomWhenBarcodeDetectedIsSmall;//扫到的二维码太小，自动拉近扫码距离，默认为NO

@property (nonatomic,assign) BOOL enableAutoZoomWhenNothingDetectedInEightSeconds;//8秒扫码无结果，自动拉进一半距离，默认为NO

@property (nonatomic,assign) BOOL needFocusAlways;//是否需要不停的对焦 开关(扫码需要)

@property (nonatomic,copy) SNCoreScanerBrightnessBlock brightnessBlock;/** 亮暗模式回调 7.1.0*/

// 启动并开始运行
- (void)startReader:(BOOL)isScan;

// 停止运行
- (void)stopReader;

// 停止运行 但是不remove preview layer
- (void)stopReader2;

/*
 * @paras torchMode : 0关，1开
 * @return 操作成功返回YES,否则NO
 */
- (BOOL)torchWithMode:(NSInteger)torchMode;

/*
 * 拍照并获取拍图
 * @return imageData: 拍照后返回的图片数据
 * @return error: 未空表明成功、否则失败 错误描述在eror.localizedDescription
 */
- (void)takePhotoWithComplete:(void (^)(NSData *imageData,NSError *error))complete;


/**
 设置rectOfInterest

 @param size 父view的size
 @param scanRect 扫描区域
 */
- (void)setRectOfInterestWithSize:(CGSize)size scanRect:(CGRect)scanRect scanType:(SNCoreScanerScanType)scanType;


/**
 AR切换session preset

 @param sessionPreset session preset
 */
- (void)changeCaptureSessionPreset:(AVCaptureSessionPreset)sessionPreset;


/**
 添加捏合手势view(拉近拉远)

 @param view view
 */
- (void)passViewForPinchGesture:(UIView *)view;

/**
 调整焦距

 @param zoom 1.0~5.0
 */
- (void)adjustFocusWithZoomFactor:(float)zoom;

@end
