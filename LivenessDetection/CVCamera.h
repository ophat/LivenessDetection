//
//  CVCamera.h
//  TestApp
//
//  Created by Ophat Phuetkasichonphasutha on 11/10/2016.
//  Copyright © 2016 Ophat Phuetkasichonphasutha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/videoio/cap_ios.h>
#import <stdio.h>

@protocol CvVideoCameraDelegateMod <CvVideoCameraDelegate>
@end

@interface CVCamera : CvVideoCamera{
}

@property (nonatomic, retain) CALayer *customPreviewLayer;

- (void)updateOrientation;
- (void)layoutPreviewLayer;

@end
