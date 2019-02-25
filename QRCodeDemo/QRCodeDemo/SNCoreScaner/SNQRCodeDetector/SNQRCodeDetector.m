//
//  SNQRCodeDetector.m
//  SNQRCodeDetector
//
//  Created by zhangjie on 2017/9/1.
//  Copyright © 2017年 suning. All rights reserved.
//

#import "SNQRCodeDetector.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import "DetectorHook.h"
#import "ZXingObjC.h"
#import "DetectorHelper.h"

@interface SNQRCodeDetector ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate>


@property (nonatomic, strong) AVCaptureDeviceInput *captureInput;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_queue_t captureQueue;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureOutput;
@property (nonatomic, strong) dispatch_queue_t metaQueue;
@property (nonatomic, strong) AVCaptureMetadataOutput *metaOutput;

@property (nonatomic, strong) id<ZXReader> reader;
@property (nonatomic, strong) ZXDecodeHints *hints;
@property (nonatomic, assign) UIInterfaceOrientation statusBarOrientation;

@end

@implementation SNQRCodeDetector
{
    BOOL needHandleBuffer;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    if (self = [super init]) {
        self.scanRect = CGRectZero;
        self.brightnessThreshold = -1;
        
        self.reader = [ZXMultiFormatReader reader];
        self.hints = [ZXDecodeHints hints];
        self.statusBarOrientation = UIInterfaceOrientationPortrait;
        needHandleBuffer = YES;
    }
    return self;
}

- (NSError *)startWithCaptureSession:(AVCaptureSession *)session {
    // 已有处理队列，返回
    if (_captureQueue) {
        return nil;
    }
    
    self.captureSession = session;
    [DetectorHelper setIsZoommed:NO];
    
    // AVCaptureDeviceInput
    NSError *inputError = [self replaceInput];
    if (nil == self.captureInput || inputError != nil) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"您已关闭相机使用权限，请至手机“设置->隐私->相机”中打开"};
        return ([NSError errorWithDomain:@"" code:-1 userInfo:userInfo]);
    }
    
    //AVCaptureVideoDataOutput
    _captureQueue = dispatch_queue_create("com.suning.qrcodeCaptureQueue", NULL);
    _captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_captureOutput setVideoSettings:@{
                                       (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]
                                       }];
    [_captureOutput setAlwaysDiscardsLateVideoFrames:YES];
    if (_enableZXing) {
        [_captureOutput setSampleBufferDelegate:self queue:_captureQueue];
    }
    if ([self.captureSession canAddOutput:_captureOutput]) {
        [self.captureSession addOutput:_captureOutput];
    }
    
    // AVCaptureMetadataOutput
    _metaQueue = dispatch_queue_create("com.suning.metaCaptureQueue", NULL);
    _metaOutput = [[AVCaptureMetadataOutput alloc] init];
    [_metaOutput setMetadataObjectsDelegate:self queue:_metaQueue];
    if ([self.captureSession canAddOutput:_metaOutput]) {
        [self.captureSession addOutput:_metaOutput];
    }
    // 需要在 captureSession初始化化后调用
    _metaOutput.metadataObjectTypes = [_metaOutput availableMetadataObjectTypes];

    [DetectorHook startHook];
    
    return nil;
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        if (self.delegate) {
            NSString *outputString = nil;
            NSString *outputType   = nil;
            
            BOOL isFound = NO;
            for (AVMetadataMachineReadableCodeObject/*AVMetadataObject*/ *obj in metadataObjects) {
                if ([obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
//                    NSLog(@"SNReader-type:%@,value:%@",obj.type,obj.stringValue);
                    outputString = [obj.stringValue copy];
                    outputType   = [obj.type copy];
                    isFound = YES;
                    break;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(detectorDidDetectBarcode:codeType:)]) {
                    //                        NSLog(@"=========== %@ , %@",codeType, codeContent);
                    [self.delegate detectorDidDetectBarcode:outputString codeType:outputType];
                }
            });
        }
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {

    @autoreleasepool {
        if (self.delegate) {
            if(needHandleBuffer) {
                needHandleBuffer = NO;
                return;
            }
            if([self.delegate respondsToSelector:@selector(passBuffer4ARScan:)]) {
                [self.delegate passBuffer4ARScan:sampleBuffer];
            }
            
            if ([self.delegate respondsToSelector:@selector(detectorDidDetectDarkImage)]) {
                CFDictionaryRef myAttachments = CMGetAttachment(sampleBuffer, kCGImagePropertyExifDictionary, NULL);
                NSString *bri = CFDictionaryGetValue(myAttachments, @"BrightnessValue");
                if (bri) {
//                    NSLog(@"============= 亮度属性: %f", [bri floatValue]);
                    if ([bri floatValue] < self.brightnessThreshold) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate detectorDidDetectDarkImage];
                        });
                    }
                }
            }
            
            if([self.delegate respondsToSelector:@selector(detectorDidDetectDarkValue:)]) {
                CFDictionaryRef myAttachments = CMGetAttachment(sampleBuffer, kCGImagePropertyExifDictionary, NULL);
                NSString *bri = CFDictionaryGetValue(myAttachments, @"BrightnessValue");
                if (bri) {
//                    NSLog(@"============= 亮度属性: %f", [bri floatValue]);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate detectorDidDetectDarkValue:bri.floatValue];
                    });
                }
            }
            
            CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
            
            CGImageRef videoFrameImage = [ZXCGImageLuminanceSource createImageFromBuffer:videoFrame];
            CGImageRef rotatedImage = [self createRotatedImage:videoFrameImage degrees:90];
            CGImageRelease(videoFrameImage);
            
            // If scanRect is set, crop the current image to include only the desired rect
            if (!CGRectIsEmpty(self.scanRect)) {
                CGRect cropRect = [self applyRectOfInterest:self.statusBarOrientation];
                CGImageRef croppedImage = CGImageCreateWithImageInRect(rotatedImage, cropRect);
                CFRelease(rotatedImage);
                rotatedImage = croppedImage;
            }
            
            ZXCGImageLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:rotatedImage];
            CGImageRelease(rotatedImage);
            ZXHybridBinarizer *binarizer = [[ZXHybridBinarizer alloc] initWithSource:source];
            ZXBinaryBitmap *bitmap = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizer];
            NSError *error;
            ZXResult *result = [self.reader decode:bitmap hints:self.hints error:&error];
            if (result) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(detectorDidDetectBarcode:codeType:)]) {
                        NSString *codeContent = result.text;
                        NSString *codeType = [self getBarcodeType:result.barcodeFormat];
//                        NSLog(@"=========== %@ , %@",codeType, codeContent);
                        [self.delegate detectorDidDetectBarcode:codeContent codeType:codeType];
                    }
                });
            }
            needHandleBuffer = YES;
            
        }
    }
}

// Adapted from http://blog.coriolis.ch/2009/09/04/arbitrary-rotation-of-a-cgimage/ and https://github.com/JanX2/CreateRotateWriteCGImage
- (CGImageRef)createRotatedImage:(CGImageRef)original degrees:(float)degrees CF_RETURNS_RETAINED {
    if (degrees == 0.0f) {
        CGImageRetain(original);
        return original;
    } else {
        double radians = degrees * M_PI / 180;
        
#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
        radians = -1 * radians;
#endif
        
        size_t _width = CGImageGetWidth(original);
        size_t _height = CGImageGetHeight(original);
        
        CGRect imgRect = CGRectMake(0, 0, _width, _height);
        CGAffineTransform __transform = CGAffineTransformMakeRotation(radians);
        CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, __transform);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     rotatedRect.size.width,
                                                     rotatedRect.size.height,
                                                     CGImageGetBitsPerComponent(original),
                                                     0,
                                                     colorSpace,
                                                     kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedFirst);
        CGContextSetAllowsAntialiasing(context, FALSE);
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        CGColorSpaceRelease(colorSpace);
        
        CGContextTranslateCTM(context,
                              +(rotatedRect.size.width/2),
                              +(rotatedRect.size.height/2));
        CGContextRotateCTM(context, radians);
        
        CGContextDrawImage(context, CGRectMake(-imgRect.size.width/2,
                                               -imgRect.size.height/2,
                                               imgRect.size.width,
                                               imgRect.size.height),
                           original);
        
        CGImageRef rotatedImage = CGBitmapContextCreateImage(context);
        CFRelease(context);
        
        return rotatedImage;
    }
}

- (CGRect)applyRectOfInterest:(UIInterfaceOrientation)orientation {
    CGFloat scaleVideo, scaleVideoX, scaleVideoY;
    CGFloat videoSizeX, videoSizeY;
    CGRect transformedVideoRect = self.scanRect;
    if([self.captureSession.sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        videoSizeX = 1080;
        videoSizeY = 1920;
    }else if ([self.captureSession.sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]){
        videoSizeX = 720;
        videoSizeY = 1280;
    }else {
        videoSizeX = 480;
        videoSizeY = 640;
    }
    if(UIInterfaceOrientationIsPortrait(orientation)) {
        scaleVideoX = [UIScreen mainScreen].bounds.size.width / videoSizeX;
        scaleVideoY = [UIScreen mainScreen].bounds.size.height / videoSizeY;
        scaleVideo = MAX(scaleVideoX, scaleVideoY);
        if(scaleVideoX > scaleVideoY) {
            transformedVideoRect.origin.y += (scaleVideo * videoSizeY - [UIScreen mainScreen].bounds.size.height) / 2;
        } else {
            transformedVideoRect.origin.x += (scaleVideo * videoSizeX - [UIScreen mainScreen].bounds.size.width) / 2;
        }
    } else {
        scaleVideoX = [UIScreen mainScreen].bounds.size.width / videoSizeY;
        scaleVideoY = [UIScreen mainScreen].bounds.size.height / videoSizeX;
        scaleVideo = MAX(scaleVideoX, scaleVideoY);
        if(scaleVideoX > scaleVideoY) {
            transformedVideoRect.origin.y += (scaleVideo * videoSizeX - [UIScreen mainScreen].bounds.size.height) / 2;
        } else {
            transformedVideoRect.origin.x += (scaleVideo * videoSizeY - [UIScreen mainScreen].bounds.size.width) / 2;
        }
    }
    CGAffineTransform captureSizeTransform = CGAffineTransformMakeScale(1/scaleVideo, 1/scaleVideo);
    return CGRectApplyAffineTransform(transformedVideoRect, captureSizeTransform);
}

- (NSString *)getBarcodeType:(ZXBarcodeFormat)format {
    NSString *type = AVMetadataObjectTypeQRCode;
    switch (format) {
        case kBarcodeFormatAztec:
        {
            type = AVMetadataObjectTypeAztecCode;
        }
            break;
        case kBarcodeFormatCodabar:
        {
            type = @"kBarcodeFormatCodabar";
        }
            break;
        case kBarcodeFormatCode39:
        {
            type = AVMetadataObjectTypeCode39Code;
        }
            break;
        case kBarcodeFormatCode93:
        {
            type = AVMetadataObjectTypeCode93Code;
        }
            break;
        case kBarcodeFormatCode128:
        {
            type = AVMetadataObjectTypeCode128Code;
        }
            break;
        case kBarcodeFormatDataMatrix:
        {
            type = AVMetadataObjectTypeDataMatrixCode;
        }
            break;
        case kBarcodeFormatEan8:
        {
            type = AVMetadataObjectTypeEAN8Code;
        }
            break;
        case kBarcodeFormatEan13:
        {
            type = AVMetadataObjectTypeEAN13Code;
        }
            break;
        case kBarcodeFormatITF:
        {
            type = AVMetadataObjectTypeITF14Code;
        }
            break;
        case kBarcodeFormatPDF417:
        {
            type = AVMetadataObjectTypePDF417Code;
        }
            break;
        case kBarcodeFormatQRCode:
        {
            type = AVMetadataObjectTypeQRCode;
        }
            break;
        case kBarcodeFormatRSS14:
        {
            type = @"kBarcodeFormatRSS14";
        }
            break;
        case kBarcodeFormatRSSExpanded:
        {
            type = @"kBarcodeFormatRSSExpanded";
        }
            break;
        case kBarcodeFormatUPCA:
        {
            type = @"kBarcodeFormatUPCA";
        }
            break;
        case kBarcodeFormatUPCE:
        {
            type = AVMetadataObjectTypeUPCECode;
        }
            break;
        case kBarcodeFormatUPCEANExtension:
        {
            type = @"kBarcodeFormatUPCEANExtension";
        }
            break;
            
        default:
            break;
    }
    return type;
}

#pragma mark enableAutoFocus
- (void)enableAutoFocus {
    [_captureDevice lockForConfiguration:nil];
    if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        _captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
    }
    _captureDevice.subjectAreaChangeMonitoringEnabled = YES;
    [_captureDevice unlockForConfiguration];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:_captureDevice];
}

- (void)subjectAreaDidChange:(NSNotification *)notification {
    //摄像区域改变后自动对焦
    if (self.captureDevice.isFocusPointOfInterestSupported &&[self.captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error =nil;
        [_captureDevice lockForConfiguration:&error];
        [_captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        [_captureDevice unlockForConfiguration];
    }
}

#pragma mark setRectOfInterestWithSize
/**
  设置rectOfInterest

 @param size 父view的size
 @param aRect 扫描区域
 @param scanType 扫描类型
 */
- (void)setRectOfInterestWithSize:(CGSize)size scanRect:(CGRect)aRect scanType:(SNCoreScanerScanType)scanType {
    _scanRect = aRect;
    
    // 扫描以scanRect为中心，以屏幕宽度为宽的扫描区域
    if (scanType == SNCoreScanerScanTypeFullWidth) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        if ([UIScreen mainScreen].bounds.size.height < width) {
            width = [UIScreen mainScreen].bounds.size.height;
        }
        CGFloat frameX = _scanRect.origin.x-(width-_scanRect.size.width)/2.0f;
        CGFloat frameY = _scanRect.origin.y-(width-_scanRect.size.height)/2.0f;
        _scanRect = CGRectMake(frameX, frameY, width, width);
    }
    
    // 设置扫描区域，兼容手机屏幕和相机分辨率
    CGFloat showRatio = size.height/size.width;
    CGFloat captureRatio = 640./480.;
    if (self.captureSession.sessionPreset == AVCaptureSessionPreset1920x1080) {
        captureRatio = 1920./1080.;
    } else if (self.captureSession.sessionPreset == AVCaptureSessionPreset1280x720) {
        captureRatio = 1280./720.;
    }
    if (showRatio < captureRatio) {
        CGFloat fixHeight = size.width * captureRatio;
        CGFloat fixPadding = (fixHeight - size.height)/2;
        CGRect rectOfInterest = CGRectMake((_scanRect.origin.y + fixPadding)/fixHeight,
                                           _scanRect.origin.x/size.width,
                                           _scanRect.size.height/fixHeight,
                                           _scanRect.size.width/size.width);
        _metaOutput.rectOfInterest = rectOfInterest;
    } else {
        CGFloat fixWidth = size.height / captureRatio;
        CGFloat fixPadding = (fixWidth - size.width)/2;
        CGRect rectOfInterest = CGRectMake(_scanRect.origin.y/size.height,
                                           (_scanRect.origin.x + fixPadding)/fixWidth,
                                           _scanRect.size.height/size.height,
                                           _scanRect.size.width/fixWidth);
        _metaOutput.rectOfInterest = rectOfInterest;
    }
}

#pragma mark setCamera
- (void)setCamera:(int)camera {
    _camera = camera;
    
    int currentCamera = 0;
    AVCaptureDevicePosition position = [[self.captureInput device] position];
    if (position == AVCaptureDevicePositionFront) {
        currentCamera = 1;
    }
    if (_camera != currentCamera) {
        [self replaceInput];
    }
}

- (NSError *)replaceInput {
    // newCaptureDevice
    AVCaptureDevice *newCaptureDevice = nil;
    NSError *inputError;
    if (_camera == 0) {
        newCaptureDevice = [self backCamera];
    } else if (_camera == 1) {
        newCaptureDevice = [self frontCamera];
    }
    [newCaptureDevice lockForConfiguration:nil];
    if ([newCaptureDevice hasFlash]) {
        newCaptureDevice.flashMode = AVCaptureFlashModeOff;
    }
    // 增强低光模式
    if (newCaptureDevice.isLowLightBoostSupported) {
        newCaptureDevice.automaticallyEnablesLowLightBoostWhenAvailable = YES;
    }
    [newCaptureDevice unlockForConfiguration];
    
    // newCaptureInput
    AVCaptureDeviceInput *newCaptureInput = [AVCaptureDeviceInput deviceInputWithDevice:newCaptureDevice error:&inputError];
    if (nil == newCaptureInput || inputError != nil) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"您已关闭相机使用权限，请至手机“设置->隐私->相机”中打开"};
        return ([NSError errorWithDomain:@"" code:-1 userInfo:userInfo]);
    }
    
    [self.captureSession beginConfiguration];
    if (self.captureSession && self.captureInput) {
        [self.captureSession removeInput:self.captureInput];
    }
    
    if ([newCaptureInput.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1920x1080]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
    } else if ([newCaptureInput.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    } else if ([newCaptureInput.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    }
    if ([self.captureSession canAddInput:newCaptureInput]) {
        [self.captureSession addInput:newCaptureInput];
        
        self.captureDevice = newCaptureDevice;
        self.captureInput = newCaptureInput;
    } else {
        if (self.captureInput) {
            if ([self.captureInput.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1920x1080]) {
                self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
            } else if ([self.captureInput.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]) {
                self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
            } else if ([self.captureInput.device supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480]) {
                self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
            }
            if ([self.captureSession canAddInput:self.captureInput]) {
                [self.captureSession addInput:self.captureInput];
            }
        }
    }
    
    [self.captureSession commitConfiguration];

    return nil;
}

- (AVCaptureDevice *)frontCamera {
    AVCaptureDevice *inputDevice = [self cameraWithPosition:AVCaptureDevicePositionFront];
    [inputDevice lockForConfiguration:nil];
    if ([inputDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        inputDevice.focusMode = AVCaptureFocusModeAutoFocus;
    }
    [inputDevice unlockForConfiguration];
    return inputDevice;
}

- (AVCaptureDevice *)backCamera {
    AVCaptureDevice *inputDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
    [inputDevice lockForConfiguration:nil];
    if ([inputDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        inputDevice.focusMode = AVCaptureFocusModeAutoFocus;
    }
    [inputDevice unlockForConfiguration];
    return inputDevice;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

#pragma mark setEnableAutoZoomWhenBarcodeDetectedIsSmall
// 扫到的二维码太小，自动拉近扫码距离，默认为NO
- (void)setEnableAutoZoomWhenBarcodeDetectedIsSmall:(BOOL)isEnable {
    [DetectorHelper setEnableAutoZoomWhenBarcodeDetectedIsSmall:isEnable];
}

@end
