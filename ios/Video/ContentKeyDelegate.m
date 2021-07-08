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

    NSLog(@"Key asset ID : @%",_url);

    do {
        if (![self contentKeyLocationForAsset:_url error:nil]) {
            NSLog(@"doesn't exist");
            break;
           
        }
        
        NSData* data = [self loadPersistentContentKeyForAsset:_url error:nil];
        
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
  
    [self processOnlineKey:session request:keyRequest assetIDString:_url];
    

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


- (NSData *)getContentKeyAndLeaseExpiryfromKeyServerModuleWithRequest:(NSData *)requestBytes skdURL:(NSURL *)skdURL leaseExpiryDuration:(NSTimeInterval *)expiryDuration error:(NSError **)errorOut
{
    NSString *requestLength = [NSString stringWithFormat:@"%lu", (unsigned long)[requestBytes length]];
    
    // Convert scheme from skd to https
    NSURLComponents *components = [NSURLComponents componentsWithURL:skdURL resolvingAgainstBaseURL:false];
    [components setScheme:@"https"];
    NSURL *keyURL = [components URL];
    
    //format post body to be {"spc":<your base64 encoded spc>}
    NSString *spc = [NSString stringWithFormat:@"{\"spc\":\"%@\"}", [requestBytes base64EncodedStringWithOptions:0]];
    NSLog(@"\n\n*** CONSTRUCTED SPC***\n>>> %@ <<<\n\n", spc);
    
    NSLog(@"\n\n*** Retrieving key from ***\n>>> %@ <<<\n\n", keyURL);
    NSMutableURLRequest *keyRequest = [NSMutableURLRequest requestWithURL:keyURL];
    [keyRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    //[keyRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [keyRequest setValue:requestLength forHTTPHeaderField:@"Content-Length"];
    [keyRequest setHTTPMethod:@"POST"];
    [keyRequest setHTTPBody:[spc dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"Header %@",_Header);
    if (_Header != nil) {
        for (NSString *key in _Header) {
            NSString *value = _Header[key];
            [keyRequest setValue:value forHTTPHeaderField:key];
        }
    }
    NSURLResponse *response;
    NSError *errOut;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:keyRequest returningResponse:&response error:&errOut];
    
    return responseData;

    NSData *decodedData = nil;
    
    *errorOut = [NSError errorWithDomain:NSPOSIXErrorDomain code:1 userInfo:nil];
    return decodedData;
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
       
        
        NSData *responseData = nil;
          NSTimeInterval expiryDuration = 0.0;
        NSLog(@"_url : %@",_url);
          // Send the SPC message to the Key Server.
          responseData = [self getContentKeyAndLeaseExpiryfromKeyServerModuleWithRequest:contentKeyRequestData
                                                                                  skdURL: [NSURL URLWithString:_url]
                                                                     leaseExpiryDuration:&expiryDuration
                                                                                   error:&error];
          
          // The Key Server returns the CK inside an encrypted Content Key Context (CKC) message in response to
          // the app’s SPC message.  This CKC message, containing the CK, was constructed from the SPC by a
          // Key Security Module in the Key Server’s software.
          if (responseData != nil) {
              
              // upLynk is sending back a JSON payload with a 'ckc' member that's base64 encoded. So we need to grab
              // that and b64-decode it before passing it further in...
              NSError *jsonParseError;
              NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData
                                                                       options:NSJSONReadingMutableContainers
                                                                         error:&jsonParseError];
              NSLog(@"ckc response dic === %@",responseData);
          }
        
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

    NSURL* libraryDir = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:error];
    
    if (!libraryDir) {
        return nil;
    }
    
    NSString* HexedAssetId = [self hexedMD5:assetId];
    HexedAssetId = [HexedAssetId stringByAppendingString:@"-"];
    assetId = [HexedAssetId stringByAppendingString:_accountID];
    
    NSURL* keyStoreDir = [libraryDir URLByAppendingPathComponent:@"SwannKeyStore" isDirectory:YES];
   // NSURL*keyStoreDir = [libraryDir URLByAppendingPathComponent:assetId isDirectory:YES];
    
    if (![[NSFileManager defaultManager] createDirectoryAtURL:keyStoreDir withIntermediateDirectories:YES attributes:nil error:error]) {
        return nil;
    }

    
   
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    [self addToStorage];
    return [keyStoreDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.key", assetId]];
}

-(void)addToStorage{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *arr1  = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"Downloaders"]];
    if (![arr1 containsObject:_accountID]){
        [arr1 addObject:_accountID];
          [defaults setObject:arr1 forKey:@"Downloaders"];
          [defaults synchronize];
    }
   
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
