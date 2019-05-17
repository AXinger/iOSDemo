//
//  ZBarQRVC.m
//  LBXScanDemo
//
//  Created by AXing on 2019/3/11.
//  Copyright © 2019 lbx. All rights reserved.
//

#import "ZBarQRVC.h"
#import "LBXZBarWrapper.h"

@interface ZBarQRVC ()<ZBarReaderDelegate>

/**description*/
@property (nonatomic, strong) UILabel *codeLabel;
@end

@implementation ZBarQRVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
     self.readerDelegate = self;
    
    self.codeLabel = [[UILabel alloc]initWithFrame:CGRectMake(100, 100, 100, 40)];
    [self.view addSubview:self.codeLabel];
    self.codeLabel.backgroundColor = [UIColor orangeColor];
    
}



- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{


    [picker dismissViewControllerAnimated:YES completion:nil];
    
    __block UIImage* image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if (!image){
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    

    UIImage * aImage = image;
    ZBarReaderController *read = [ZBarReaderController new];
    CGImageRef cgImageRef = aImage.CGImage;
    ZBarSymbol* symbol = nil;
    
    NSMutableArray *array = [[NSMutableArray alloc]initWithCapacity:1];
    
    for(symbol in [read scanImage:cgImageRef]){
        
        NSString* strCode = symbol.data;
        
        [array addObject:strCode];
    }
    
    NSLog(@"array>> %@",array);
    self.view.backgroundColor = [UIColor blackColor];
    self.codeLabel.text  = array.firstObject;
}
    
    
    
@end
