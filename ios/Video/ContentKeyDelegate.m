//
//  QContentKeyDelegate.m
//  AVARLDelegateDemo
//
//  Created by NguyenVanSao on 8/9/19.
//  Copyright © 2019 rajiv. All rights reserved.
//
#import <CommonCrypto/CommonDigest.h> // Need to import for CC_MD5 access
#import "ContentKeyDelegate.h"
#import "RCTVideo.h"
@interface ContentKeyDelegate()
@end


@implementation ContentKeyDelegate
#pragma AVContentKeySession Delegate
- (void)contentKeySession:(AVContentKeySession *)session didProvidePersistableContentKeyRequest:(AVPersistableContentKeyRequest *)keyRequest
{
    NSLog(@"Received content Key request");
    [self handleContentKeyRequest:session request:keyRequest];
}
- (void)contentKeySession:(AVContentKeySession *)session didProvideRenewingContentKeyRequest:(AVPersistableContentKeyRequest *)keyRequest
{
    [self handleContentKeyRequest:session request:keyRequest];
}
- (void)contentKeySession:(AVContentKeySession *)session contentKeyRequest:(AVPersistableContentKeyRequest *)keyRequest didFailWithError:(NSError *)err
{
    [self->_RCTvideo DispatchDownloadError];
    NSLog(@"contentKeySession: %@", err);
}
- (BOOL)contentKeySession:(AVContentKeySession *)session shouldRetryContentKeyRequest:(AVContentKeyRequest *)keyRequest reason:(AVContentKeyRequestRetryReason)retryReason
{
    NSLog(@"failed for some reason");
    return retryReason == AVContentKeyRequestRetryReasonTimedOut ||
        retryReason == AVContentKeyRequestRetryReasonReceivedResponseWithExpiredLease ||
        retryReason == AVContentKeyRequestRetryReasonReceivedObsoleteContentKey;
}
- (void)contentKeySession:(AVContentKeySession *)session contentKeyRequestDidSucceed:(AVContentKeyRequest *)keyRequest
{
    
}
- (void)contentKeySessionContentProtectionSessionIdentifierDidChange:(AVContentKeySession *)session
{
    
}

- (void)contentKeySession:(nonnull AVContentKeySession *)session didProvideContentKeyRequest:(nonnull AVPersistableContentKeyRequest *)keyRequest {
    
    [keyRequest respondByRequestingPersistableContentKeyRequest];
}

- (void)contentKeySessionDidGenerateExpiredSessionReport:(AVContentKeySession *)session
{
    
}




/// Implement
-(void)handleContentKeyRequest:(AVContentKeySession *)session request:(AVPersistableContentKeyRequest *)keyRequest
{
    NSLog(@"Handling non persistance key  request for acount with ID %@",_accountID);
    NSString *keyAssetID = [_url stringByAppendingString:_accountID];
    NSString *assetIDString = [[NSURL alloc] initWithString:keyAssetID].absoluteString;
    NSLog(@"Key asset ID : @%",assetIDString);

    do {
        if (![self contentKeyLocationForAsset:assetIDString error:nil]) {
            NSLog(@"doesn't exist");
            break;
           
        }
        
        NSData* data = [self loadPersistentContentKeyForAsset:assetIDString error:nil];
        
        NSLog(@"data log %@",data);
        if (data == nil){
            break;
        }

        AVContentKeyResponse *response = [AVContentKeyResponse contentKeyResponseWithFairPlayStreamingKeyResponseData:data];
        [keyRequest processContentKeyResponse:response];
        [self->_RCTvideo executemydownloadtask];
     
        return;
    }
    while (FALSE);
    // Request Key Online
  
    [self processOnlineKey:session request:keyRequest assetIDString:assetIDString];
    

}




-(NSData*)loadPersistentContentKeyForAsset:(NSString*)assetId error:(NSError**)error {
    
    NSURL* url = [self contentKeyLocationForAsset:assetId error:error];
    NSLog(@"we are reading key from %@",url);
    if (!url) {
      //  KPLogError(@"Can't get contentkey location. Error: %@", *error);
        return nil;
    }
    
    NSError* readError;
    NSData* data = [NSData dataWithContentsOfURL:url options:0 error:&readError];
    
    if (!data) {
        if (readError.domain != NSCocoaErrorDomain || readError.code != NSFileReadNoSuchFileError) {
            // NSFileReadNoSuchFileError is expected in this context; something else is more serious.
            *error = readError;
        }
    }
    
    return data;
}



-(void)processOnlineKey:(AVContentKeySession *)session request:(AVPersistableContentKeyRequest *)keyRequest assetIDString:(NSString *)assetIDString
{
    NSLog(@"Persistance ");

 
    
    NSURL *certificateURL = [NSURL URLWithString:[@"https://swann.k8s.satoripop.io/fps.cer" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSData *certificate = [NSData dataWithContentsOfURL:certificateURL];
    if (!certificate){
        NSLog(@"certificate Data Error!");
        [self->_RCTvideo DispatchDownloadError];

        [keyRequest processContentKeyResponseError:nil];
    }else{
        
  
    
    [keyRequest makeStreamingContentKeyRequestDataForApp:certificate contentIdentifier:[NSData dataWithBytes:[assetIDString UTF8String] length:[assetIDString length]] options:@{AVContentKeyRequestProtocolVersionsKey: @[[NSNumber numberWithInt:1]]} completionHandler:^(NSData * _Nullable contentKeyRequestData, NSError * _Nullable error) {
        // Check validate
       
        NSData *licenseData = [self requestKeyFromServer:contentKeyRequestData forAssetId:assetIDString];
        if (error){
            NSLog(@"License Data Error!");
            [self->_RCTvideo DispatchDownloadError];

            [keyRequest processContentKeyResponseError:error];
        }
        else {
            NSError *err = nil;
            NSLog(@"LICENSE DATA  = %@",licenseData);
            if(!licenseData){
                [self->_RCTvideo DispatchDownloadError];
            }else{
                
                NSData *persistentKey = [keyRequest persistableContentKeyFromKeyVendorResponse:licenseData options:nil error:&err];
                
                
                [self savePersistentContentKey:persistentKey forAsset:assetIDString error:&error];
                        
                AVContentKeyResponse *response = [AVContentKeyResponse contentKeyResponseWithFairPlayStreamingKeyResponseData:persistentKey];
            
                [keyRequest processContentKeyResponse:response];
           
                
                [self->_RCTvideo executemydownloadtask];
               
              
                
                
            }
        
            
        }
        
    }];
    }
}





-(BOOL)savePersistentContentKey:(NSData*)key forAsset:(NSString*)assetId error:(NSError**)error {
    NSURL* url = [self contentKeyLocationForAsset:assetId error:error];
    if (!url) {
        return NO;
    }
    
    NSLog(@"we are saving in %@",assetId);
    return [key writeToURL:url options:NSDataWritingAtomic error:error];
}

-(NSURL*)contentKeyLocationForAsset:(NSString*)assetId error:(NSError**)error {

    NSURL* libraryDir = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:error];
    
    if (!libraryDir) {
        return nil;
    }
    
    NSURL* keyStoreDir = [libraryDir URLByAppendingPathComponent:@"SwannKeyStore" isDirectory:YES];
    if (![[NSFileManager defaultManager] createDirectoryAtURL:keyStoreDir withIntermediateDirectories:YES attributes:nil error:error]) {
        return nil;
    }
    
    return [keyStoreDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.key", [self hexedMD5:assetId]]];
}

- (NSString *)hexedMD5: (NSString*)assetId {
    const char *cStr = assetId.UTF8String;
    unsigned char digest[16];
    CC_MD5( cStr, (int)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return  output;
}



-(NSData *)requestKeyFromServer:(NSData *)spcData forAssetId:(NSString *) assetId
{
    NSLog(@"requesting key from server");
    
    NSString *url = [_url stringByReplacingOccurrencesOfString:@"skd" withString:@"https"];
    
    
    NSCharacterSet *queryCharacter = [NSCharacterSet URLQueryAllowedCharacterSet];
    
    
    NSMutableCharacterSet *allowUrlCharacter = [NSMutableCharacterSet characterSetWithBitmapRepresentation:[queryCharacter bitmapRepresentation]];
    [allowUrlCharacter removeCharactersInString:@"+/=\\"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    
    [request setHTTPBody: spcData];
//                                    Create Request HTTP body:

    NSString *spcString = [spcData base64EncodedStringWithOptions:0];
    NSString *httpBodyString = [NSString stringWithFormat:@"spc=%@&assetId=%@",
                                [spcString stringByAddingPercentEncodingWithAllowedCharacters:
                                 [[NSCharacterSet characterSetWithCharactersInString:@"="] invertedSet]], assetId];
    [request setHTTPBody:[httpBodyString dataUsingEncoding:NSUTF8StringEncoding]];
    
    

    
    
    

  
    request.HTTPMethod = @"POST";
    
    
 
    
    
    NSLog(@"Header %@",_Header);
    if (_Header != nil) {
        for (NSString *key in _Header) {
            NSString *value = _Header[key];
            [request setValue:value forHTTPHeaderField:key];
        }
    }
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    //[request addValue:[self customData] forHTTPHeaderField:@"custom-data"];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *result = nil;
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        do {
            NSLog(@"LICENSE DATA RESONSE= %@",response);
            NSLog(@"LICENSE DATA data= %@",data);
            NSLog(@"LICENSE DATA ERROR= %@",error);
            if (error) break;
            if (!data) break;
          
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
 
            NSLog(@"NSData String: %@", dataString);
       //     if (!licenseObj) break;
         
            NSString *stringStrippedOfCkcTags = [[dataString stringByReplacingOccurrencesOfString:@"<ckc>"
                                                                                       withString:@""]
                                                 stringByReplacingOccurrencesOfString:@"</ckc>"
                                                 withString:@""];
            result = [[NSData alloc] initWithBase64EncodedString:stringStrippedOfCkcTags
                                                                        options:0];
            
            
//            result = [[NSData alloc] initWithBase64EncodedString:dataString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        }
        while (FALSE);
        dispatch_semaphore_signal(semaphore);
    }];
    [dataTask resume];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * 10E9));
    return result;
}
-(NSDictionary *)query: (NSString *)url
{
    NSMutableDictionary *queries = [[NSMutableDictionary alloc] init];
    NSURLComponents *urlComponent = [NSURLComponents componentsWithString:url];
    for (int idx = 0; idx < [urlComponent.queryItems count]; idx++){
        NSURLQueryItem *item = [urlComponent.queryItems objectAtIndex:idx];
        [queries setObject:item.value forKey:item.name];
    }
    return queries;
}







@end
