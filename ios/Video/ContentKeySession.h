//
//  SContentKeySession.h
//  AVARLDelegateDemo
//
//  Created by NguyenVanSao on 8/9/19.
//  Copyright © 2019 rajiv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAssetResourceLoader.h>
#import <AVFoundation/AVAsset.h>

NS_ASSUME_NONNULL_BEGIN

@interface ContentKeySession : NSObject

+ (instancetype)sharedManager;
-(void)addAsset:(AVURLAsset *)asset;
-(void)sendRequest:(NSString *)link;
-(void)addDelegate:(id<AVContentKeySessionDelegate>) delegate;
-(void)removeAsset:(AVURLAsset *)asset;
@end

NS_ASSUME_NONNULL_END
