//
//  ViewController.m
//  color
//
//  Created by pjpjpj on 2017/5/30.
//  Copyright © 2017年 #incloud. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

#import "UIImage+Extension.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (weak, nonatomic) IBOutlet UIView *camareView;
@property (weak, nonatomic) IBOutlet UIImageView *addImgeView;

@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) CALayer *customLayer;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *prevLayer;
@end

@implementation ViewController
{
    UIImagePickerController *controller;
    
    AVCaptureSession *_captureSession;
    UIImageView *_imageView;
    CALayer *_customLayer;
    AVCaptureVideoPreviewLayer *_prevLayer;
}

//- (void)viewDidLoad {
//    [super viewDidLoad];
//
//    controller = [[UIImagePickerController alloc] init];
//    [controller setSourceType:UIImagePickerControllerSourceTypeCamera];
//    [controller setShowsCameraControls:NO];
//    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
//    float aspectRatio = 4.0/3.0;
//    float scale = screenSize.height/screenSize.width * aspectRatio;
//    controller.cameraViewTransform = CGAffineTransformMakeScale(scale, scale);
//    self.camareView = controller.view;
//    [self.view addSubview:self.camareView];
//    [self.view bringSubviewToFront:self.addImgeView];
//}
//
//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initCapture];
}

/**
 * 初始化摄像头
 */
- (void)initCapture {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:device  error:nil];
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc]
                                               init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    // captureOutput.minFrameDuration = CMTimeMake(1, 10);
    
    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
    [captureOutput setSampleBufferDelegate:self queue:queue];
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:captureInput];
    [self.captureSession addOutput:captureOutput];
    [self.captureSession startRunning];
    
    self.customLayer = [CALayer layer];
    CGRect frame = self.view.bounds;
    frame.origin.y = 64;
    frame.size.height = frame.size.height - 64;
    
    self.customLayer.frame = frame;
    self.customLayer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI/2.0f, 0, 0, 1);
    self.customLayer.contentsGravity = kCAGravityResizeAspectFill;
    [self.view.layer addSublayer:self.customLayer];
    
//    self.imageView = [[UIImageView alloc] init];
//    self.imageView.frame = CGRectMake(0, 64, 100, 100);
//    [self.view addSubview:self.imageView];
//    self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
//    self.prevLayer.frame = CGRectMake(100, 64, 100, 100);
//    self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    [self.view.layer addSublayer: self.prevLayer];
    
//    UIButton *back = [[UIButton alloc]init];
//    [back setTitle:@"Back" forState:UIControlStateNormal];
//    [back setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
//    [back sizeToFit];
//    frame = back.frame;
//    frame.origin.y = 25;
//    back.frame = frame;
//    [self.view addSubview:back];
//    [back addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view bringSubviewToFront:self.addImgeView];
}

//-(void)back:(id)sender{
//    [self dismissViewControllerAnimated:true completion:nil];
//}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace,                                                  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    id object = (__bridge id)newImage;
    [self.customLayer performSelectorOnMainThread:@selector(setContents:) withObject: object waitUntilDone:YES];
    
    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
    // release
    CGImageRelease(newImage);
    
    UIColor * color = [image colorAtPixel:CGPointMake(image.size.width / 2, image.size.height / 2)];
    NSLog(@"%@", color);
    
    
    //    [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

- (void)viewDidUnload {
    [self.captureSession stopRunning];
    self.imageView = nil;
    self.customLayer = nil;
    self.prevLayer = nil;
}

@end
