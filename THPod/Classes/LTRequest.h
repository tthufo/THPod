//
//  LTRequest.h
//
//  Created by thanhhaitran on 3/3/15.
//  Copyright (c) 2015 libreteam. All rights reserved.
//

#import <Foundation/Foundation.h>

//#import "ASIFormDataRequest.h"

typedef NS_ENUM(NSInteger, PermisionType) {
    authorized = 0,
    denied,
    restricted,
    per_granted,
    per_denied
};

typedef void (^Camera)(PermisionType type);

typedef void (^RequestCompletion)(NSString * responseString, NSString * errorCode, NSError * error, BOOL isValidated);

typedef void (^RequestCache)(NSString * cacheString);

@interface LTRequest : NSObject
{
    PermisionType camType;
}

@property(nonatomic,copy) Camera CameraCompletion;

@property(nonatomic,copy) RequestCompletion completion;

@property(nonatomic,copy) RequestCache cache;

@property (nonatomic, retain) NSString * deviceToken;

@property (nonatomic, retain) NSString * address;

@property (nonatomic, readwrite) BOOL lang;

+ (LTRequest*)sharedInstance;

- (void)initRequest;

//- (ASIFormDataRequest*)didRequestInfo:(NSDictionary*)dict withCache:(RequestCache)cache andCompletion:(RequestCompletion)completion;

- (void)didRequestInfo:(NSDictionary*)dict withCache:(RequestCache)cache andCompletion:(RequestCompletion)completion;

- (void)didInitWithUrl:(NSDictionary*)dict withCache:(RequestCache)cache andCompletion:(RequestCompletion)completion;

- (void)registerPush;

- (void)didReceiveToken:(NSData *)deviceToken;

- (void)didFailToRegisterForRemoteNotification:(NSError *)error;

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

- (void)didClearBadge;

- (BOOL)isConnectionAvailable;

- (void)askCamera:(Camera)cameraPermission;

@end
