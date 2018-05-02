//  ImageUtils.mm
//  TestApp
//
//  Created by Ophat Phuetkasichonphasutha on 12/10/2016.
//  Copyright © 2016 Ophat Phuetkasichonphasutha. All rights reserved.

#import <ImageIO/ImageIO.h>

#import "Ascend_ImageUtils.h"
#include "opencv2/core/core_c.h"
#include "opencv2/core/core.hpp"
#include "opencv2/imgproc/imgproc_c.h"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/video/tracking.hpp"
#include "opencv2/features2d/features2d.hpp"
#include "opencv2/flann/flann.hpp"
#include "opencv2/calib3d/calib3d.hpp"
#include "opencv2/objdetect/objdetect.hpp"

@implementation Ascend_ImageUtils

#pragma mark ### Convert
+ (cv::Mat) cvMatFromUIImage: (UIImage *) image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (cv::Mat) cvMatGrayFromUIImage: (UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (UIImage *) UIImageFromCVMat: (cv::Mat)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1)
    {
        colorSpace = CGColorSpaceCreateDeviceGray();
    }
    else
    {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,//bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

#pragma mark ### Color Change
+(UIImage *) turnToBlackAndWhite:(UIImage *)aImage{
    
    //==== Remove noise
    cv::Mat rgb = [Ascend_ImageUtils cvMatFromUIImage:gs_convert_image(aImage)];
    cv::fastNlMeansDenoisingColored(rgb,rgb,3,10,7,21);
    
    //Most Accurrate
    cv::Mat gray;
    cvtColor(rgb,gray,CV_RGB2GRAY);
    
    cv::threshold(gray, gray, 0, 255, CV_THRESH_BINARY + cv::THRESH_OTSU);
    //equalizeHist( gray, gray );

    cv::bitwise_not(gray, gray);
    cv::Mat element = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(3,3));
    cv::erode(gray, gray, element);
    cv::bitwise_not(gray, gray);

    return [Ascend_ImageUtils UIImageFromCVMat:gray];
    
}

#pragma mark ### Resize
UIImage * gs_convert_image (UIImage * src_img) {
    CGColorSpaceRef d_colorSpace = CGColorSpaceCreateDeviceRGB();
    
    size_t d_bytesPerRow = src_img.size.width * 4;
    unsigned char * imgData = (unsigned char*)malloc(src_img.size.height*d_bytesPerRow);
    CGContextRef context =  CGBitmapContextCreate(imgData, src_img.size.width,
                                                  src_img.size.height,
                                                  8, d_bytesPerRow,
                                                  d_colorSpace,
                                                  kCGImageAlphaNoneSkipFirst);
    
    UIGraphicsPushContext(context);
    // These next two lines 'flip' the drawing so it doesn't appear upside-down.
    CGContextTranslateCTM(context, 0.0, src_img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    // Use UIImage's drawInRect: instead of the CGContextDrawImage function, otherwise you'll have issues when the source image is in portrait orientation.
    [src_img drawInRect:CGRectMake(0.0, 0.0, src_img.size.width, src_img.size.height)];
    UIGraphicsPopContext();
    
    // After we've processed the raw data, turn it back into a UIImage instance.
    CGImageRef new_img = CGBitmapContextCreateImage(context);
    UIImage * convertedImage = [[UIImage alloc] initWithCGImage:
                                new_img];
    
    CGImageRelease(new_img);
    CGContextRelease(context);
    CGColorSpaceRelease(d_colorSpace);
    free(imgData);
    return convertedImage;
}

+(UIImage *) resizeToAppropiateSize:(UIImage *)aUIImage Size:(CGSize)aSize{
    UIGraphicsBeginImageContextWithOptions(aSize, NO, 0.0);
    [aUIImage drawInRect:CGRectMake(0, 0, aSize.width, aSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+(UIImage *) crop:(UIImage *)aUIImage WithCGRect:(CGRect)aRect{
    CGImageRef imageRef = CGImageCreateWithImageInRect([aUIImage CGImage],aRect);
    UIImage * cropImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef); 
    return cropImage;
}

#pragma mark ### Transform

+(UIImage *) toPerspective:(UIImage *)aImage{
   
    cv::Point2f inputQ[4];
    cv::Point2f outputQ[4];
    
    cv::Mat input = [self cvMatFromUIImage:aImage];
        
    cv::Mat lambda( 2, 4, CV_32FC1 );
    cv::Mat output;
    
    // Set the lambda matrix the same type and size as input
    lambda = cv::Mat::zeros( input.rows, input.cols, input.type() );
    
    // The 4 points that select quadilateral on the input , from top-left in clockwise order
    // These four pts are the sides of the rect box used as input
    inputQ[0] =  cv::Point2f( -30,-60 );
    inputQ[1] =  cv::Point2f( input.cols+50,-50);
    inputQ[2] =  cv::Point2f( input.cols+100,input.rows+50);
    inputQ[3] =  cv::Point2f( -50,input.rows+50  );
    // The 4 points where the mapping is to be done , from top-left in clockwise order
    outputQ[0] =  cv::Point2f( 0,0 );
    outputQ[1] =  cv::Point2f( input.cols-1,0);
    outputQ[2] =  cv::Point2f( input.cols-1,input.rows-1);
    outputQ[3] =  cv::Point2f( 0,input.rows-1  );
    
    // Get the Perspective Transform Matrix i.e. lambda
    lambda = getPerspectiveTransform( inputQ, outputQ );
    // Apply the Perspective Transform just found to the src image
    warpPerspective(input,output,lambda,output.size() );
    
    return [self UIImageFromCVMat:output];
}

+(UIImage *)turnImageToJPG:(UIImage *)aFile {
    
    NSData *imgData = UIImageJPEGRepresentation(aFile, 1.0);
    //NSLog(@"File size is : %.2f MB",(float)imgData.length/1024.0f/1024.0f);
    UIImage * toJPG = [UIImage imageWithData:imgData];
    
    return toJPG;
}

+(UIImage *)resizeFile:(UIImage *)aFile w:(float)aW h:(float)aH{
    
    UIImage * resized = [Ascend_ImageUtils resizeToAppropiateSize:aFile Size:CGSizeMake(aW, aH)];
    NSData *imgData = UIImageJPEGRepresentation(resized, 1.0);
    //NSLog(@"File size is : %.2f MB",(float)imgData.length/1024.0f/1024.0f);
    resized = [UIImage imageWithData:imgData];
    
    return resized;
}

#pragma mark ### Core IM

+(UIImage *)adjustContrast:(UIImage *)aImage contrast:(float)aValue {
    @autoreleasepool {
        CIImage *inputImage = [[CIImage alloc] initWithImage:aImage];
        CIFilter *exposureAdjustmentFilter = [CIFilter filterWithName:@"CIColorControls"];
        [exposureAdjustmentFilter setDefaults];
        [exposureAdjustmentFilter setValue:inputImage forKey:@"inputImage"];
        [exposureAdjustmentFilter setValue:[NSNumber numberWithFloat:aValue] forKey:@"inputContrast"];
        CIImage *outputImage = [exposureAdjustmentFilter valueForKey:@"outputImage"];
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef imgRef = [context createCGImage:outputImage fromRect:outputImage.extent];
        UIImage * newImage = [[UIImage alloc]initWithCGImage:imgRef];
        CGImageRelease(imgRef);
        
        return newImage;
    }
}


+(UIImage *)adjustExposure:(UIImage *)aImage exposure:(float)aValue {
    @autoreleasepool {
        CIImage *inputImage = [[CIImage alloc] initWithImage:aImage];
        CIFilter *exposureAdjustmentFilter = [CIFilter filterWithName:@"CIExposureAdjust"];
        [exposureAdjustmentFilter setDefaults];
        [exposureAdjustmentFilter setValue:inputImage forKey:@"inputImage"];
        [exposureAdjustmentFilter setValue:[NSNumber numberWithFloat:aValue] forKey:@"inputEV"];
        CIImage *outputImage = [exposureAdjustmentFilter valueForKey:@"outputImage"];
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef imgRef = [context createCGImage:outputImage fromRect:outputImage.extent];
        UIImage * newImage = [[UIImage alloc]initWithCGImage:imgRef];
        CGImageRelease(imgRef);
        
        return newImage;
    }
}

+(UIImage *)adjustSharpen:(UIImage *)aImage sharpen:(float)aValue {
    @autoreleasepool {
        CIImage *inputImage = [[CIImage alloc] initWithImage:aImage];
        CIFilter *exposureAdjustmentFilter = [CIFilter filterWithName:@"CISharpenLuminance"];
        [exposureAdjustmentFilter setDefaults];
        [exposureAdjustmentFilter setValue:inputImage forKey:@"inputImage"];
        [exposureAdjustmentFilter setValue:[NSNumber numberWithFloat:aValue] forKey:@"inputSharpness"];
        CIImage *outputImage = [exposureAdjustmentFilter valueForKey:@"outputImage"];
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef imgRef = [context createCGImage:outputImage fromRect:outputImage.extent];
        UIImage * newImage = [[UIImage alloc]initWithCGImage:imgRef];
        CGImageRelease(imgRef);
        
        return newImage;
    }
}

+(UIImage *)adjustSatuaration : (UIImage *) aImage satuaration:(float)aValue {
    @autoreleasepool {
        CIImage *inputImage = [[CIImage alloc] initWithImage:aImage];
        CIFilter *colorControlsFilter = [CIFilter filterWithName:@"CIColorControls"];
        [colorControlsFilter setDefaults];
        [colorControlsFilter setValue:inputImage forKey:@"inputImage"];
        [colorControlsFilter setValue:[NSNumber numberWithFloat:aValue] forKey:@"inputSaturation"];
        CIImage *outputImage = [colorControlsFilter valueForKey:@"outputImage"];
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef imgRef = [context createCGImage:outputImage fromRect:outputImage.extent];
        UIImage * newImage = [[UIImage alloc]initWithCGImage:imgRef];
        CGImageRelease(imgRef);
        
        return newImage;
    }
}

+(UIImage *)adjustShadow : (UIImage *) aImage shadow:(float)aValue {
    @autoreleasepool {
        CIImage *inputImage = [[CIImage alloc] initWithImage:aImage];
        CIFilter *colorControlsFilter = [CIFilter filterWithName:@"CIHighlightShadowAdjust"];
        [colorControlsFilter setDefaults];
        [colorControlsFilter setValue:inputImage forKey:@"inputImage"];
        [colorControlsFilter setValue:[NSNumber numberWithFloat:aValue] forKey:@"inputShadowAmount"];
        CIImage *outputImage = [colorControlsFilter valueForKey:@"outputImage"];
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef imgRef = [context createCGImage:outputImage fromRect:outputImage.extent];
        UIImage * newImage = [[UIImage alloc]initWithCGImage:imgRef];
        CGImageRelease(imgRef);
        
        return newImage;
    }
}

+(UIImage *)adjustNoise : (UIImage *) aImage noiselvl:(float)aValue {
    @autoreleasepool {
        CIImage *inputImage = [[CIImage alloc] initWithImage:aImage];
        CIFilter *colorControlsFilter = [CIFilter filterWithName:@"CINoiseReduction"];
        [colorControlsFilter setDefaults];
        [colorControlsFilter setValue:inputImage forKey:@"inputImage"];
        [colorControlsFilter setValue:[NSNumber numberWithFloat:aValue] forKey:@"inputNoiseLevel"];
        CIImage *outputImage = [colorControlsFilter valueForKey:@"outputImage"];
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef imgRef = [context createCGImage:outputImage fromRect:outputImage.extent];
        UIImage * newImage = [[UIImage alloc]initWithCGImage:imgRef];
        CGImageRelease(imgRef);
        
        return newImage;
    }
}

+(BOOL)isSuitableLight:(UIImage *)aImage{
    @autoreleasepool { 
        int MaxTest = 50;
        
        float heightInPoints = aImage.size.height;
        float heightInPixels = heightInPoints * aImage.scale;
        
        float widthInPoints = aImage.size.width;
        float widthInPixels = widthInPoints * aImage.scale;
        
        float rangeW = widthInPixels  / MaxTest ;
        float rangeH = heightInPixels / MaxTest ;
        
        NSMutableArray * listOfColor = [[NSMutableArray alloc]init];
        
        NSMutableArray * locX = [[NSMutableArray alloc]init];
        NSMutableArray * locY = [[NSMutableArray alloc]init];
        for (int i = 1; i <= MaxTest -1 ; i++) {
            //NSLog(@"rw: %lf %lf",i*rangeW,i*rangeH);
            [locX addObject:[NSNumber numberWithFloat:i*rangeW]];
            [locY addObject:[NSNumber numberWithFloat:i*rangeH]];
        }
        
        for (int i = MaxTest - 1 ; i > 1; i--) {
            float tempW = (i * rangeW);
            float tempH = (i * rangeW);
            //NSLog(@"rl: %lf %lf",tempW,tempH);
            [locX addObject:[NSNumber numberWithFloat:tempW]];
            [locY addObject:[NSNumber numberWithFloat:tempH]];
        }
        
        //============ RGX x Bar
        for (int i=0; i < [locX count]; i++) {
            float x = [[locX objectAtIndex:i] floatValue];
            float y = [[locY objectAtIndex:i] floatValue];
            
            NSArray * ar = [self getRGBAsFromImage:aImage atX:x andY:y count:1];
            [listOfColor addObject:ar];
        }
        
        //====================================
        int darkCount   = 0;
        int brightCount = 0;
        for ( int i =0; i < [listOfColor count]; i++) {
            NSMutableArray * hrgb = [listOfColor objectAtIndex:i];
            NSMutableArray * rgb = [hrgb objectAtIndex:0];
            
            //NSLog(@"rgb %@ %d",rgb,[rgb count]);
            float r = [[rgb objectAtIndex:0] floatValue];
            float g = [[rgb objectAtIndex:1] floatValue];
            float b = [[rgb objectAtIndex:2] floatValue];
            
            if (r < 90 && g < 90 && b < 90) {
                darkCount++;
            }
            
            if (r > 180 && g > 180 && b > 180) {
                brightCount++;
            }
        }
        
        float ratioLight = ((MaxTest*2) * 0.7); // 70 % Light / Dark Area
        
        if (brightCount > ratioLight ) {
            //NSLog(@"Too Bright %d",brightCount);
            return NO;
        }
        if (darkCount >  ratioLight ) {
            //NSLog(@"Too Dark %d",darkCount);
            return NO;
        }
        return YES;
    }
}

+(UIImage *)binarize : (UIImage *) aImage {
    @autoreleasepool {
        CIImage *inputImage = [[CIImage alloc] initWithImage:aImage];
        CIFilter *exposureAdjustmentFilter = [CIFilter filterWithName:@"CIPhotoEffectMono"];
        [exposureAdjustmentFilter setDefaults];
        [exposureAdjustmentFilter setValue:inputImage forKey:@"inputImage"];
        CIImage *outputImage = [exposureAdjustmentFilter valueForKey:@"outputImage"];
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef imgRef = [context createCGImage:outputImage fromRect:outputImage.extent];
        UIImage * newImage = [[UIImage alloc]initWithCGImage:imgRef];
        CGImageRelease(imgRef);
        
        return newImage;
    }
}

+ (NSArray*)getRGBAsFromImage:(UIImage*)image atX:(int)x andY:(int)y count:(int)count {
    @autoreleasepool {
        
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
        
        // First get the image into your data buffer
        CGImageRef imageRef = [image CGImage];
        NSUInteger width = CGImageGetWidth(imageRef);
        NSUInteger height = CGImageGetHeight(imageRef);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * width;
        NSUInteger bitsPerComponent = 8;
        CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                     bitsPerComponent, bytesPerRow, colorSpace,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGContextRelease(context);
        
        // Now your rawData contains the image data in the RGBA8888 pixel format.
        NSUInteger byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
        for (int i = 0 ; i < count ; ++i)
        {
            CGFloat alpha = ((CGFloat) rawData[byteIndex + 3] ) / 255.0f;
            CGFloat red   = ((CGFloat) rawData[byteIndex]     ) / alpha;
            CGFloat green = ((CGFloat) rawData[byteIndex + 1] ) / alpha;
            CGFloat blue  = ((CGFloat) rawData[byteIndex + 2] ) / alpha;
            byteIndex += bytesPerPixel;
            
            NSMutableArray * rgbRange = [[NSMutableArray alloc]init];
            [rgbRange addObject:[NSNumber numberWithFloat:red]];
            [rgbRange addObject:[NSNumber numberWithFloat:green]];
            [rgbRange addObject:[NSNumber numberWithFloat:blue]];
            
            [result addObject:rgbRange];
        }
        
        free(rawData);
        
        return result;
    }
}

+ (UIImage*)imageByCombiningImage:(UIImage*)firstImage withImage:(UIImage*)secondImage {
    @autoreleasepool {
        UIImage *image = nil;
        
        CGSize newImageSize = CGSizeMake( MAX(firstImage.size.width, secondImage.size.width) * 2,
                                          MAX(firstImage.size.height , secondImage.size.height) * 2);
        UIGraphicsBeginImageContext(newImageSize);
        
        [firstImage drawAtPoint:CGPointMake(0,0)];
        [secondImage drawAtPoint:CGPointMake(firstImage.size.width, 0)];
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image;
    }
}



@end
