//
//  SNCoreScaner.m
//  SuningEBuy
//
//  Created by xzoscar on 15/12/23.
//  Copyright © 2015年 苏宁易购. All rights reserved.
//

#import "SNCoreScaner.h"
#import <AVFoundation/AVFoundation.h>
#import "SNQRCodeDetector.h"

@interface SNCoreScaner () <AVCaptureMetadataOutputObjectsDelegate, SNQRCodeDetectorDelegate> {
    dispatch_queue_t _queue;
    SystemSoundID    _beepSound;
}

// core

@property (nonatomic,strong) AVCaptureStillImageOutput  *stillImageOutput;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *prevLayer;
@property (nonatomic) SNQRCodeDetector *detector;;

// 摄像头是否初始化完成
@property (nonatomic,assign) BOOL captureIsLoadComplete;
// 聚焦定时器
@property (nonatomic,strong) NSTimer *focusTimer;
// 拉伸定时器
@property (nonatomic,strong) NSTimer *zoomTimer;
// 一次扫码处理是否完成
@property (atomic,assign) BOOL onceScanerComplete;

//手势捏合拉近拉远功能
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture;
//初始化initialPinchZoom
@property (nonatomic, assign) CGFloat initialPinchZoom;

@end


@implementation SNCoreScaner

- (void)dealloc
{
    [self stopFocusTimer];
    
#if !OS_OBJECT_USE_OBJC
    if (_queue) dispatch_release(_queue);
#endif
    _queue = NULL;
    if (_beepSound != (SystemSoundID)-1) {
        AudioServicesDisposeSystemSoundID(_beepSound);
    }
}

- (id)init {
    if (self = [super init]) {
        _queue = dispatch_queue_create("com.suning.SNReader", NULL);
        
        {
            // 默认功能都为NO，有需要的手动开启
            _enableSound = NO;
            _enableZXing = NO;
            _enableAutoZoomWhenBarcodeDetectedIsSmall = NO;
            _enableAutoZoomWhenNothingDetectedInEightSeconds = NO;
            
            // 播放声音创建资源
            _beepSound = -1;
            NSURL *aifURL =
            [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"qrcode_find_hint" ofType:@"aif"]];
            OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)aifURL, &_beepSound);
            if (error != kAudioServicesNoError) {
                NSLog(@"Problem loading nearSound.caf");
            }
        }
    }
    return self;
}

- (AVCaptureVideoPreviewLayer *)prevLayer {
    if (nil == _prevLayer
        && nil != _captureSession) {
        _prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
        _prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        // frame
        CGSize size  = [[UIScreen mainScreen] bounds].size;
        CGRect frame = CGRectMake(0, 0, size.width, size.height);
        _prevLayer.frame = frame;
    }
    return _prevLayer;
}

- (NSError *)onInitAVCapture {
    // AVCaptureSession
    self.captureSession = [[AVCaptureSession alloc] init];
    
    // stillImageOutput
    if ([self.captureSession canAddOutput:self.stillImageOutput]) {
        [self.captureSession addOutput:self.stillImageOutput];
    }
    
    // detector
    _detector = [[SNQRCodeDetector alloc] init];
    _detector.delegate = self;
    _detector.enableZXing = _enableZXing;
    NSError *error = [_detector startWithCaptureSession:self.captureSession];
    if (error) {
        return error;
    }
    [_detector enableAutoFocus];
    
    return nil;
}

- (AVCaptureStillImageOutput *)stillImageOutput {
    if (!_stillImageOutput) {
        _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary * outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
        [_stillImageOutput setOutputSettings:outputSettings];
    }
    return _stillImageOutput;
}

// 取消对焦定时器，修改为摄像区域变化后自动对焦
#pragma amrk --- 定时器

- (void)startFocusTimer:(BOOL)isScan {
    if (nil == _focusTimer
        || ![_focusTimer isValid]) {
        if (isScan) {
            _focusTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(reFocus) userInfo:nil repeats:YES];
        }else {
            _focusTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(reFocus) userInfo:nil repeats:YES];
        }
    }
    
    // 8秒扫不到内容，自动拉进一半距离，只调整一次
    if (_enableAutoZoomWhenNothingDetectedInEightSeconds) {
        if (nil == _zoomTimer
            || ![_zoomTimer isValid]) {
            _zoomTimer = [NSTimer scheduledTimerWithTimeInterval:8.0f target:self selector:@selector(rampVideoZoomFactorToHalfMax) userInfo:nil repeats:NO];
        }
    }
}

- (void)stopFocusTimer {
    [_focusTimer invalidate];
    _focusTimer = nil;
    [_zoomTimer invalidate];
    _zoomTimer = nil;
}

// 自动聚焦
- (void)reFocus {
    //过滤拍照购和ar扫得0.5s自动对焦
    if(_needFocusAlways) {
        if (_captureIsLoadComplete) {
            AVCaptureDevice* inputDevice =
            [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            
            [inputDevice lockForConfiguration:nil];
            if ([inputDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                inputDevice.focusMode = AVCaptureFocusModeAutoFocus;
            }
            [inputDevice unlockForConfiguration];
        }
    }
}

// 间隔8秒没扫到结果，拉近到最大能拉近距离的一半，只调整一次
- (void)rampVideoZoomFactorToHalfMax {
    if(_needFocusAlways) {
        // 调整距离
        AVCaptureDevice *captureDevice =[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        CGFloat videoMaxZoomFactor = 3.0f;
        if (captureDevice.activeFormat.videoMaxZoomFactor < videoMaxZoomFactor) {
            videoMaxZoomFactor = captureDevice.activeFormat.videoMaxZoomFactor;
        }
        CGFloat videoZoomFactor = videoMaxZoomFactor/2.0f;
        if (![captureDevice isRampingVideoZoom]
            && captureDevice.videoZoomFactor < videoZoomFactor) {
            AVCaptureDevice *captureDevice =[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            NSError *cerror = nil;
            [captureDevice lockForConfiguration:&cerror];
            // 拉近距离
            CGFloat maxRate = 6.0f;
            CGFloat rate = maxRate*0.5f+(videoZoomFactor-1.0f)*(maxRate*0.5f)/(videoMaxZoomFactor-1.0f);
            [captureDevice rampToVideoZoomFactor:videoZoomFactor withRate:rate];
            // 自动对焦
            if (captureDevice.isFocusPointOfInterestSupported
                && [captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            }
            [captureDevice unlockForConfiguration];
        }
    } else {
        //拍照购 ar扫不需要拉近
        AVCaptureDevice *captureDevice =[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSError *cerror = nil;
        [captureDevice lockForConfiguration:&cerror];
        // 自动对焦一次
        if (captureDevice.isFocusPointOfInterestSupported
            && [captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        [captureDevice unlockForConfiguration];
    }
}

#pragma mark - SNQRCodeDetectorDelegate

- (void)passBuffer4ARScan:(CMSampleBufferRef)sampleBufferRef {
    if(self.AVCaptureScanOutputingBuffer) {
        self.AVCaptureScanOutputingBuffer(sampleBufferRef);
    }
}

- (void)detectorDidDetectBarcode:(NSString *)codeContent codeType:(NSString *)codeType {
    NSLog(@"===== detectorDidDetectBarcode: codeType = %@ codeContent = %@ ", codeType, codeContent);
    if (!_onceScanerComplete && codeContent != nil && codeContent.length > 0) {
        _onceScanerComplete = YES;
        
        NSString *outputString = codeContent;
        NSString *outputType   = codeType;
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.CustomAVCaptureScanOutputComplete) {
                weakSelf.onceScanerComplete = weakSelf.CustomAVCaptureScanOutputComplete(outputString, outputType, nil);
            } else {
                if (nil != weakSelf.avCaptureScanOutputComplete) {
                    [weakSelf stopReader];
                    weakSelf.onceScanerComplete = YES;
                    // 播放声音
                    if (_enableSound
                        && _beepSound != (SystemSoundID)-1) {
                        AudioServicesPlaySystemSound(_beepSound);
                    }
                    NSError *error = nil;
                    if (nil == outputString) {
                        error = [NSError errorWithDomain:@"" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"未识别"}];
                    }
                    weakSelf.avCaptureScanOutputComplete(outputString,outputType,error);
                }
            }
        });
    }

}

- (void)detectorDidDetectDarkImage {
//    NSLog(@"====== didDetectDarkImage");
}

- (void)detectorDidDetectDarkValue:(float)brightnessValue
{
    if(self.brightnessBlock) {
        self.brightnessBlock(brightnessValue);
    }
}

#pragma mark AVCapture action

- (void)startReader:(BOOL)isScan {
    if (_captureIsLoadComplete) {
        if (nil != _captureSession && ![_captureSession isRunning] && _superPreviewLayer) {
            // 重置captureDevice
            AVCaptureDevice *captureDevice =[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            [captureDevice lockForConfiguration:nil];
            captureDevice.videoZoomFactor = 1.0f;
            [captureDevice unlockForConfiguration];
            // 添加layer
            [_superPreviewLayer insertSublayer:self.prevLayer atIndex:0];
            [self.captureSession startRunning];
            
            // 扫到的二维码太小，自动拉近扫码距离
            [_detector setEnableAutoZoomWhenBarcodeDetectedIsSmall:_enableAutoZoomWhenBarcodeDetectedIsSmall];
            
            // 扫码启动完成
            if (self.AVCaptureScanStarted) {
                self.AVCaptureScanStarted();
            }
        }
        // 定时自动聚焦
        [self stopFocusTimer];
        [self startFocusTimer:isScan];
    }else {
        __weak typeof(self) weakSelf = self;
        dispatch_async(_queue, ^{
            NSError *error = [weakSelf onInitAVCapture];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (nil == error) {
                    weakSelf.captureIsLoadComplete = YES;
                    [weakSelf startReader:isScan];
                }
                
                if (nil != weakSelf.AVCaptureInitComplete) {
                    weakSelf.AVCaptureInitComplete(error);
                }
            });
        });
    }
    
    // once action
    _onceScanerComplete = NO;
}

- (void)stopReader {
    
    if (nil != _prevLayer) {
        [_prevLayer removeFromSuperlayer];
    }
    
    [self stopReader2];
    
    // once action
    _onceScanerComplete = YES;
}

// 停止运行 但是不remove preview layer
- (void)stopReader2 {
    
    [self stopFocusTimer];  // 停止聚焦定时
    [self torchWithMode:0]; // 关闭闪关灯
    
    if (nil != _captureSession && [_captureSession isRunning]) {
        __weak typeof(self) weakSelf = self;
//        dispatch_async(dispatch_get_global_queue(0,0), ^{
            [weakSelf.captureSession stopRunning];
//        });
    }
}

/*
 * @paras torchMode : 0关，1开
 * @return 操作成功返回YES,否则NO
 */
- (BOOL)torchWithMode:(NSInteger)torchMode {
    BOOL ret = NO;
    if (_captureIsLoadComplete) {
        AVCaptureDevice* inputDevice =
        [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [inputDevice lockForConfiguration:nil];
        if ([inputDevice hasTorch]) {
            inputDevice.torchMode = torchMode;
            ret = YES;
        }
        [inputDevice unlockForConfiguration];
    }
    return ret;
}

/*
 * 拍照并获取拍图
 * @return imageData: 拍照后返回的图片数据
 * @return error: 未空表明成功、否则失败 错误描述在eror.localizedDescription
 */
- (void)takePhotoWithComplete:(void (^)(NSData *imageData,NSError *error))complete {
    AVCaptureConnection * videoConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (videoConnection != nil) {
        void (^handler)(CMSampleBufferRef imageDataSampleBuffer, NSError *error) =
        ^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            NSData *imageData = nil;
            if (nil == error) {
                imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            }
            
            if (complete != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    complete(imageData,error);
                });
            }
        };
        
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                           completionHandler:handler];
    }else {
        NSDictionary *descp = @{NSLocalizedDescriptionKey:@"初始化失败"};
        NSError *error = [NSError errorWithDomain:@"" code:-1 userInfo:descp];
        complete(nil,error);
    }
}

- (BOOL)isRunning {
    return [_captureSession isRunning];
}

/**
 设置rectOfInterest
 
 @param size 父view的size
 @param scanRect 扫描区域
 */
- (void)setRectOfInterestWithSize:(CGSize)size scanRect:(CGRect)scanRect scanType:(SNCoreScanerScanType)scanType {
    [_detector setRectOfInterestWithSize:size scanRect:scanRect scanType:scanType];
}

- (void)changeCaptureSessionPreset:(AVCaptureSessionPreset)sessionPreset {
    [self.captureSession beginConfiguration];
    if ([self.captureSession canSetSessionPreset:sessionPreset]) {
        self.captureSession.sessionPreset = sessionPreset;
    }
    [self.captureSession commitConfiguration];
}

- (void)setCamera:(int)camera {
    _detector.camera = camera;
}

- (int)camera {
    return _detector.camera;
}

#pragma mark - 捏合手势拉近拉远
- (void)passViewForPinchGesture:(UIView *)view
{
    if(!_pinchGesture) {
        _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognizerClicked:)];
    }
    [view addGestureRecognizer:_pinchGesture];
}

- (void)pinchGestureRecognizerClicked:(UIPinchGestureRecognizer *)pinch
{
    if (!_captureSession) return;
    
    if (pinch.state == UIGestureRecognizerStateBegan) {
        _initialPinchZoom = _detector.captureDevice.videoZoomFactor;
    }

    NSError *error = nil;
    [_detector.captureDevice lockForConfiguration:&error];
    
    if (!error) {
        CGFloat zoomFactor;
        CGFloat scale = pinch.scale;
        if (scale < 1.0f) {
            zoomFactor = _initialPinchZoom - powf(_detector.captureDevice.activeFormat.videoMaxZoomFactor, 1.0f - pinch.scale) + 1;
        }  else {
            zoomFactor = _initialPinchZoom + powf(_detector.captureDevice.activeFormat.videoMaxZoomFactor, (pinch.scale - 1.0f)) - 1;
        }
        
        zoomFactor = MIN(4.0f, zoomFactor);
        zoomFactor = MAX(1.0f, zoomFactor);
        
        _detector.captureDevice.videoZoomFactor = zoomFactor;
        [_detector.captureDevice unlockForConfiguration];
    }
}

- (void)adjustFocusWithZoomFactor:(float)zoom
{
    NSError *error = nil;
    [_detector.captureDevice lockForConfiguration:&error];
    
    if (!error) {
        _detector.captureDevice.videoZoomFactor = zoom;
        [_detector.captureDevice unlockForConfiguration];
    }
}
@end
