//
//  LTRequest.h
//
//  Created by thanhhaitran on 3/3/15.
//  Copyright (c) 2015 libreteam. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, CamPermisionType) {
    authorized = 0,
    denied,
    restricted,
    per_granted,
    per_denied
};

typedef NS_ENUM(NSInteger, MicPermisionType) {
    mGranted = 0,
    mDined,
    mPer_granted,
    mPer_denied
};

typedef NS_ENUM(NSInteger, LocationPermisionType) {
    lAlways = 0,
    lDenied,
    lRestricted,
    lWhenUse,
    lNotSure
};

typedef void (^Camera)(CamPermisionType type);

typedef void (^Micro)(MicPermisionType type);

typedef void (^Location)(LocationPermisionType type);


typedef void (^RequestCompletion)(NSString * responseString, NSString * errorCode, NSError * error, BOOL isValidated);

typedef void (^RequestCache)(NSString * cacheString);

@interface LTRequest : NSObject <CLLocationManagerDelegate>
{
    CamPermisionType camType;
    
    MicPermisionType micType;
    
    LocationPermisionType locationType;
}

@property(nonatomic,copy) Camera CameraCompletion;

@property(nonatomic,copy) Micro MicroCompletion;

@property(nonatomic,copy) Location LocationCompletion;

@property(nonatomic,copy) RequestCompletion completion;

@property(nonatomic,copy) RequestCache cache;

@property (nonatomic, retain) NSString * deviceToken;

@property (nonatomic, retain) NSString * address;

@property (nonatomic, readwrite) BOOL lang;

@property (nonatomic, retain) CLLocationManager * locationManager;

+ (LTRequest*)sharedInstance;

- (void)initRequest;

- (void)didRequestInfo:(NSDictionary*)dict withCache:(RequestCache)cache andCompletion:(RequestCompletion)completion;

- (void)didInitWithUrl:(NSDictionary*)dict withCache:(RequestCache)cache andCompletion:(RequestCompletion)completion;

- (void)registerPush;

- (void)didReceiveToken:(NSData *)deviceToken;

- (void)didFailToRegisterForRemoteNotification:(NSError *)error;

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

- (void)didClearBadge;

- (BOOL)isConnectionAvailable;

- (void)askCamera:(Camera)cameraPermission;

- (void)askMicrophone:(Micro)microPermission;

- (void)askGallery:(Camera)cameraPermission;

- (void)initLocation:(BOOL)isAlways andCompletion:(Location)locationCompletion;

@end
