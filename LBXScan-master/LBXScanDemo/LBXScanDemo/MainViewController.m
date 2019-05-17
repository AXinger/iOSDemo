//
//  MainViewController.m
//  LBXScanDemo
//
//  Created by AXing on 2019/3/11.
//  Copyright © 2019 lbx. All rights reserved.
//

#import "MainViewController.h"
#import "AppleQRVC.h"

#import "ZBarQRVC.h"
#import "ZXingQRVC.h"
@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)appleAc:(id)sender {
    
    AppleQRVC *vc = [[AppleQRVC alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)zbarAc:(id)sender {
    ZBarQRVC *vc = [[ZBarQRVC alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)zxingAC:(id)sender {

    
    ZXingQRVC *vc = [[ZXingQRVC alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
