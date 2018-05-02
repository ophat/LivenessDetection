//
//  LiveViewController.h
//  TestApp
//
//  Created by Ophat Phuetkasichonphasutha on 10/10/2016.
//  Copyright © 2016 Ophat Phuetkasichonphasutha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/videoio/cap_ios.h>
#include <opencv2/objdetect.hpp>

@class CVCamera;

@interface LiveViewController : UIViewController <CvVideoCameraDelegate>{
    
    CVCamera      *mCamera;
    
    cv::CascadeClassifier mCascadeClassifierFace;
    cv::CascadeClassifier mCascadeClassifierEye;
    
    std::vector<cv::Rect> mFaceRects;
    std::vector<cv::Mat>  mFaceImgs;
    CGFloat               mScale;
    
    NSThread      *mCThread;
    UIImage       *mFaceImage;
    int           mThreadCount;
    int           mFrameCollection;
    
    BOOL          mReady;
    int           mPassValidationCode;
    int           mPassValidationCount;
    int           mResetLimit;
    int           mResetLimitCount;
    

    NSMutableArray *mListEyeIMGs;
    
}

@property (nonatomic,weak)  IBOutlet UIImageView *mUIImageView;
@property (weak, nonatomic) IBOutlet UIImageView *mUITestImage;
@property (weak, nonatomic) IBOutlet UILabel *mText;
@property (weak, nonatomic) IBOutlet UITextView *mLog;

@property (nonatomic,strong) CVCamera *mCamera;
@property (nonatomic,assign) cv::CascadeClassifier mCascadeClassifierFace;
@property (nonatomic,assign) cv::CascadeClassifier mCascadeClassifierEye; 

@property (nonatomic,assign) std::vector<cv::Rect> mFaceRects;
@property (nonatomic,assign) std::vector<cv::Mat>  mFaceImgs;
@property (nonatomic,assign) CGFloat mScale;

@property (nonatomic,strong) NSThread *mCThread;
@property (nonatomic,strong) UIImage  *mFaceImage;

@property (nonatomic,assign) int mThreadCount;
@property (nonatomic,assign) int mFrameCollection;

@property (nonatomic,assign) BOOL mReady;
@property (nonatomic,assign) int  mPassValidationCode;
@property (nonatomic,assign) int  mPassValidationCount;
@property (nonatomic,assign) int  mResetLimit;
@property (nonatomic,assign) int  mResetLimitCount;
 

@property (nonatomic,retain) NSMutableArray *mListEyeIMGs;

@property (nonatomic,retain) id  mDelegate;
@property (nonatomic,assign) SEL mSEL;
@property (nonatomic,assign) SEL mSEL2;
-(void)stopProcess; 

@end
