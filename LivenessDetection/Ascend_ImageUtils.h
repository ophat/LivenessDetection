//  ImageUtils.h
//  TestApp
//
//  Created by Ophat Phuetkasichonphasutha on 12/10/2016.
//  Copyright © 2016 Ophat Phuetkasichonphasutha. All rights reserved.


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include <opencv2/opencv.hpp>


@interface Ascend_ImageUtils : NSObject

+ (cv::Mat) cvMatFromUIImage: (UIImage *) image;
+ (cv::Mat) cvMatGrayFromUIImage: (UIImage *)image;

+ (UIImage *) UIImageFromCVMat: (cv::Mat)cvMat;

+ (UIImage *) turnToBlackAndWhite:(UIImage *)aImage;

+ (UIImage *) resizeToAppropiateSize:(UIImage *)aUIImage Size:(CGSize)aSize;
+ (UIImage *) crop:(UIImage *)aUIImage WithCGRect:(CGRect)aRect;
+ (UIImage *) toPerspective:(UIImage *)aImage;

+ (UIImage *) resizeFile:(UIImage *)aFile w:(float)aW h:(float)aH;
+ (UIImage *) turnImageToJPG:(UIImage *)aFile ;
+ (UIImage *) adjustContrast:(UIImage *)aImage contrast:(float)aValue;
+ (UIImage *) adjustExposure:(UIImage *)aImage exposure:(float)aValue;
+ (UIImage *) adjustSharpen:(UIImage *)aImage sharpen:(float)aValue;
+ (UIImage *) adjustSatuaration:(UIImage *) aImage satuaration:(float)aValue;
+ (UIImage *) adjustShadow : (UIImage *) aImage shadow:(float)aValue;
+ (UIImage *) adjustNoise : (UIImage *) aImage noiselvl:(float)aValue;
+ (UIImage *) binarize : (UIImage *) aImage;

+ (BOOL)isSuitableLight:(UIImage *)aImage;
+ (UIImage*)imageByCombiningImage:(UIImage*)firstImage withImage:(UIImage*)secondImage;

@end
