//
//  ViewController.m
//  FaceRecognizeDemo
//
//  Created by 刘成 on 17/6/20.
//  Copyright © 2017年 刘成. All rights reserved.
//


#import "ViewController.h"
#import <Photos/Photos.h>
#import "FaceStreamDetectorViewController.h"

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UIImageView *imageView;
    UILabel *tipLabel;
    NSString* gid;
}
@property (strong, nonatomic) UIImagePickerController *pickerController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"人脸识别";
    
    [self initView];
}

- (void)initView{
    
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setTitle:@"选择底片" forState:UIControlStateNormal];
    [leftBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    leftBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    leftBtn.frame = CGRectMake(0, 0, 80, 44);
    leftBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    [leftBtn addTarget:self action:@selector(leftClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:leftBtn];
    
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightBtn setTitle:@"识别" forState:UIControlStateNormal];
    [rightBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    rightBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    rightBtn.frame = CGRectMake(0, 0, 44, 44);
    rightBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    [rightBtn addTarget:self action:@selector(rightClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:rightBtn];
    
    
    tipLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, kWIDTH, 30)];
    tipLabel.textColor = [UIColor redColor];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:tipLabel];
    
    imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 30, kWIDTH, kHEIGHT-94)];
    imageView.backgroundColor = [UIColor lightGrayColor];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
}

- (void)leftClick{
    [self showTakePhotoAcitonSheet];
}

- (void)rightClick{
    
    if (!imageView.image) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"请先选择底片" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    FaceStreamDetectorViewController *faceVC = [[FaceStreamDetectorViewController alloc]init];
    faceVC.myImage = imageView.image;
    faceVC.handle = ^(id result){
        NSString* score = (NSString *)result;
        
        tipLabel.text = [NSString stringWithFormat:@"相似度为%@",score];
    };
    [self.navigationController pushViewController:faceVC animated:YES];
    
}


- (UIImagePickerController *)pickerController{
    
    if (!_pickerController) {
        
        _pickerController = [[UIImagePickerController alloc]init];
        _pickerController.delegate = self;
        _pickerController.allowsEditing = NO;
        
    }
    return _pickerController;
}
- (void)showTakePhotoAcitonSheet{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takePhoto];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"去相册选取" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self pushImagePickerController];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}



/**
 相册
 */
- (void)pushImagePickerController{
    
    if(![self checkLibraryAuthStatus]) return;
    
    
    //判断是否支持相册
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        self.pickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        [self presentViewController:_pickerController animated:YES completion:nil];
    }
}


/**
 拍照
 */
- (void)takePhoto {
    
    if(![self checkLibraryAndCameraAuthStatus]) return;
    
    // 调用相机
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        //系统相机
        self.pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        //设置默认调用后置摄像头
        _pickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        [self presentViewController:_pickerController animated:YES completion:nil];
        
    } else {
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
    }
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *userImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        
        imageView.image = userImage;
        
     }];
    
}



- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if ([picker isKindOfClass:[UIImagePickerController class]]) {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}


/**
 检测相册及相机权限
 
 @return bool
 */
- (BOOL)checkLibraryAndCameraAuthStatus{
    
    if (![self checkLibraryAuthStatus]) {
        return NO;
    }
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ((authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)) {// 拍照之前还需要检查相册权限
        [self showAlertWithTitle:@"无法使用相机" message:@"请在iPhone的""设置-隐私-相机""中允许访问相机"];
        return NO;
    }
    return YES;
}

/**
 检测相册权限
 
 @return bool
 */
- (BOOL)checkLibraryAuthStatus{
    
    
    if ([PHPhotoLibrary authorizationStatus] == 2) { // 已被拒绝，没有相册权限，将无法保存拍的照片
        [self showAlertWithTitle:@"无法访问相册" message:@"请在iPhone的""设置-隐私-相册""中允许访问相册"];
        return NO;
    }
    
    return YES;
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
