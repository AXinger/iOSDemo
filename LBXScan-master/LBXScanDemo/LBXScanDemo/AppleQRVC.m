//
//  AppleQRVC.m
//  LBXScanDemo
//
//  Created by AXing on 2019/3/11.
//  Copyright © 2019 lbx. All rights reserved.
//

#import "AppleQRVC.h"
#import <AVFoundation/AVFoundation.h>
#import "SNCoreScaner.h"

@interface AppleQRVC ()

@property (nonatomic, strong)AVCaptureSession * session;//输入输出的中间桥梁

@property (nonatomic, strong)  SNCoreScaner *snCoreScaner;

/**<#description#>*/
@property (nonatomic, strong) UILabel *codeLabel;
@end

@implementation AppleQRVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"扫一扫";
    
    
    self.codeLabel = [[UILabel alloc]initWithFrame:CGRectMake(100, 100, 100, 40)];
    [self.view addSubview:self.codeLabel];
    self.codeLabel.backgroundColor = [UIColor orangeColor];
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        
        
        
    }else{
        
        self.snCoreScaner = [[SNCoreScaner alloc]init];
        self.snCoreScaner.superPreviewLayer = self.view.layer;
        [self.snCoreScaner passViewForPinchGesture:self.view];
        self.snCoreScaner.enableAutoZoomWhenBarcodeDetectedIsSmall = YES;
        self.snCoreScaner.enableAutoZoomWhenNothingDetectedInEightSeconds = YES;
        self.snCoreScaner.needFocusAlways = YES;
        [self.snCoreScaner adjustFocusWithZoomFactor:1];
        __weak typeof(self) weakSelf = self;
        self.snCoreScaner.avCaptureScanOutputComplete = ^(NSString *stringValue, NSString *type, NSError *error) {
            __strong typeof(weakSelf) self = weakSelf;
            self.codeLabel.text = stringValue;
            NSLog(@"stringValue>> %@",stringValue);
        };
        
        
        [self.snCoreScaner startReader:YES];
        
    }
}



- (AVCaptureSession *)session{
    if (!_session) {
        
        
        //    output.
        //初始化链接对象
        _session = [[AVCaptureSession alloc]init];
        //高质量采集率
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        
    }
    return _session;
}


@end
