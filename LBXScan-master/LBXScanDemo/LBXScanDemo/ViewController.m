//
//  ViewController.m
//  LBXScanDemo
//
//  Created by AXing on 2019/3/12.
//  Copyright © 2019 lbx. All rights reserved.
//

#import "ViewController.h"
#import "MainViewController.h"
#import "DemoListTableViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}
- (IBAction)btn1:(id)sender {
    DemoListTableViewController* vc = [[DemoListTableViewController alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)btn2:(id)sender {
    MainViewController* vc = [[MainViewController alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
