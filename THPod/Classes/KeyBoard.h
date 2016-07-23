//
//  KeyboardViewController.h
//  Pods
//
//  Created by thanhhaitran on 6/29/16.
//
//

#import <UIKit/UIKit.h>

typedef void (^KeyBoardEvents)(CGFloat kbHeight, BOOL isOn);

@interface KeyBoard : NSObject

+ (KeyBoard*)shareInstance;

- (KeyBoard*)keyboardOn:(KeyBoardEvents)kbEvent;

- (KeyBoard*)keyboardOn:(NSDictionary*)dict andCompletion:(KeyBoardEvents)kbEvent;

- (void)keyboardOff;

@property(nonatomic,copy) KeyBoardEvents event;

@end
