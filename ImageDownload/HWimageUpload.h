//
//  HWimageUpload.h
//  ImageDownload
//
//  Created by Kenji SHIMIZU on 2014/05/13.
//  Copyright (c) 2014年 Kenji SHIMIZU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HWimageUpload : NSObject

@property NSString *helloClass;

+ (void)uploadTest;
- (void)uploadingTestTask:(unsigned int)ntryMaxUL;
@property unsigned int ntryMaxUL;
@end



