//
//  LCFaceRecognizeService.h
//  FaceRecognizeDemo
//
//  Created by 刘成 on 17/6/21.
//  Copyright © 2017年 刘成. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^LCFaceRegHandle)(BOOL success, id result);
typedef void(^LCFaceVerifyHandle)(BOOL success, id result);

@interface LCFaceRecognizeService : NSObject

+ (instancetype)faceRecognizeService;

- (void)lc_faceRegistWithImage:(UIImage *)image complete:(LCFaceRegHandle)complete;

- (void)lc_faceVerifyWithImage:(UIImage *)image gid:(NSString *)gid complete:(LCFaceVerifyHandle)complete;

@property (copy, nonatomic) LCFaceRegHandle faceRegHandle;
@property (copy, nonatomic) LCFaceVerifyHandle faceVerifyHandle;

@end
