





//
//  LivenessDetection.m
//  LivenessDetection
//
//  Created by Ophat on 19/4/2561 BE.
//  Copyright © 2561 Ophat. All rights reserved.
//

#import "LivenessDetection.h"

#import "Ascend_ImageUtils.h"


@implementation LivenessDetection


+(int) exampleSpecularReflectionValidate:(cv::Mat)aImgMat setImageView:(UIImageView *)aImageView scale:(float)aScale FaceCGRect:(CGRect)aFaceRect EyeCGRect:(CGRect)aEyeRect EyeArray:(NSMutableArray *)aEyeArray {
 
    // ############ Blur Detection
    if ([self isImageBlur:aImgMat]) {
        //NSLog(@"***** blur image detected");
        return kLivenessBlur;
    }

//    if ( [self detect_Rectangle_ImageIn:aImgMat]) {
//        //NSLog(@"***** blur image detected");
//        return kLivenessFoundSquare;
//    }
   
    // ############ Eye Movement Detection
    cv::Rect eyeROI(cvPoint(cvRound(aEyeRect.origin.x*aScale),
                            cvRound(aEyeRect.origin.y*aScale)),
                    cvPoint(cvRound((aEyeRect.origin.x + aEyeRect.size.width-1)*aScale),
                            cvRound((aEyeRect.origin.y + aEyeRect.size.height-1)*aScale) - aEyeRect.size.height/3) );
    cv::Mat croppedEyeImage = aImgMat(eyeROI).clone();
    
    UIImage * cropEyeUIImage = [Ascend_ImageUtils UIImageFromCVMat:croppedEyeImage];
    
    //[aImageView setImage:cropEyeUIImage];
    
    CaseError val = [self compareHistogramIris:cropEyeUIImage Array:aEyeArray setImageView:aImageView];
    //NSLog(@"compareHistogramIris %d",val);
    if (val != kLivenessNone) {
        return val;
    }
    
    // ############ Nose Detection
//    cv::Rect noseROI(cvPoint(cvRound(aNoseRect.origin.x*aScale),
//                            cvRound(aNoseRect.origin.y*aScale)),
//                    cvPoint(cvRound((aNoseRect.origin.x + aNoseRect.size.width-1)*aScale),
//                            cvRound((aNoseRect.origin.y + aNoseRect.size.height-1)*aScale) - aEyeRect.size.height/3) );
//    cv::Mat croppedNoseImage = aImgMat(noseROI).clone();
//
//    UIImage * cropNoseUIImage = [Ascend_ImageUtils UIImageFromCVMat:croppedNoseImage];
//
//    [aImageView setImage:cropNoseUIImage];
    
//
//    if (![Ascend_ImageUtils isSuitableLight:[Ascend_ImageUtils UIImageFromCVMat:aImgMat]]) {
//        //NSLog(@"***** Light Prob");
//        return kLivenessLightness;
//    }
    
    // ############ Face Specular Reflection !!! Eat CPU
//    cv::Mat img_gray,img_threshold;
//    cv::Mat blurred(croppedImage);
//    GaussianBlur(croppedImage, blurred, cv::Size(9,9),1000);
//    cvtColor(blurred, img_gray, CV_BGR2GRAY);
//    //cv::threshold(img_gray, img_threshold, 0, 255, CV_THRESH_OTSU+CV_THRESH_BINARY);
//    cv::threshold(img_gray, img_threshold, 127, 255, CV_THRESH_BINARY);
//
//    UIImage * cropThresholdImage = [Ascend_ImageUtils UIImageFromCVMat:img_threshold];
//
//    if (![self checkSpecularLight:cropThresholdImage]) {
//        return kLivenessFaceSpecular;
//    }
    
    if ([aEyeArray count] > 4) {
        return kLivenessSuccess;
    }else{
        return kLivenessNone;
    }
}


+(BOOL)getIris:(cv::Mat)aImage originEyeX:(int *)aOriginEyeX originEyeY:(int *)aOriginEyeY{
    BOOL canGetIris = NO;
    std::vector<cv::Vec3f> circles;
    
    cvtColor(aImage, aImage, CV_BGR2GRAY);
    
    cv::HoughCircles(aImage, circles, CV_HOUGH_GRADIENT, 1, aImage.cols / 8, 250, 15, aImage.rows / 8, aImage.rows / 3);
    
    if (circles.size() > 0){
        cv::Vec3f eyeball = getEyeball(aImage, circles);
        cv::Point center(eyeball[0], eyeball[1]);
        std::vector<cv::Point> centers;
        centers.push_back(center);
        center = stabilize(centers, 5); // we are using the last 5
        
        //cv::circle(aImage, center, 5, cv::Scalar(0, 0, 255), 2);
        
        NSLog(@"**** EYE CO %d %d : %d %d",*aOriginEyeX,*aOriginEyeY,center.x,center.y);
        if (aOriginEyeX == 0 && aOriginEyeY == 0) {
            *aOriginEyeX = center.x;
            *aOriginEyeY = center.y;
        }
        //UIImage * cropEyeUIImage = [Ascend_ImageUtils UIImageFromCVMat:aImage];
        //[aImageView setImage:cropEyeUIImage];
        
        canGetIris = YES;
    }
    return canGetIris;
}

cv::Vec3f getEyeball(cv::Mat &eye, std::vector<cv::Vec3f> &circles)
{
    std::vector<int> sums(circles.size(), 0);
    for (int y = 0; y < eye.rows; y++)
    {
        uchar *ptr = eye.ptr<uchar>(y);
        for (int x = 0; x < eye.cols; x++)
        {
            int value = static_cast<int>(*ptr);
            for (int i = 0; i < circles.size(); i++)
            {
                cv::Point center((int)std::round(circles[i][0]), (int)std::round(circles[i][1]));
                int radius = (int)std::round(circles[i][2]);
                if (std::pow(x - center.x, 2) + std::pow(y - center.y, 2) < std::pow(radius, 2))
                {
                    sums[i] += value;
                }
            }
            ++ptr;
        }
    }
    int smallestSum = 9999999;
    int smallestSumIndex = -1;
    for (int i = 0; i < circles.size(); i++)
    {
        if (sums[i] < smallestSum)
        {
            smallestSum = sums[i];
            smallestSumIndex = i;
        }
    }
    return circles[smallestSumIndex];
}

cv::Point stabilize(std::vector<cv::Point> &points, int windowSize)
{
    float sumX = 0;
    float sumY = 0;
    int count = 0;
    for (int i = std::max(0, (int)(points.size() - windowSize)); i < points.size(); i++)
    {
        sumX += points[i].x;
        sumY += points[i].y;
        ++count;
    }
    if (count > 0)
    {
        sumX /= count;
        sumY /= count;
    }
    return cv::Point(sumX, sumY);
}

+ (CaseError)compareHistogramIris:(UIImage *)aImage Array:(NSMutableArray *)aArrayImages setImageView:(UIImageView *)aImageView{
    @autoreleasepool {
        UIImage * retainImage = [aImage copy];
       
        if ([aArrayImages count] > 4) {
            UIImage * previousImage1 = [aArrayImages objectAtIndex:0];
            UIImage * previousImage2 = [aArrayImages objectAtIndex:1];
            UIImage * previousImage3 = [aArrayImages objectAtIndex:2];
            UIImage * previousImage4 = [aArrayImages objectAtIndex:3];
            
            cv::Mat im_src = [Ascend_ImageUtils cvMatFromUIImage:retainImage];
            cv::Mat im_comp1 = [Ascend_ImageUtils cvMatFromUIImage:previousImage1];
            cv::Mat im_comp2 = [Ascend_ImageUtils cvMatFromUIImage:previousImage2];
            cv::Mat im_comp3 = [Ascend_ImageUtils cvMatFromUIImage:previousImage3];
            cv::Mat im_comp4 = [Ascend_ImageUtils cvMatFromUIImage:previousImage4];
            
            cv::Mat hsv_base;
            cv::Mat hsv_half_down;
            cv::Mat hsv_compare1;
            cv::Mat hsv_compare2;
            cv::Mat hsv_compare3;
            cv::Mat hsv_compare4;
            
            cvtColor( im_src, hsv_base, cv::COLOR_BGR2HSV );
            cvtColor( im_comp1, hsv_compare1, cv::COLOR_BGR2HSV );
            cvtColor( im_comp1, hsv_compare2, cv::COLOR_BGR2HSV );
            cvtColor( im_comp1, hsv_compare3, cv::COLOR_BGR2HSV );
            cvtColor( im_comp1, hsv_compare4, cv::COLOR_BGR2HSV );
            
            hsv_half_down = hsv_base( cv::Range( hsv_base.rows/2, hsv_base.rows - 1 ), cv::Range( 0, hsv_base.cols - 1 ) );

            /// Using 50 bins for hue and 60 for saturation
            int h_bins = 50; int s_bins = 60;
            int histSize[] = { h_bins, s_bins };
            
            // hue varies from 0 to 179, saturation from 0 to 255
            float h_ranges[] = { 0, 180 };
            float s_ranges[] = { 0, 256 };
            
            const float* ranges[] = { h_ranges, s_ranges };
            
            // Use the o-th and 1-st channels
            int channels[] = { 0, 1 };
            
            /// Histograms
            cv::MatND hist_base;
            cv::MatND hist_half_down;
            cv::MatND hist_compare1;
            cv::MatND hist_compare2;
            cv::MatND hist_compare3;
            cv::MatND hist_compare4;
            
            /// Calculate the histograms for the HSV images
            calcHist( &hsv_base, 1, channels, cv::Mat(), hist_base, 2, histSize, ranges, true, false );
            normalize( hist_base, hist_base, 0, 1, cv::NORM_MINMAX, -1, cv::Mat() );
            
            calcHist( &hsv_half_down, 1, channels, cv::Mat(), hist_half_down, 2, histSize, ranges, true, false );
            normalize( hist_half_down, hist_half_down, 0, 1, cv::NORM_MINMAX, -1, cv::Mat() );
            
            calcHist( &hsv_compare1, 1, channels, cv::Mat(), hist_compare1, 2, histSize, ranges, true, false );
            normalize( hist_compare1, hist_compare1, 0, 1, cv::NORM_MINMAX, -1, cv::Mat() );
            
            calcHist( &hsv_compare2, 1, channels, cv::Mat(), hist_compare2, 2, histSize, ranges, true, false );
            normalize( hist_compare2, hist_compare2, 0, 1, cv::NORM_MINMAX, -1, cv::Mat() );
            
            calcHist( &hsv_compare3, 1, channels, cv::Mat(), hist_compare3, 2, histSize, ranges, true, false );
            normalize( hist_compare3, hist_compare3, 0, 1, cv::NORM_MINMAX, -1, cv::Mat() );
            
            calcHist( &hsv_compare4, 1, channels, cv::Mat(), hist_compare4, 2, histSize, ranges, true, false );
            normalize( hist_compare4, hist_compare4, 0, 1, cv::NORM_MINMAX, -1, cv::Mat() );
        
            BOOL isHistogramNotFakeMatched = NO;
    
            for( int i = 0; i < 4; i++ ) {
                int compare_method = i;
                double base_half = compareHist( hist_base, hist_half_down, compare_method );
                double base_compare1 = compareHist( hist_base, hist_compare1, compare_method );
                double base_compare2 = compareHist( hist_base, hist_compare2, compare_method );
                double base_compare3 = compareHist( hist_base, hist_compare3, compare_method );
                double base_compare4 = compareHist( hist_base, hist_compare4, compare_method );
                
                if(i == 2){
                    float xBar = (base_half + base_compare1 + base_compare2 + base_compare3 + base_compare4)/5;
                    NSLog(@"Iris %f ",xBar);
                     if (xBar < 8.0) {
                         isHistogramNotFakeMatched = YES;
                     } 
                }
            }
            
            [aArrayImages removeAllObjects];
            [aArrayImages addObject:retainImage];
            
            if (isHistogramNotFakeMatched) {
                return kLivenessNone;
            }else{
                return kLivenessEyeMovement;
            }
            
        }else{
            [aArrayImages addObject:retainImage];
            
            return kLivenessNone;
        }
    }
    return kLivenessEyeMovement;
}

+ (BOOL)checkSpecularLight:(UIImage *)aImage {
    @autoreleasepool {
        UIImage * retainImage = [aImage copy];
        int MaxTest = 25;
        
        float heightInPoints = retainImage.size.height;
        float heightInPixels = heightInPoints * retainImage.scale;
        
        float widthInPoints = retainImage.size.width;
        float widthInPixels = widthInPoints * retainImage.scale;
        
        float rangeW = widthInPixels  / MaxTest ;
        float rangeH = heightInPixels / MaxTest ;
        
        NSMutableArray * listOfColor = [[NSMutableArray alloc]init];
        
        NSMutableArray * locX = [[NSMutableArray alloc]init];
        NSMutableArray * locY = [[NSMutableArray alloc]init];
        
        for (int i = 0; i <= MaxTest; i++) {
            for (int j=0; j <= MaxTest; j++) {
                [locX addObject:[NSNumber numberWithFloat:j*rangeW]];
                [locY addObject:[NSNumber numberWithFloat:i*rangeH]];
            }
        }
        
        //============ RGX x Bar
        for (int i = 0; i < [locX count]; i++) {
            float x = [[locX objectAtIndex:i] floatValue];
            float y = [[locY objectAtIndex:i] floatValue];
            
            NSMutableArray * ar = [self colorAtPixel:CGPointMake(x,y) aImage:retainImage];
            if (ar) {
                [listOfColor addObject:ar];
            }
        }
        
        //====================================
        int darkCount   = 0;
        int brightCount = 0;
        
        for ( int i =0; i < [listOfColor count]; i++) {
            NSMutableArray * rgb = [listOfColor objectAtIndex:i];
            
            float r = [[rgb objectAtIndex:0] floatValue];
            float g = [[rgb objectAtIndex:1] floatValue];
            float b = [[rgb objectAtIndex:2] floatValue];
            //NSLog(@"rgb %lf %lf %lf",r,g,b);
            if (r < 90 && g < 90 && b < 90) {
                darkCount++;
            }
            
            if (r > 180 && g > 180 && b > 180) {
                brightCount++;
            }
        }
        
        //float matchRealFace = (pow(MaxTest, 2) * 0.70); // 70 % Dark Area # Face not reflect light
        float matchRealFace = [listOfColor count] * 0.35; // 35 % Dark Area # Face not reflect light
        
        //NSLog(@"Bright %d",brightCount);
        //NSLog(@"Dark %d",darkCount);
        
        if (darkCount >  matchRealFace ) {
            //NSLog(@"Dark %d",darkCount);
            return YES;
        }else{
            return NO;
        }
    }
    return NO;
}

+ (NSMutableArray *)colorAtPixel:(CGPoint)point aImage:(UIImage *)aImage{
    @autoreleasepool {
        // Cancel if point is outside image coordinates
        if (!CGRectContainsPoint(CGRectMake(0.0f, 0.0f, aImage.size.width, aImage.size.height), point)) {
            return nil;
        }
        
        CGRect sourceRect = CGRectMake(point.x, point.y, 1, 1);
        CGImageRef cgImage = CGImageCreateWithImageInRect(aImage.CGImage, sourceRect);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        NSUInteger bitsPerComponent = 8;
        int bytesPerPixel = 4;
        int bytesPerRow = bytesPerPixel;
        
        unsigned char pixelData[4] = { 0, 0, 0, 0 };
        
        CGContextRef context = CGBitmapContextCreate(pixelData,
                                                     1,
                                                     1,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorSpace,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        
        
        CGContextDrawImage(context, CGRectMake(0, 0, 1, 1),cgImage);
      
        NSMutableArray * colorArray = [[NSMutableArray alloc]init];
        
        // Convert color values [0..255] to floats [0.0..1.0]
        CGFloat red   = (CGFloat)pixelData[0] ;
        CGFloat green = (CGFloat)pixelData[1] ;
        CGFloat blue  = (CGFloat)pixelData[2] ;
        //CGFloat alpha = (CGFloat)pixelData[3] / 255.0f;
        
        [colorArray addObject:[NSNumber numberWithFloat:red]];
        [colorArray addObject:[NSNumber numberWithFloat:green]];
        [colorArray addObject:[NSNumber numberWithFloat:blue]];
        
        CGImageRelease(cgImage);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        
        return colorArray;
    }
}

+(BOOL)isImageBlur:(cv::Mat)aImgMat{
    
    cv::Mat matImage = aImgMat.clone();
    cv::Mat matImageGrey;
    cv::cvtColor(matImage, matImageGrey, CV_BGRA2GRAY);
    
    cv::Mat dst2 = aImgMat;
    cv::Mat laplacianImage;
    dst2.convertTo(laplacianImage, CV_8UC1);
    cv::Laplacian(matImageGrey, laplacianImage, CV_8U);
    cv::Mat laplacianImage8bit;
    laplacianImage.convertTo(laplacianImage8bit, CV_8UC1);
    
    unsigned char *pixels = laplacianImage8bit.data;
    
    //    unsigned char *pixels = laplacianImage8bit.data;
    int maxLap = -1;
    
    for (int i = 0; i < ( laplacianImage8bit.elemSize()*laplacianImage8bit.total()); i++) {
        if (pixels[i] > maxLap)
            maxLap = pixels[i];
    }
    
    NSLog(@"maxLap : %d",maxLap);
    
    if (maxLap < 160) { // Fix Value
        return YES;
    }else{
        return NO;
    }
    return YES;
}


double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 ) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

+(BOOL) detect_Rectangle_ImageIn:(cv::Mat&)image {
    BOOL isFound = NO;
    
    std::vector<std::vector<cv::Point> >    squares;
    std::vector<std::vector<cv::Point> >    contours;
    
    cv::Mat OriginImage = image.clone();
    
    cv::Mat blurred(image);
    //medianBlur(image, blurred, 5);
    //GaussianBlur(image, blurred, cv::Size(21,21),1000);
    GaussianBlur(image, blurred, cv::Size(9,9),1000);
    //blur(image,blurred, cv::Size(21,21));
    
    //=================================== Canny
    cv::Mat gray;
    cv::Mat gray0(blurred.size(), CV_8U);
    
    for (int c = 0; c < 3; c++) {
        int ch[] = {c, 0};
        mixChannels(&blurred, 1, &gray0, 1, ch, 1);
        
        const int threshold_level = 2;
        for (int l = 0; l < threshold_level; l++) {
            if (l == 0){
                Canny(gray0, gray, 3, 10, 3); //
                // Dilate helps to remove potential holes between edge segments
                dilate(gray, gray,  cv::Mat(), cv::Point(-1,-1));
            }
            else{
                gray = gray0 >= (l+1) * 255 / threshold_level;
            }
            
            // Find contours and store them in a list
            findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
            
            // Test contours
            std::vector<cv::Point> approx;
            for (size_t i = 0; i < contours.size(); i++){
                
                approxPolyDP( cv::Mat(contours[i]), approx, arcLength( cv::Mat(contours[i]), true)*0.02, true);
                double fabv = fabs(contourArea( cv::Mat(approx)));
                double cardSize = 50000;
                
                if (approx.size() >= 4 &&  fabv > cardSize && isContourConvex( cv::Mat(approx)) ){
                    //NSLog(@"pprox.size() %lu",approx.size());
                    //NSLog(@"fabv %lf",fabv);
                    double maxCosine = 0;
                    
                    for (int j = 2; j < 5; j++){
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    if (maxCosine < 0.3){
                        NSLog(@"####### Found SQ");
                        isFound = YES;
                        squares.push_back(approx);
                    }
                }
            }
        }
    }
    
    OriginImage.copyTo(image);
    //=================================== Canny

    return isFound;
}



@end
