//
//  LTRequest.m
//
//  Created by thanhhaitran on 3/3/15.
//  Copyright (c) 2015 libreteam. All rights reserved.
//

#import "LTRequest.h"

#import "Reachability.h"

#import "JSONKit.h"

#import "NSObject+Category.h"

#import "AVHexColor.h"

#import <AVFoundation/AVFoundation.h>

#import <AssetsLibrary/AssetsLibrary.h>

#import "AFNetworking.h"

static LTRequest *__sharedLTRequest = nil;

@implementation LTRequest

@synthesize deviceToken, address, locationManager;

+ (LTRequest *)sharedInstance
{
    if (!__sharedLTRequest)
    {
        __sharedLTRequest = [[LTRequest alloc] init];
    }
    return __sharedLTRequest;
}

- (void)registerPush
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
    }
    
    [self didRegisterApp];
}

- (void)didRegisterApp
{
    if(![self getValue:@"fakeUUID"])
    {
        NSString * fakeUUID = [[[self deviceUUID] stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
        
        [self addValue:fakeUUID andKey:@"fakeUUID"];
        
        deviceToken = fakeUUID;
    }
    else
    {
        if(![self checkForNotification])
        {
            deviceToken = [self getValue:@"fakeUUID"];
        }
#if TARGET_IPHONE_SIMULATOR
        
        deviceToken = [self getValue:@"fakeUUID"];
        
#endif
    }
}

- (void)didReceiveToken:(NSData *)_deviceToken
{
    deviceToken = [[[[_deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: @""] stringByReplacingOccurrencesOfString: @">" withString: @""] stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    NSLog(@"TokenPushInfor----->%@", deviceToken);
}

- (void)didFailToRegisterForRemoteNotification:(NSError *)error
{
    [self alert:self.lang ? @"Attention" : @"Thông báo" message:[error localizedDescription]];
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"UserPushInfor----->%@", userInfo);
}

- (void)initRequest
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if(!dictionary)
    {
        NSLog(@"Check your Info.plist is not right path or name");
    }
    
    if (!dictionary[@"host"])
    {
        NSLog(@"Please setup request url in Plist");
    }
    else
    {
        self.address = dictionary[@"host"];
    }
    self.lang = [dictionary responseForKey:@"lang"];
}

- (void)didInitWithUrl:(NSDictionary*)dict withCache:(RequestCache)cache andCompletion:(RequestCompletion)completion
{
    if([self getValue:dict[@"absoluteLink"]])
    {
        cache([self getValue:dict[@"absoluteLink"]]);
    }
    else
    {
        if([dict responseForKey:@"host"])
        {
            [(UIViewController*)dict[@"host"] showSVHUD: self.lang ? @"Loading" : @"Đang tải" andOption:0];
        }
    }
    if([dict responseForKey:@"overrideLoading"])
    {
        if([dict responseForKey:@"host"])
        {
            [(UIViewController*)dict[@"host"] showSVHUD: self.lang ? @"Loading" : @"Đang tải" andOption:0];
        }
    }
    
    NSURL * requestUrl = [NSURL URLWithString:dict[@"absoluteLink"]];
    
    NSError* error = nil;
    
    NSData* htmlData = [NSData dataWithContentsOfURL:requestUrl options:NSDataReadingUncached error:&error];
    
    if(error)
    {
        completion(nil, @"1", error, NO);
    }
    else
    {
        completion([NSString stringWithUTF8String:[htmlData bytes]], @"0", nil, YES);
        
        [self addValue:[NSString stringWithUTF8String:[htmlData bytes]] andKey:dict[@"absoluteLink"]];
    }
    
    if([dict responseForKey:@"host"])
    {
        [self hideSVHUD];
    }
}

- (void)didRequestInfo:(NSDictionary*)dict withCache:(RequestCache)cacheData andCompletion:(RequestCompletion)completion
{
    if(!self.address)
    {
        NSLog(@"Please setup request url in Plist");
        
        return ;
    }
    NSMutableDictionary * data = [dict mutableCopy];
    
    data[@"completion"] = completion;
    
    data[@"cache"] = cacheData;
    
    [self didInitRequest:data];
}

- (BOOL)didRespond:(NSMutableDictionary*)dict andHost:(UIViewController*)host
{
    NSLog(@"+___+%@",dict);
    
    NSDictionary * info = [self dictWithPlist:@"Info"];
    
    if(host)
    {
        [host hideSVHUD];
    }
    
    if(!dict)
    {
        [self showToast:self.lang ? @"Server error" :  @"Hệ thống đang bận" andPos:0];
        
        return NO;
    }
    
    if([info responseForKey:@"eCode"] && !dict[info[@"eCode"]])
    {
        [self showToast:@"Check for Plist/eCode" andPos:0];
        
        return NO;
    }
    
    if([dict responseForKindOfClass:[info responseForKey:@"eCode"] ? info[@"eCode"] : @"ERR_CODE" andTarget:[info responseForKey:@"sCode"] ? info[@"sCode"] : @"0"])
    {
        if([dict responseForKey:@"checkmark"] && host)
        {
            dict[@"status"] = @(1);
            
            [self didAddCheckMark:dict andHost:host];
        }
        else
        {
            if(![dict responseForKey:@"overrideAlert"])
            {
                [self showToast:[dict responseForKey: [info responseForKey:@"eCode"] ? info[@"eCode"] : @"ERR_CODE"] ? dict[[info responseForKey:@"eMessage"] ? info[@"eMessage"] : @"ERR_MSG"] ? dict[[info responseForKey:@"eMessage"] ? info[@"eMessage"] : @"ERR_MSG"] : @"Check for Plist/eMessage" : self.lang ? @"Server error, please try again" : @"Lỗi hệ thống xảy ra, xin hãy thử lại" andPos:0];
            }
        }
        return YES;
    }
    
    if([dict responseForKey:@"checkmark"] && host)
    {
        dict[@"status"] = @(0);
        
        [self didAddCheckMark:dict andHost:host];
    }
    else
    {
        if(![dict responseForKey:@"overrideAlert"])
        {
            [self showToast:[dict responseForKey: [info responseForKey:@"eCode"] ? info[@"eCode"] : @"ERR_CODE"] ? dict[[info responseForKey:@"eMessage"] ? info[@"eMessage"] : @"ERR_MSG"] ? dict[[info responseForKey:@"eMessage"] ? info[@"eMessage"] : @"ERR_MSG"] : @"Check for Plist/eMessage" : self.lang ? @"Server error, please try again" : @"Lỗi hệ thống xảy ra, xin hãy thử lại" andPos:0];
        }
    }
    
    return NO;
}

- (void)didInitRequest:(NSMutableDictionary*)dict
{
    NSDictionary * info = [self dictWithPlist:@"Info"];
    
    NSMutableDictionary * post = nil;
    
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSString * url;
    
    if([dict responseForKey:@"method"])
    {
        url = [dict responseForKey:@"absoluteLink"] ? dict[@"absoluteLink"] : [NSString stringWithFormat:@"%@/%@?%@", self.address, dict[[info responseForKey:@"cCode"] ? info[@"cCode"] : @"CMD_CODE"], [self returnGetUrl:dict]];
        
        if([self getValue: url])
        {
            ((RequestCache)dict[@"cache"])([self getValue: url]);
        }
        else
        {
            if([dict responseForKey:@"host"])
            {
                [(UIViewController*)dict[@"host"] showSVHUD: self.lang ? @"Loading" : @"Đang tải" andOption:0];
            }
        }
        if([dict responseForKey:@"overrideLoading"])
        {
            if([dict responseForKey:@"host"])
            {
                [(UIViewController*)dict[@"host"] showSVHUD: self.lang ? @"Loading" : @"Đang tải" andOption:0];
            }
        }
        
        [manager GET:url parameters:nil success:^(NSURLSessionTask *task, id responseObject) {
            
            [self didSuccessResult:dict andResult:[responseObject objectFromJSONData] ? [responseObject objectFromJSONData] : [NSString stringWithUTF8String:[responseObject bytes]] andUrl:url andPostData:post];
            
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            
            [self didFailedResult:dict andError:error];
            
        }];
    }
    else
    {
        url = [dict responseForKey:@"absoluteLink"] ? dict[@"absoluteLink"] : self.address;
        
        post = [[NSMutableDictionary alloc] initWithDictionary:dict];
        
        for(NSString * key in post.allKeys)
        {
            if([key isEqualToString:@"host"] || [key isEqualToString:@"completion"] || [key isEqualToString:@"method"] || [key isEqualToString:@"checkmark"] || [key isEqualToString:@"cache"] || [key isEqualToString:@"absoluteLink"] || [key isEqualToString:@"overrideLoading"] || [key isEqualToString:@"overrideAlert"])
            {
                [post removeObjectForKey:key];
            }
        }
        
        if([self getValue: [dict responseForKey:@"absoluteLink"] ? dict[@"absoluteLink"] : [post bv_jsonStringWithPrettyPrint:NO]])
        {
            ((RequestCache)dict[@"cache"])([self getValue:[dict responseForKey:@"absoluteLink"] ? dict[@"absoluteLink"] : [post bv_jsonStringWithPrettyPrint:NO]]);
        }
        else
        {
            if([dict responseForKey:@"host"])
            {
                [dict[@"host"] showSVHUD: self.lang ? @"Loading" : @"Đang tải" andOption:0];
            }
        }
        if([dict responseForKey:@"overrideLoading"])
        {
            if([dict responseForKey:@"host"])
            {
                [dict[@"host"] showSVHUD: self.lang ? @"Loading" : @"Đang tải" andOption:0];
            }
        }
        
        [manager POST:url parameters:post success:^(NSURLSessionTask *task, id responseObject) {
            
            [self didSuccessResult:dict andResult:[responseObject objectFromJSONData] ? [responseObject objectFromJSONData] : [NSString stringWithUTF8String:[responseObject bytes]] andUrl:url andPostData:post];
            
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            
            [self didFailedResult:dict andError:error];
            
        }];
    }
}

- (void)didFailedResult:(NSDictionary*)dict andError:(NSError*)error
{
    if(![self isConnectionAvailable])
    {
        if([dict responseForKey:@"host"])
        {
            [self showToast:self.lang ? @"Please check your Internet connection" : @"Vui lòng kiểm tra lại kết nối Internet" andPos:0];
            
            [dict[@"host"] hideSVHUD];
        }
        
        ((RequestCompletion)dict[@"completion"])(nil, @"404", error, NO);
    }
    else
    {
        NSMutableDictionary * result = [NSMutableDictionary new];
        
        if([dict responseForKey:@"overrideAlert"])
        {
            [result addEntriesFromDictionary:@{@"overrideAlert":dict[@"overrideAlert"]}];
        }
        
        if([dict responseForKey:@"checkmark"])
        {
            [result addEntriesFromDictionary:@{@"checkmark":dict[@"checkmark"]}];
        }
        
        ((RequestCompletion)dict[@"completion"])(nil, @"503", error, [self didRespond:result andHost:dict[@"host"]]);
    }
}

- (void)didSuccessResult:(NSDictionary*)dict andResult:(id)response andUrl:(NSString*)url andPostData:(NSDictionary*)post
{
    NSDictionary * info = [self dictWithPlist:@"Info"];
    
    NSMutableDictionary * result = [NSMutableDictionary new];//[NSMutableDictionary dictionaryWithDictionary:response];
    
    if([dict responseForKey:@"method"])
    {
        if(response)
        {            
            [self addValue:[response isKindOfClass:[NSDictionary class]] ? [response bv_jsonStringWithPrettyPrint:NO] : [response isKindOfClass:[NSArray class]] ? [@{@"array":response} bv_jsonStringWithPrettyPrint:NO] : response andKey:[dict responseForKey:@"absoluteLink"] ? dict[@"absoluteLink"] : url];
        }
    }
    else
    {
        if(response)
        {
            [self addValue:[response isKindOfClass:[NSDictionary class]] ? [response bv_jsonStringWithPrettyPrint:NO] : [response isKindOfClass:[NSArray class]] ? [@{@"array":response} bv_jsonStringWithPrettyPrint:NO] : response andKey:[dict responseForKey:@"absoluteLink"] ? dict[@"absoluteLink"] : [post bv_jsonStringWithPrettyPrint:NO]];
        }
    }
    
    if([dict responseForKey:@"overrideAlert"])
    {
        [result addEntriesFromDictionary:@{@"overrideAlert":dict[@"overrideAlert"]}];
    }
    
    if([dict responseForKey:@"checkmark"])
    {
        [result addEntriesFromDictionary:@{@"checkmark":dict[@"checkmark"]}];
    }
    
    if([dict responseForKey:@"overrideError"] && dict[@"host"])
    {
        [self hideSVHUD];
    }
    
    if([info responseForKey:@"eCode"] && !response[info[@"eCode"]])
    {
        [self showToast:@"Check for Plist/eCode" andPos:0];
    }
    
    ((RequestCompletion)dict[@"completion"])([response isKindOfClass:[NSDictionary class]] ? [response bv_jsonStringWithPrettyPrint:NO] : [response isKindOfClass:[NSArray class]] ? [@{@"array":response} bv_jsonStringWithPrettyPrint:NO] : response, [result responseForKey:[info responseForKey:@"eCode"] ? info[@"eCode"] : @"ERR_CODE"] ? [result getValueFromKey:[info responseForKey:@"eCode"] ? info[@"eCode"] : @"ERR_CODE"] : @"500", nil,[dict responseForKey:@"overrideError"] ? YES : [self didRespond:result andHost:dict[@"host"]]);
}

- (NSString*)returnGetUrl:(NSDictionary*)dict
{
    NSDictionary * info = [self dictWithPlist:@"Info"][@"eCode"];
    
    NSString * getUrl = @"";
    
    for(NSString * key in dict.allKeys)
    {
        if([key isEqualToString:@"host"] || [key isEqualToString:[info responseForKey:@"cCode"] ? info[@"cCode"] : @"CMD_CODE"] || [key isEqualToString:@"completion"] || [key isEqualToString:@"method"] || [key isEqualToString:@"overrideLoading"] || [key isEqualToString:@"overrideAlert"] || [key isEqualToString:@"overrideError"])
        {
            continue;
        }
        getUrl = [NSString stringWithFormat:@"%@%@=%@&",getUrl,key,dict[key]];
    }
    
    return [getUrl substringToIndex:getUrl.length-(getUrl.length>0)];
}

- (void)didClearBadge
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
}

- (void)didAddCheckMark:(NSDictionary*)dict andHost:(UIViewController*)host
{
    [host showSVHUD:[dict[@"status"] boolValue] ? self.lang ? @"Success" :  @"Thành công" : self.lang ? @"Error" : @"Xảy ra lỗi" andOption:[dict[@"status"] boolValue] ? 1 : 2];
}

- (BOOL)isConnectionAvailable
{
    SCNetworkReachabilityFlags flags;
    SCNetworkReachabilityRef add;
    add = SCNetworkReachabilityCreateWithName(NULL, "www.apple.com" );
    Boolean success = SCNetworkReachabilityGetFlags(add, &flags);
    CFRelease(add);
    
    bool canReach = success
    && !(flags & kSCNetworkReachabilityFlagsConnectionRequired)
    && (flags & kSCNetworkReachabilityFlagsReachable);
    
    return canReach;
}

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
    
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied | kCLAuthorizationStatusRestricted)
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
