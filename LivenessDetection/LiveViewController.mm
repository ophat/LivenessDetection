//
//  OCRViewController.m
//  TestApp
//
//  Created by Ophat Phuetkasichonphasutha on 10/10/2016.
//  Copyright © 2016 Ophat Phuetkasichonphasutha. All rights reserved.
//

#import <opencv2/videoio/cap_ios.h>
#import <CoreGraphics/CoreGraphics.h>

#import "LiveViewController.h"
#import "Ascend_ImageUtils.h"
#import "CVCamera.h" 
#import "LivenessDetection.h"

@implementation LiveViewController
@synthesize mDelegate;
@synthesize mSEL;
@synthesize mSEL2;

@synthesize mCamera;
@synthesize mCascadeClassifierFace;
@synthesize mCascadeClassifierEye; 

@synthesize mFaceRects;
@synthesize mFaceImgs;
@synthesize mScale;

@synthesize mFaceImage;

@synthesize mReady;

@synthesize mUIImageView;
@synthesize mUITestImage;
@synthesize mText;
@synthesize mLog;

@synthesize mCThread;
@synthesize mThreadCount;
@synthesize mFrameCollection;

@synthesize mPassValidationCode;
@synthesize mPassValidationCount;

@synthesize mResetLimit;
@synthesize mResetLimitCount;

@synthesize mListEyeIMGs;

#pragma mark - ViewDidLoad
- (void) viewDidLoad { 
    
    [super viewDidLoad];
    
    mCamera = [[CVCamera alloc] initWithParentView: mUIImageView];
    mCamera.defaultAVCaptureDevicePosition   = AVCaptureDevicePositionFront;
    mCamera.defaultAVCaptureSessionPreset    = AVCaptureSessionPreset1280x720;
    mCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    mCamera.defaultFPS = 30;
    mCamera.grayscaleMode = NO;
    mCamera.delegate = self;
    
    [mCamera lockFocus];
    [mCamera lockBalance];
    //[mCamera lockExposure];
    
    const CFIndex CASCADE_NAME_LEN = 2048;
    char *CASCADE_NAME = (char *) malloc(CASCADE_NAME_LEN);
    
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2" ofType:@"xml"];
    CFStringGetFileSystemRepresentation( (CFStringRef)faceCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);
    mCascadeClassifierFace.load(CASCADE_NAME);
    
    NSString *eyeCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_eye_tree_eyeglasses" ofType:@"xml"];
    CFStringGetFileSystemRepresentation( (CFStringRef)eyeCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);
    mCascadeClassifierEye.load(CASCADE_NAME);
    

    
    free(CASCADE_NAME);
     
    mListEyeIMGs   = [[NSMutableArray alloc]init];
    
    [mText setHidden:YES];
    
    mResetLimit      = 10;
    mResetLimitCount = 0;
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    [self performSelectorOnMainThread:@selector(startOpenCV) withObject:nil waitUntilDone:NO];
}

#pragma mark - Image Processing
-(void)processImage:(cv::Mat &)image {
    @autoreleasepool {
        [NSThread detachNewThreadSelector:@selector(doImageProces:) toTarget:self withObject:[Ascend_ImageUtils UIImageFromCVMat:image]];
    }
}

-(void)doImageProces:(UIImage *)aImage {
    @autoreleasepool {
        if (!mReady) {
            mReady = YES;
            [NSThread detachNewThreadSelector:@selector(doImageProcesOnThread:) toTarget:self withObject:aImage];
            [self performSelectorOnMainThread:@selector(resetIntervalProcessInMainThread) withObject:nil waitUntilDone:NO];
        }
    }
}

-(void)resetIntervalProcessInMainThread{
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(resetIntervalProcess) userInfo:nil repeats:NO];
}

-(void)resetIntervalProcess{
    //NSLog(@"resetIntervalProcess");
    mReady = NO;
}

-(void)doImageProcesOnThread:(UIImage *)aImage{
    mScale = 1.5;
    cv::Mat img = [Ascend_ImageUtils cvMatFromUIImage:aImage];
    [self detectAndDrawFacesOn:img scale:mScale];
}

-(void)stopProcess{
    [self stopOpenCV]; 
}

#pragma mark - Start/Stop
-(void) startOpenCV{
    [mCamera start];
}

-(void) stopOpenCV{
    if (mCamera) {
        if ([mCamera running]) {
            [mCamera stop];
            mCamera = nil;
        }
    }
}

#pragma mark - Face Detection
- (void)detectAndDrawFacesOn:(cv::Mat&) img scale:(double) scale {
    int i = 0;
    double t = 0;
        
    cv::Mat gray, smallImg( cvRound (img.rows/scale), cvRound(img.cols/scale), CV_8UC1 );
    
    cvtColor( img, gray, cv::COLOR_BGR2GRAY );
    resize( gray, smallImg, smallImg.size(), 0, 0, cv::INTER_LINEAR );
    equalizeHist( smallImg, smallImg );
    
    t = (double)cvGetTickCount();
    double scalingFactor = 1.1;
    int minRects = 2;
    cv::Size minSize(30,30);
    
    mCascadeClassifierFace.detectMultiScale( smallImg, mFaceRects,
                                            scalingFactor, minRects, 0,
                                            minSize );
    
    t = (double)cvGetTickCount() - t;
    
    std::vector<cv::Mat> faceImages;
    
    for( std::vector<cv::Rect>::const_iterator r = mFaceRects.begin(); r != mFaceRects.end(); r++, i++ ) {

        CGRect FaceRect = CGRectMake(r->x, r->y, r->width, r->height);
        
        //################ Eye Detect
        std::vector<cv::Rect> eyesObject;
        mCascadeClassifierEye.detectMultiScale( smallImg, eyesObject, scalingFactor, minRects, 0,cv::Size(9, 9) );
        
        int maxEyes = 1; // Right Only
        int countEye = 0;
        CGRect EyeRect = CGRectZero;
        
        for( std::vector<cv::Rect>::const_iterator nr = eyesObject.begin(); nr != eyesObject.end(); nr++ ) {
            if (nr->width > r->width/6 && nr->height > r->height/6) {
                if (countEye < maxEyes ) {
                    // detect only right eye
                    if ( nr->x > (r->width/2) + (r->width/8) ) {
                        EyeRect = CGRectMake(nr->x, nr->y, nr->width, nr->height);
                        countEye++;
                        break;
                    }
                }
            }
        }
        
        //=========================================
        
        cvtColor(img, img, cv::COLOR_RGB2RGBA);
        
        if (mResetLimitCount >= mResetLimit) {
            [self performSelectorOnMainThread:@selector(UpdateRSLog:) withObject:[NSNumber numberWithInt:kLivenessReset] waitUntilDone:NO];
            mPassValidationCount =0;
        }
        
        if (r->width > 300 && r->height > 300 &&
            EyeRect.origin.x >0 && EyeRect.origin.y >0 && EyeRect.size.width >0 && EyeRect.size.height >0 ){
            
            //NSLog(@"** %d %d ||| %d %d %d",r->width,r->height,[mListMouthIMGs count],[mListFaceIMGs count],[mListEyeIMGs count]);
            
            mResetLimitCount = 0;
            
            mPassValidationCode = [LivenessDetection exampleSpecularReflectionValidate:img setImageView:mUITestImage scale:scale FaceCGRect:FaceRect EyeCGRect:EyeRect EyeArray:mListEyeIMGs]; 
            
            if (mPassValidationCode == kLivenessSuccess) {
                if (mPassValidationCount < 0) {
                    mPassValidationCount = 0;
                    [self performSelectorOnMainThread:@selector(TestUpdateRSS:) withObject:@"" waitUntilDone:NO];
                }

                mPassValidationCount++;
                if (mPassValidationCount >= 3 ){
                    [self performSelectorOnMainThread:@selector(TestUpdateRSS:) withObject:@"Pass" waitUntilDone:NO];
                    mFaceImage = [Ascend_ImageUtils UIImageFromCVMat:img];
                   
                    mPassValidationCount = 0;
                    NSLog(@"########## PASSSSSSS");
                }
            }else{
                
                if(mPassValidationCode == kLivenessNone){
                    //NSLog(@"kLivenessNone");
                }else{
                    if (mPassValidationCount > 0) {
                        mPassValidationCount = 0;
                        [self performSelectorOnMainThread:@selector(TestUpdateRSS:) withObject:@"" waitUntilDone:NO];
                    }

                    mPassValidationCount--;
                    if (mPassValidationCount <= -3) {
                        [self performSelectorOnMainThread:@selector(TestUpdateRSS:) withObject:@"Fake" waitUntilDone:NO];
                        NSLog(@"########## Fake");
                        mPassValidationCount = 0;
                    }
                }
            }
            [self performSelectorOnMainThread:@selector(UpdateRSLog:) withObject:[NSNumber numberWithInt:mPassValidationCode] waitUntilDone:NO];
        }else{
            mResetLimitCount ++;
        }
        
        break;
    }
    
    @synchronized(self) {
        mFaceImgs = faceImages;
    }
}

-(void)TestUpdateRSS:(NSString *)aString{
    if([aString length] > 0){
        if([mText isHidden]){
            if([aString isEqualToString:@"Fake"]){
                [mText setTextColor:[UIColor redColor]];
            }else{
                [mText setTextColor:[UIColor greenColor]];
            }
            [mText setText:aString];
            [mText setHidden:NO];
            [self performSelector:@selector(ResetUpdateRSS) withObject:nil afterDelay:2];
        }
    }else{
        if ([mText isHidden]) {
            [mText setText:@""];
        }
    }
}
-(void)ResetUpdateRSS{
    [mText setText:@""];
    [mText setHidden:YES];
}

-(void)UpdateRSLog:(NSNumber *)aCase{
    int LogCase = [aCase intValue];
    //NSLog(@"LogCase %d",LogCase);
    if (LogCase == kLivenessSuccess) {
        [mLog insertText:@"Success\n"];
    }else if (LogCase == kLivenessBlur) {
        [mLog insertText:@"Blur\n"];
    }else if (LogCase == kLivenessLightness) {
        [mLog insertText:@"Lightness\n"];
    }else if (LogCase == kLivenessFaceSpecular) {
        [mLog insertText:@"FaceSpecular\n"];
    } else if (LogCase == kLivenessEyeMovement) {
        [mLog insertText:@"EyeMovement\n"];
    }else if (LogCase == kLivenessFoundSquare) {
        [mLog insertText:@"FoundSquare\n"];
    }else if (LogCase == kLivenessReset) {
        [mLog insertText:@"Reset\n"];
    }
    
    NSRange range = NSMakeRange(mLog.text.length - 1, 1);
    [mLog scrollRangeToVisible:range];
}

@end
