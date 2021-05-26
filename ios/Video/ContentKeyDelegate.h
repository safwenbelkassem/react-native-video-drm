//
//  SContentKeyDelegate.h
//  AVARLDelegateDemo
//
//  Created by NguyenVanSao on 8/9/19.
//  Copyright © 2019 rajiv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RCTVideo.h"


NS_ASSUME_NONNULL_BEGIN

//@protocol QnetDelegate <NSObject>
//@optional
//-(void)getCetificateError:(NSError *)err;
//-(void)getLicenseError:(NSError *)err;
//@end

@interface ContentKeyDelegate : NSObject<AVContentKeySessionDelegate>
{
}
@property (nonatomic, retain) NSString *userId;
@property (nonatomic, retain) NSDictionary *Header;
@property (nonatomic, retain) RCTVideo *RCTvideo;

@property (nonatomic, retain) NSString *MainUrl;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *certificateUrl;
@property (nonatomic, retain) NSString *sessionId;
@property (nonatomic, retain) NSString *merchant;
@property (nonatomic, retain) NSString *appId;
@property (nonatomic, assign) BOOL debugMode;

-(NSDictionary *)query: (NSString *)url;
-(void)processOnlineKey:(AVContentKeySession *)session request:(AVPersistableContentKeyRequest *)keyRequest;
-(NSData *)requestKeyFromServer:(NSData *)spcData forAssetId:(NSString *) assetId;
@end

NS_ASSUME_NONNULL_END
