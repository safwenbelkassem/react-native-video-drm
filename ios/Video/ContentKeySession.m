//
//  SContentKeySession.m
//  AVARLDelegateDemo
//
//  Created by NguyenVanSao on 8/9/19.
//  Copyright © 2019 rajiv. All rights reserved.
//

#import "ContentKeySession.h"
#import <AVFoundation/AVFoundation.h>
@interface ContentKeySession()
{
    
}
@property(nonatomic, nullable) AVContentKeySession *sessionKey;
@property(nonatomic, nullable) dispatch_queue_t keyQueue;
@end
@implementation ContentKeySession
-(instancetype) init
{
    self = [super init];
    if (self){
        if (@available(iOS 11.0, *)) {
            _sessionKey = [AVContentKeySession contentKeySessionWithKeySystem:AVContentKeySystemFairPlayStreaming];
        } else {
            // Fallback on earlier versions
            NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
            NSURL *documentsURL = [paths lastObject];
            _sessionKey = [AVContentKeySession contentKeySessionWithKeySystem:AVContentKeySystemFairPlayStreaming storageDirectoryAtURL:documentsURL];
        }
        
        _keyQueue = dispatch_queue_create("com.sigma.fairplay", nil);
    }
    return self;
}

-(void)addAsset:(AVURLAsset *)asset
{
    [_sessionKey addContentKeyRecipient:asset];
 
}


-(void)sendRequest:(NSString *)url
{
    NSLog(@"Received content Key request");

    [_sessionKey processContentKeyRequestWithIdentifier:url initializationData:nil options:nil];

}



-(void)addDelegate:(id<AVContentKeySessionDelegate>) delegate
{
    [_sessionKey setDelegate:delegate queue:_keyQueue];
}
-(void)removeAsset:(AVURLAsset *)asset
{
    [_sessionKey removeContentKeyRecipient:asset];
}
@end
