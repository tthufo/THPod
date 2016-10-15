//
//  DropAlert.h
//  Pods
//
//  Created by thanhhaitran on 2/27/16.
//
//

#import <Foundation/Foundation.h>

#import <StoreKit/StoreKit.h>

typedef void (^DropAlertCompletion)(int indexButton, id object);

@interface DropAlert : NSObject <SKStoreProductViewControllerDelegate>

+ (DropAlert*)shareInstance;

- (void)alertWithInfor:(NSDictionary*)dict andCompletion:(DropAlertCompletion)completion;

- (void)actionSheetWithInfo:(NSDictionary*)dict andCompletion:(DropAlertCompletion)completion;

- (void)didOpenLink:(NSDictionary*)dict;

- (void)didShowStoreWithInfo:(NSDictionary*)dict andCompletion:(DropAlertCompletion)completion;

@end
