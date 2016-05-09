//
//  ViewController.m
//  testAVFoundation
//
//  Created by 强新宇 on 16/5/9.
//  Copyright © 2016年 强新宇. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>


@interface ViewController () <AVCaptureFileOutputRecordingDelegate>

/**
 *  负责 捕获会话
 */
@property (nonatomic, strong)AVCaptureSession * captureSession;


// 视频输入对象
// 根据输入设备初始化输入对象，用户获取输入数据
@property (nonatomic, strong)AVCaptureDeviceInput * videoCaptureDeviceInput;

//  音频输入对象
//根据输入设备初始化设备输入对象，用于获得输入数据
@property (nonatomic, strong)AVCaptureDeviceInput * audioCaptureDeviceInput;


//初始化输出数据管理对象，如果要拍照就初始化AVCaptureStillImageOutput对象；如果拍摄视频就初始化AVCaptureMovieFileOutput对象。
// 拍摄视频输出对象
// 初始化输出设备对象，用户获取输出数据
@property (nonatomic, strong)AVCaptureMovieFileOutput * caputureMovieFileOutput;


@property (nonatomic, strong)AVCaptureVideoPreviewLayer * captureVideoPreviewLayer;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    //将数据输入对象AVCaptureDeviceInput、数据输出对象AVCaptureOutput添加到媒体会话管理对象AVCaptureSession中。
    // 将视频输入对象添加到会话 (AVCaptureSession) 中
    if ([self.captureSession canAddInput:self.videoCaptureDeviceInput]) {
        [self.captureSession addInput:self.videoCaptureDeviceInput];
    }
    
    // 将音频输入对象添加到会话 (AVCaptureSession) 中
    if ([_captureSession canAddInput:self.audioCaptureDeviceInput]) {
        [_captureSession addInput:self.audioCaptureDeviceInput];
        AVCaptureConnection *captureConnection = [_caputureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        // 标识视频录入时稳定音频流的接受，我们这里设置为自动
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    
    
    //创建视频预览图层AVCaptureVideoPreviewLayer并指定媒体会话，添加图层到显示容器中，调用AVCaptureSession的startRuning方法开始捕获。
    // 通过会话 (AVCaptureSession) 创建预览层
     self.captureVideoPreviewLayer   = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    // 显示在视图表面的图层
    self.view.layer.masksToBounds = true;
    
    _captureVideoPreviewLayer.frame = self.view.layer.bounds;
    _captureVideoPreviewLayer.masksToBounds = true;
    _captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
    [self.view.layer addSublayer:_captureVideoPreviewLayer];
    
    // 让会话（AVCaptureSession）勾搭好输入输出，然后把视图渲染到预览层上
    [_captureSession startRunning];
}
- (IBAction)start:(id)sender {
    

    [(UIButton *)sender setSelected:![(UIButton *)sender isSelected]];
    
    if ([(UIButton *)sender isSelected]) {
        AVCaptureConnection *captureConnection=[self.caputureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        // 开启视频防抖模式
        AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        if ([self.videoCaptureDeviceInput.device.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
            [captureConnection setPreferredVideoStabilizationMode:stabilizationMode];
        }
        
        //如果支持多任务则则开始多任务
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
//            self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        }
        // 预览图层和视频方向保持一致,这个属性设置很重要，如果不设置，那么出来的视频图像可以是倒向左边的。
        captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
        
        // 设置视频输出的文件路径，这里设置为 temp 文件
        NSString *outputFielPath= [NSTemporaryDirectory() stringByAppendingString:@"/movie.mov"];
        
        NSLog(@" -- %@",outputFielPath);
        
        // 路径转换成 URL 要用这个方法，用 NSBundle 方法转换成 URL 的话可能会出现读取不到路径的错误
        NSURL *fileUrl=[NSURL fileURLWithPath:outputFielPath];
        
        // 往路径的 URL 开始写入录像 Buffer ,边录边写
        [self.caputureMovieFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
    }
    else {
        // 取消视频拍摄
        [self.caputureMovieFileOutput stopRecording];
        [self.captureSession stopRunning];
        NSLog(@"取消 视频拍摄");
    }


}



#pragma mark -----------------------------------------------------------
#pragma mark - captureMovieFileOutput Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"---- 开始录制 ----");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"---- 录制结束 ----");
}

#pragma mark -----------------------------------------------------------
#pragma mark - Inner Method

/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    
    NSLog(@"获取设备失败");
    return nil;
}



#pragma mark -----------------------------------------------------------
#pragma mark - Lazy Loading

- (AVCaptureSession *)captureSession
{
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
            [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
        }
    }
    return _captureSession;
}


- (AVCaptureDeviceInput *)videoCaptureDeviceInput
{
    if (!_videoCaptureDeviceInput) {
        NSError * error;
        _videoCaptureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:[self getCameraDeviceWithPosition:AVCaptureDevicePositionBack] error:&error];
        if (error) {
            NSLog(@"初始化视频输入设备失败  %@ ",error);
        }
        
    }
    return _videoCaptureDeviceInput;
}

- (AVCaptureDeviceInput *)audioCaptureDeviceInput
{
    if (!_audioCaptureDeviceInput) {
        NSError * error;
        _audioCaptureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject] error:&error];
        if (error) {
            NSLog(@"初始化音频输入设备失败  %@ ",error);
        }
    }
    return _audioCaptureDeviceInput;
}

- (AVCaptureMovieFileOutput *)caputureMovieFileOutput
{
    if (!_caputureMovieFileOutput) {
        _caputureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    }
    return _caputureMovieFileOutput;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
