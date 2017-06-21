//
//  LCFaceRecognizeService.m
//  FaceRecognizeDemo
//
//  Created by 刘成 on 17/6/21.
//  Copyright © 2017年 刘成. All rights reserved.
//

#import "LCFaceRecognizeService.h"
#import "IFlyFaceResultKeys.h"
#import "DemoPreDefine.h"
#import "UIImage+Extensions.h"
#import "UIImage+compress.h"

@interface LCFaceRecognizeService ()<IFlyFaceRequestDelegate>
{
    NSString *resultStings;
}
@property (nonatomic,strong) IFlyFaceRequest * iFlySpFaceRequest;

@end

@implementation LCFaceRecognizeService

+ (instancetype)faceRecognizeService{
    static LCFaceRecognizeService *service = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[LCFaceRecognizeService alloc]init];
    });
    return service;
}
- (IFlyFaceRequest *)iFlySpFaceRequest{
    if (!_iFlySpFaceRequest) {
        _iFlySpFaceRequest=[IFlyFaceRequest sharedInstance];
        [_iFlySpFaceRequest setDelegate:self];
    }
    return _iFlySpFaceRequest;
}

- (void)lc_faceRegistWithImage:(UIImage *)image complete:(LCFaceRegHandle)complete{

    _faceRegHandle = complete;
    resultStings = @"";
    
    image = [[image fixOrientation] compressedImage];

    NSData *oldData = [image compressedData];
    [self.iFlySpFaceRequest setParameter:[IFlySpeechConstant FACE_REG] forKey:[IFlySpeechConstant FACE_SST]];
    [self.iFlySpFaceRequest setParameter:USER_APPID forKey:[IFlySpeechConstant APPID]];
    [self.iFlySpFaceRequest setParameter:USER_APPID forKey:@"auth_id"];
    [self.iFlySpFaceRequest setParameter:@"del" forKey:@"property"];
    //  压缩图片大小
    [self.iFlySpFaceRequest sendRequest:oldData];

}

- (void)lc_faceVerifyWithImage:(UIImage *)image gid:(NSString *)gid complete:(LCFaceVerifyHandle)complete{
    
    _faceVerifyHandle = complete;
    resultStings = @"";
    
    image = [[image fixOrientation] compressedImage];

    [self.iFlySpFaceRequest setParameter:[IFlySpeechConstant FACE_VERIFY] forKey:[IFlySpeechConstant FACE_SST]];
    [self.iFlySpFaceRequest setParameter:USER_APPID forKey:[IFlySpeechConstant APPID]];
    [self.iFlySpFaceRequest setParameter:USER_APPID forKey:@"auth_id"];
    [self.iFlySpFaceRequest setParameter:gid forKey:[IFlySpeechConstant FACE_GID]];
    [self.iFlySpFaceRequest setParameter:@"2000" forKey:@"wait_time"];
    //  压缩图片大小
    NSData* imgData=[image compressedData];
    [self.iFlySpFaceRequest sendRequest:imgData];
}

#pragma mark - IFlyFaceRequestDelegate


/**
 * 消息回调
 * @param eventType 消息类型
 * @param params 消息数据对象
 */
- (void) onEvent:(int) eventType WithBundle:(NSString*) params{
    NSLog(@"onEvent | params:%@",params);
}

/**
 * 数据回调，可能调用多次，也可能一次不调用
 * 服务端返回的二进制数据
 */
- (void) onData:(NSData* )data{
    
    NSLog(@"onData | ");
    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"result:%@",result);
    
    if (result) {
        resultStings=[resultStings stringByAppendingString:result];
    }
    
}

/**
 * 结束回调，没有错误时，error为null
 * @param error 错误类型
 */
- (void) onCompleted:(IFlySpeechError*) error{
    
    NSLog(@"onCompleted | error:%@",[error errorDesc]);
    NSString* errorInfo=[NSString stringWithFormat:@"错误码：%d\n 错误描述：%@",[error errorCode],[error errorDesc]];
    if(0!=[error errorCode]){
        [self performSelectorOnMainThread:@selector(showResultInfo:) withObject:errorInfo waitUntilDone:NO];
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateFaceImage:resultStings];
        });
    }
}
-(void)showResultInfo:(NSString*)resultInfo{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"结果" message:resultInfo delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
}

-(void)updateFaceImage:(NSString*)result{
    
    NSError* error;
    NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
    
    if (!resultData) {
        return;
    }
    
    NSDictionary* dic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
    
    if(dic){
        NSString* strSessionType=[dic objectForKey:KCIFlyFaceResultSST];
        
        //注册
        if([strSessionType isEqualToString:KCIFlyFaceResultReg]){
            [self praseRegResult:result];
        }
        
        //验证
        if([strSessionType isEqualToString:KCIFlyFaceResultVerify]){
            [self praseVerifyResult:result];
        }
    }
}
-(void)praseRegResult:(NSString*)result{
    NSString *resultInfo = @"";
    NSString *resultInfoForLabel = @"";
    
    @try {
        NSError* error;
        NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* dic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        
        if(dic){
            NSString* strSessionType=[dic objectForKey:KCIFlyFaceResultSST];
            
            //注册
            if([strSessionType isEqualToString:KCIFlyFaceResultReg]){
                NSString* rst=[dic objectForKey:KCIFlyFaceResultRST];
                NSString* ret=[dic objectForKey:KCIFlyFaceResultRet];
                if([ret integerValue]!=0){
                    resultInfo=[resultInfo stringByAppendingFormat:@"注册错误\n错误码：%@",ret];
                    [self performSelectorOnMainThread:@selector(showResultInfo:) withObject:resultInfo waitUntilDone:NO];
                    if (_faceRegHandle) {
                        _faceRegHandle(NO, nil);
                    }
                }else{
                    if(rst && [rst isEqualToString:KCIFlyFaceResultSuccess]){
                        NSString* gid=[dic objectForKey:KCIFlyFaceResultGID];
                        resultInfo=[resultInfo stringByAppendingString:@"检测到人脸\n注册成功！"];
                        resultInfoForLabel=[resultInfoForLabel stringByAppendingFormat:@"gid:%@",gid];
                        
                        if (_faceRegHandle) {
                            _faceRegHandle(YES, dic);
                        }
                        
                    }else{
                        resultInfo=[resultInfo stringByAppendingString:@"未检测到人脸\n注册失败！"];
                        [self performSelectorOnMainThread:@selector(showResultInfo:) withObject:resultInfo waitUntilDone:NO];
                        if (_faceRegHandle) {
                            _faceRegHandle(NO, nil);
                        }
                    }
                }
            }
            
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
    }
    
    
}

-(void)praseVerifyResult:(NSString*)result{
    NSString *resultInfo = @"";
    NSString *resultInfoForLabel = @"";
    
    @try {
        NSError* error;
        NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* dic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        
        if(dic){
            NSString* strSessionType=[dic objectForKey:KCIFlyFaceResultSST];
            
            if([strSessionType isEqualToString:KCIFlyFaceResultVerify]){
                NSString* rst=[dic objectForKey:KCIFlyFaceResultRST];
                NSString* ret=[dic objectForKey:KCIFlyFaceResultRet];
                if([ret integerValue]!=0){
                    resultInfo=[resultInfo stringByAppendingFormat:@"验证错误\n错误码：%@",ret];
                    if (_faceRegHandle) {
                        _faceRegHandle(NO, nil);
                    }
                }else{
                    
                    if([rst isEqualToString:KCIFlyFaceResultSuccess]){
                        resultInfo=[resultInfo stringByAppendingString:@"检测到人脸\n"];
                    }else{
                        resultInfo=[resultInfo stringByAppendingString:@"未检测到人脸\n"];
                    }
                    NSString* verf=[dic objectForKey:KCIFlyFaceResultVerf];
                    NSString* score=[dic objectForKey:KCIFlyFaceResultScore];
                    if([verf boolValue]){
                        resultInfoForLabel=[resultInfoForLabel stringByAppendingFormat:@"score:%@\n",score];
                        resultInfo=[resultInfo stringByAppendingString:@"验证结果:验证成功!"];
                        if (_faceVerifyHandle) {
                            _faceVerifyHandle(YES, dic);
                        }
                    }else{
                        NSUserDefaults* defaults=[NSUserDefaults standardUserDefaults];
                        NSString* gid=[defaults objectForKey:KCIFlyFaceResultGID];
                        resultInfoForLabel=[resultInfoForLabel stringByAppendingFormat:@"last reg gid:%@\n",gid];
                        resultInfo=[resultInfo stringByAppendingString:@"验证结果:验证失败!"];
                        if (_faceRegHandle) {
                            _faceRegHandle(NO, nil);
                        }
                    }
                }
                
            }
            
            if([resultInfo length]<1){
                resultInfo=@"结果异常";
            }
            
            [self performSelectorOnMainThread:@selector(showResultInfo:) withObject:resultInfo waitUntilDone:NO];
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
        
    }
    
    
}


@end
