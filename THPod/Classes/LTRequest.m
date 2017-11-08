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

#import "AFNetworking.h"

static LTRequest *__sharedLTRequest = nil;

@implementation LTRequest

@synthesize deviceToken, address;

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
//#if TARGET_IPHONE_SIMULATOR
        
        deviceToken = [self getValue:@"fakeUUID"];
        
//#endif
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

- (NSString*)requestURL:(NSMutableDictionary*)dict
{
    NSDictionary * info = [self dictWithPlist:@"Info"];
    
    if([dict responseForKey:@"method"])
    {
        return [dict responseForKey:@"absoluteLink"] ? dict[@"absoluteLink"] : [NSString stringWithFormat:@"%@/%@%@%@", self.address, dict[[info responseForKey:@"cCode"] ? info[@"cCode"] : @"CMD_CODE"], [dict responseForKey:@"overrideOrder"] ? @"/" : @"?" ,[self returnGetUrl:dict]];
    }
    else
    {
        return [dict responseForKey:@"absoluteLink"] ? dict[@"absoluteLink"] : [dict responseForKey:@"postFix"] ? [NSString stringWithFormat:@"%@/%@",self.address,dict[@"postFix"]] : self.address;
    }
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
//    NSLog(@"+___+%@",dict);
    
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
    
    if([dict responseForKey:@"header"])
    {
        for(NSString * key in dict[@"header"])
        {
            [manager.requestSerializer setValue:dict[@"header"][key] forHTTPHeaderField:key];
        }
    }
    
    NSString * url;
    
    if([dict responseForKey:@"method"])
    {
        url = [dict responseForKey:@"absoluteLink"] ? dict[@"absoluteLink"] : [NSString stringWithFormat:@"%@/%@%@%@", self.address, dict[[info responseForKey:@"cCode"] ? info[@"cCode"] : @"CMD_CODE"], [dict responseForKey:@"overrideOrder"] ? @"/" : @"?" ,[self returnGetUrl:dict]];
        
        NSLog(@"%@",url);
        
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
        url = [dict responseForKey:@"absoluteLink"] ? dict[@"absoluteLink"] : [dict responseForKey:@"postFix"] ? [NSString stringWithFormat:@"%@/%@",self.address,dict[@"postFix"]] : self.address;
        
        post = [[NSMutableDictionary alloc] initWithDictionary:dict];
        
        for(NSString * key in post.allKeys)
        {
            if([key isEqualToString:@"host"] || [key isEqualToString:@"completion"] || [key isEqualToString:@"method"] || [key isEqualToString:@"checkmark"] || [key isEqualToString:@"cache"] || [key isEqualToString:@"absoluteLink"] || [key isEqualToString:@"overrideLoading"] || [key isEqualToString:@"overrideAlert"] || [key isEqualToString:@"overrideOrder"])
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
            
            NSLog(@"%@", [error description]);
        }];
    }
}

- (void)didFailedResult:(NSDictionary*)dict andError:(NSError*)error
{
    if(![self isConnectionAvailable])
    {
        [self showToast:self.lang ? @"Please check your Internet connection" : @"Vui lòng kiểm tra lại kết nối Internet" andPos:0];
        
        if([dict responseForKey:@"host"])
        {
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
    
    NSMutableDictionary * result = [response isKindOfClass:[NSDictionary class]] ? [NSMutableDictionary dictionaryWithDictionary:response] : [response isKindOfClass:[NSArray class]] ? [NSMutableDictionary dictionaryWithDictionary:@{@"array":response}] : [NSMutableDictionary new];
    
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
    
    NSMutableString * getUrl = [NSMutableString new];
    
    NSMutableArray *sortedArray = [NSMutableArray arrayWithArray:[dict allKeys]];
    
    [sortedArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for(NSString * key in sortedArray)
    {
        if([key isEqualToString:@"host"] || [key isEqualToString:[info responseForKey:@"cCode"] ? info[@"cCode"] : @"CMD_CODE"] || [key isEqualToString:@"completion"] || [key isEqualToString:@"method"] || [key isEqualToString:@"overrideLoading"] || [key isEqualToString:@"overrideAlert"] || [key isEqualToString:@"overrideError"] || [key isEqualToString:@"checkMark"] || [key isEqualToString:@"cache"] || [key isEqualToString:@"host"] || [key isEqualToString:@"overrideOrder"])
        {
            continue;
        }
        
        
        if([dict responseForKey:@"overrideOrder"])
        {
            [getUrl appendString:[NSString stringWithFormat:@"%@/",dict[key]]];
        }
        else
        {
            [getUrl appendString:[NSString stringWithFormat:@"%@=%@&",key,dict[key]]];
        }
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

@end
