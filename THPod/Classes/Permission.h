//
//  Permission.h
//  Pods
//
//  Created by thanhhaitran on 9/21/16.
//
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

#import <AssetsLibrary/AssetsLibrary.h>

#import <AVFoundation/AVFoundation.h>

#import <MediaPlayer/MediaPlayer.h>

#import "NSObject+Category.h"

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
    lNotSure,
    lDisabled
};

//typedef NS_ENUM(NSInteger, MusicPermisionType) {
//    mAllow = 0,
//    mDenied,
//    mRestricted,
//    mNotSure
//};

typedef void (^Camera)(CamPermisionType type);

typedef void (^Micro)(MicPermisionType type);

typedef void (^Location)(LocationPermisionType type);

typedef void (^Heading)(float magneticHeading, float trueHeading);

//typedef void (^Music)(MusicPermisionType type);


@interface Permission : NSObject <CLLocationManagerDelegate>
{
    CamPermisionType camType;
    
    MicPermisionType micType;
    
    LocationPermisionType locationType;
    
    //    MusicPermisionType musicType;
}

@property(nonatomic,copy) Camera CameraCompletion;

@property(nonatomic,copy) Micro MicroCompletion;

@property(nonatomic,copy) Location LocationCompletion;

@property(nonatomic,copy) Heading HeadingCompletion;

//@property(nonatomic,copy) Music MusicCompletion;

@property (nonatomic, retain) CLLocationManager * locationManager;


+ (Permission*)shareInstance;

//- (void)askMusic:(Music)musicPermission;

- (void)askCamera:(Camera)cameraPermission;

- (void)askMicrophone:(Micro)microPermission;

- (void)askGallery:(Camera)cameraPermission;

- (void)initLocation:(BOOL)isAlways andCompletion:(Location)locationCompletion;

- (void)didReturnHeading:(Heading)heading;

- (BOOL)isLocationEnable;

@end

