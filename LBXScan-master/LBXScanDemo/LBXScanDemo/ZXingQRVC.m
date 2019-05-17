//
//  ZXingQRVC.m
//  LBXScanDemo
//
//  Created by AXing on 2019/3/11.
//  Copyright © 2019 lbx. All rights reserved.
//

#import "ZXingQRVC.h"
#import "ZXCapture.h"
#import "ZXResult.h"
#import "ZXCaptureDelegate.h"
#import "SNCoreScaner.h"

@interface ZXingQRVC ()<ZXCaptureDelegate>

@property (nonatomic, strong) ZXCapture *capture;

@property (nonatomic, strong) UILabel *codeLabel;

@property (nonatomic, strong)  SNCoreScaner *snCoreScaner;

@end

@implementation ZXingQRVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
//    self.capture = [[ZXCapture alloc] init];
//    self.capture.sessionPreset = AVCaptureSessionPreset1920x1080;
//    self.capture.camera = self.capture.back;
//    self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
//    self.capture.delegate = self;
//    self.capture.layer.frame = self.view.bounds;
//    [self.view.layer addSublayer:self.capture.layer];
//    [self.capture start];
    
    
    
    self.codeLabel = [[UILabel alloc]initWithFrame:CGRectMake(100, 100, 100, 40)];
    [self.view addSubview:self.codeLabel];
    self.codeLabel.backgroundColor = [UIColor orangeColor];
    
    
    self.snCoreScaner = [[SNCoreScaner alloc]init];
    self.snCoreScaner.superPreviewLayer = self.view.layer;
    [self.snCoreScaner passViewForPinchGesture:self.view];
    self.snCoreScaner.enableAutoZoomWhenBarcodeDetectedIsSmall = YES;
    self.snCoreScaner.enableAutoZoomWhenNothingDetectedInEightSeconds = YES;
    self.snCoreScaner.needFocusAlways = YES;
    self.snCoreScaner.enableZXing = YES;
    [self.snCoreScaner adjustFocusWithZoomFactor:1];
    __weak typeof(self) weakSelf = self;
    self.snCoreScaner.avCaptureScanOutputComplete = ^(NSString *stringValue, NSString *type, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        self.codeLabel.text = stringValue;
        NSLog(@"stringValue>> %@",stringValue);
    };
    
    
    [self.snCoreScaner startReader:YES];
    
    
}

- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result {
    NSLog(@"result>> %@",result.text);
    self.codeLabel.text = result.text;
}



@end
