//
//  FaceStreamDetectorViewController.h
//  IFlyFaceDemo
//
//  Created by 刘成 on 17/6/20.
//  Copyright © 2017年 刘成. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

@protocol FaceDetectorDelegate <NSObject>

@optional

-(void)sendFaceImage:(UIImage *)faceImage; //上传图片成功
-(void)sendFaceImageError; //上传图片失败

@end

typedef void(^LCFaceRecognizeHandle)(id result);

@interface FaceStreamDetectorViewController : UIViewController

@property (strong, nonatomic) UIImage *myImage;//底图的图片

@property (assign,nonatomic) id<FaceDetectorDelegate> faceDelegate;//如果想自己处理后续的识别接口的调用逻辑,则不实现该代理

@property (copy, nonatomic) LCFaceRecognizeHandle handle;

@end
