//
//  AXQRCodeVC.m
//  AXiOSTools
//
//  Created by liuweixing on 16/6/12.
//  Copyright © 2016年 liuweixing All rights reserved.
//

#import "AXQRCodeVC.h"
#import <AVFoundation/AVFoundation.h>
#import "SNCoreScaner.h"



@interface AXQRCodeVC ()

@property (nonatomic, strong)AVCaptureSession * session;//输入输出的中间桥梁

@property (nonatomic, strong)  SNCoreScaner *snCoreScaner;
@property (weak, nonatomic) IBOutlet UILabel *codeLabel;

@end

@implementation AXQRCodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"扫一扫";
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        
        
        
    }else{
        
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
