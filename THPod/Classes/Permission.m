//
//  Permission.m
//  Pods
//
//  Created by thanhhaitran on 9/21/16.
//
//

#import "Permission.h"

static Permission * shareInstan = nil;

@implementation Permission

@synthesize locationManager;

+ (Permission*)shareInstance
{
    if(!shareInstan)
    {
        shareInstan = [Permission new];
    }
    
    return shareInstan;
}

//- (void)askMusic:(Music)musicPermission
//{
//    self.MusicCompletion = musicPermission;
//    
//    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
//        switch (status) {
//            case MPMediaLibraryAuthorizationStatusNotDetermined:
//                self.MusicCompletion(3);
//                break;
//            case MPMediaLibraryAuthorizationStatusAuthorized:
//                self.MusicCompletion(0);
//                break;
//            case MPMediaLibraryAuthorizationStatusDenied:
//                self.MusicCompletion(1);
//                break;
//            case MPMediaLibraryAuthorizationStatusRestricted:
//                self.MusicCompletion(2);
//                break;
//            default:
//                break;
//        }
//    }];
//}

- (void)askCamera:(Camera)cameraPermission
{
    self.CameraCompletion = cameraPermission;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        self.CameraCompletion(0);
    } else if(authStatus == AVAuthorizationStatusDenied) {
        self.CameraCompletion(1);
    } else if(authStatus == AVAuthorizationStatusRestricted) {
        self.CameraCompletion(2);
    } else if(authStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if(granted){
                self.CameraCompletion(3);
            } else {
                self.CameraCompletion(4);
            }
        }];
    } else {
        
    }
}

- (void)askMicrophone:(Micro)microPermission
{
    self.MicroCompletion = microPermission;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    AVAudioSessionRecordPermission sessionRecordPermission = [session recordPermission];
    switch (sessionRecordPermission) {
        case AVAudioSessionRecordPermissionUndetermined:
        {
            [session requestRecordPermission:^(BOOL granted) {
                if (granted) {
                    self.MicroCompletion(2);
                }
                else {
                    self.MicroCompletion(3);
                }
            }];
        }
            break;
        case AVAudioSessionRecordPermissionDenied:
        {
            self.MicroCompletion(1);
        }
            break;
        case AVAudioSessionRecordPermissionGranted:
        {
            self.MicroCompletion(0);
        }
            break;
        default:
            break;
    }
}

- (void)askGallery:(Camera)cameraPermission
{
    self.CameraCompletion = cameraPermission;
    
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    
    switch (status) {
        case ALAuthorizationStatusNotDetermined:
        {
            ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
            [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                if (*stop) {
                    self.CameraCompletion(3);
                    return;
                }
                *stop = TRUE;
            } failureBlock:^(NSError *error) {
                self.CameraCompletion(4);
            }];
        }
            break;
        case ALAuthorizationStatusRestricted:
            self.CameraCompletion(2);
            break;
        case ALAuthorizationStatusDenied:
            self.CameraCompletion(1);
            break;
        case ALAuthorizationStatusAuthorized:
            self.CameraCompletion(0);
            break;
        default:
            break;
    }
}

- (void)initLocation:(BOOL)isAlways andCompletion:(Location)locationCompletion
{
    if(![CLLocationManager locationServicesEnabled])
    {
        [self alert:@"Location Services Required" message:@"Location services is disabled. Please go to Settings to check your Location Services"];
        
        return;
    }
    
    self.LocationCompletion = locationCompletion;
    
    if(!locationManager)
    {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        
        if(isAlways)
        {
            if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
            {
                [locationManager requestAlwaysAuthorization];
            }
        }
        else
        {
            if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
            {
                [locationManager requestWhenInUseAuthorization];
            }
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        
        [locationManager startUpdatingLocation];
        [locationManager stopUpdatingLocation];
    }
}

- (NSDictionary *)currentLocation
{
    if(!locationManager) return nil;
    
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
    {
        return nil;
    }
    
    NSLog(@"_%@",@{@"lat":@(locationManager.location.coordinate.longitude),@"lng":@(locationManager.location.coordinate.latitude)});
    
    return @{@"lat":@(locationManager.location.coordinate.longitude),@"lng":@(locationManager.location.coordinate.latitude)};
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"Moved to location : %@",[newLocation description]);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
            self.LocationCompletion(0);
            break;
        case kCLAuthorizationStatusDenied:
            self.LocationCompletion(1);
            break;
        case kCLAuthorizationStatusRestricted:
            self.LocationCompletion(2);
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            self.LocationCompletion(3);
            break;
        case kCLAuthorizationStatusNotDetermined:
            self.LocationCompletion(4);
            break;
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self alert:@"Alert" message:@"Failed to get your location, please go to Settings to check your Location Services"];
}



@end
