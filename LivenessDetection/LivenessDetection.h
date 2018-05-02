//
//  LivenessDetection.h
//  LivenessDetection
//
//  Created by Ophat on 19/4/2561 BE.
//  Copyright © 2561 Ophat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <opencv2/videoio/cap_ios.h>
#include <opencv2/objdetect.hpp>
#include <opencv2/imgproc.hpp>

typedef enum : NSInteger {
    kLivenessNone          = 0,
    kLivenessSuccess       = 1,
    kLivenessBlur          = 2,
    kLivenessLightness     = 3,
    kLivenessFaceSpecular  = 4,
    kLivenessEyeMovement   = 5,
    kLivenessFoundSquare   = 6,
    
    kLivenessReset         = 20
} CaseError;

@interface LivenessDetection : NSObject

+(int) exampleSpecularReflectionValidate:(cv::Mat)aImgMat setImageView:(UIImageView *)aImageView scale:(float)aScale FaceCGRect:(CGRect)aFaceRect EyeCGRect:(CGRect)aEyeRect EyeArray:(NSMutableArray *)aEyeArray ;


@end
