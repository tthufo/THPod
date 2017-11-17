//
//  DropButton.m
//  Pods
//
//  Created by thanhhaitran on 1/13/16.
//
//

#import "DropButton.h"

#import "NSObject+Category.h"

#import "UIImageView+WebCache.h"

#import "AVHexColor.h"

#define screenHeight [UIScreen mainScreen].bounds.size.height

#define screenWidth [UIScreen mainScreen].bounds.size.width

static DropButton * shareButton = nil;

@interface DropButton () <NIDropDownDelegate>
{    
    DropButtonCompletion completionBlock;
    
    DropButtonUpCompletion completionUpBlock;

    NSDictionary * template;
}

@end

@implementation DropButton

@synthesize pList, dropDown, yPos;

+ (DropButton*)shareInstance
{
    if(!shareButton)
    {
        shareButton = [DropButton new];
    }
    
    return shareButton;
}

- (void)didDropDownWithView:(NSDictionary*)dict andCompletion:(DropButtonCompletion)completion
{
    completionBlock = completion;
    
    if(dropDown == nil)
    {
        CGFloat f = [dict[@"height"] floatValue];
        
        CGFloat startRect = [dict[@"X"] floatValue];//[self convertRect:self.bounds toView:nil].origin.x;
        
        CGFloat start =  startRect;//(startRect + [dict[@"width"] floatValue]) > screenWidth ? self.bounds.origin.x - ([dict[@"width"] floatValue] - (self.bounds.origin.x + self.bounds.size.width) - ([dict responseForKey:@"offSetX"] ? [dict[@"offSetX"] floatValue] : 0)) : self.bounds.origin.x;
        
        CGRect windowRect = [self convertRect:/*[dict responseForKey:@"width"] ?*/ CGRectMake(start, self.bounds.origin.y  + [dict[@"offSetY"] floatValue], [dict[@"width"] floatValue], self.bounds.size.height) /*: self.bounds*/ toView:nil];
        
        CGRect final = CGRectMake(startRect, windowRect.origin.y, [dict[@"width"] floatValue], self.bounds.size.height);
        
        yPos = windowRect.origin.y;
        
        dropDown = [NIDropDown new];
        
        dropDown.delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        
        [dropDown showDropDownWithRect:final andHeight:&f andView:dict];
    }
    else
    {
        [dropDown hideDropDown];
        
        dropDown = nil;
    }
}

- (void)completion:(DropButtonUpCompletion)_completion
{
    completionUpBlock = _completion;
}

- (void)keyboardWillShow: (NSNotification *)notification
{
    CGSize screenSize = CGSizeMake(screenWidth, screenHeight);
    CGSize dialogSize = CGSizeMake(screenWidth - 16, 110);
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        CGFloat tmp = keyboardSize.height;
        keyboardSize.height = keyboardSize.width;
        keyboardSize.width = tmp;
    }
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         dropDown.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - keyboardSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
                         
                         if(completionUpBlock)
                         {
                             completionUpBlock();
                         }
                     }
                     completion:nil
     ];
}

- (void)didDropDownWithData:(NSArray*)dataList andCustom:(NSDictionary*)dict andCompletion:(DropButtonCompletion)completion
{
    completionBlock = completion;
    
    if(dropDown == nil)
    {
        template = nil;
        
        template = [[NSDictionary new] dictionaryWithPlist:self.pList];
        
        if(!template)
        {
            return;
        }
        
        CGFloat f = [dict[@"height"] floatValue];
        
        CGFloat startRect = [self convertRect:self.bounds toView:nil].origin.x;
        
        CGFloat start = (startRect + [dict[@"width"] floatValue]) > screenWidth ? self.bounds.origin.x - ([dict[@"width"] floatValue] - (self.bounds.origin.x + self.bounds.size.width) - ([dict responseForKey:@"offSetX"] ? [dict[@"offSetX"] floatValue] : 0)) : self.bounds.origin.x;

        CGRect windowRect = [self convertRect:[dict responseForKey:@"width"] ? CGRectMake(start, self.bounds.origin.y  + [dict[@"offSetY"] floatValue], [dict[@"width"] floatValue], self.bounds.size.height) : self.bounds toView:nil];
        
        dropDown = [NIDropDown new];
        
        NSMutableDictionary * extras = [[NSMutableDictionary alloc] initWithDictionary:template];
        
        if([dict responseForKey:@"active"])
        {
            extras[@"active"] = dict[@"active"];
        }
        
        dropDown._template = extras;
        
        dropDown.delegate = self;
        
        [dropDown showDropDownWithRect:windowRect andHeight:&f andData:dataList andDirection:template[@"direction"]];
    }
    else
    {
        [dropDown hideDropDown];
        
        dropDown = nil;
    }
}

- (void)didDropDownWithData:(NSArray*)dataList andInfo:(NSDictionary*)dict andCompletion:(DropButtonCompletion)completion
{
    completionBlock = completion;
    
    if(dropDown == nil)
    {
        template = nil;
        
        template = [[NSDictionary new] dictionaryWithPlist:self.pList];
        
        if(!template)
        {
            return;
        }
        
        CGFloat f = [template[@"height"] floatValue];
        
        CGFloat startRect = [self convertRect:self.bounds toView:nil].origin.x;
        
        CGFloat start = (startRect + [template[@"width"] floatValue]) > screenWidth ? self.bounds.origin.x - ([template[@"width"] floatValue] - (self.bounds.origin.x + self.bounds.size.width)) : self.bounds.origin.x;
        
        if([dict responseForKey:@"center"])
        {
            start = self.bounds.origin.x;
            
            start -= ([template[@"width"] floatValue] - self.bounds.size.width) / 2;
        }
        
        CGRect windowRect = [dict responseForKey:@"rect"] ? [dict[@"rect"] CGRectValue] : [self convertRect:[template responseForKey:@"width"] ? CGRectMake(start, self.bounds.origin.y + ([dict responseForKey:@"center"] ? [dict[@"offSetY"] floatValue] : 0), [template[@"width"] floatValue], self.bounds.size.height) : self.bounds toView:nil];
        
        dropDown = [NIDropDown new];
        
        NSMutableDictionary * extras = [[NSMutableDictionary alloc] initWithDictionary:template];
        
        if([dict responseForKey:@"active"])
        {
            extras[@"active"] = dict[@"active"];
        }
        
        dropDown._template = extras;
        
        dropDown.delegate = self;
        
        [dropDown showDropDownWithRect:windowRect andHeight:&f andData:dataList andDirection:template[@"direction"]];
    }
    else
    {
        [dropDown hideDropDown];
        
        dropDown = nil;
    }
}

- (void)didDropDownWithData:(NSArray*)dataList andCompletion:(DropButtonCompletion)completion
{
    completionBlock = completion;
    
    if(dropDown == nil)
    {
        template = nil;
        
        template = [[NSDictionary new] dictionaryWithPlist:self.pList];
        
        if(!template)
        {
            return;
        }

        CGFloat f = [template[@"height"] floatValue];
        
        CGFloat startRect = [self convertRect:self.bounds toView:nil].origin.x;
        
        CGFloat start = (startRect + [template[@"width"] floatValue]) > screenWidth ? self.bounds.origin.x - ([template[@"width"] floatValue] - (self.bounds.origin.x + self.bounds.size.width)) : self.bounds.origin.x;
        
        CGRect windowRect = [self convertRect:[template responseForKey:@"width"] ? CGRectMake(start, self.bounds.origin.y, [template[@"width"] floatValue], self.bounds.size.height) : self.bounds toView:nil];
        
        dropDown = [NIDropDown new];

        dropDown._template = template;
        
        dropDown.delegate = self;
        
        [dropDown showDropDownWithRect:windowRect andHeight:&f andData:dataList andDirection:template[@"direction"]];
    }
    else
    {
        [dropDown hideDropDown];
        
        dropDown = nil;
    }
}

- (void)niDropDownDelegateMethod:(NIDropDown *)sender
{
    if(sender)
    {
        completionBlock(sender.selectedDetails);
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    dropDown = nil;
}

@end



@interface NIDropDown ()
{    
    NSString * direction;
    
    CGRect rect;
    
    UIButton * cover;
}

@property(nonatomic, retain) NSArray * datalist;

@end

@implementation NIDropDown

@synthesize tableView;

@synthesize datalist;

@synthesize delegate;

@synthesize cellHeight;

@synthesize selectedDetails;

@synthesize _template;

- (id)showDropDownWithRect:(CGRect)_rect andHeight:(CGFloat *)height andView:(NSDictionary*)info
{
    rect = _rect;
    
    {
        direction = @"down";
    }
        
    if (self)
    {
        ((UIView*)info[@"view"]).frame = CGRectMake(0, 0, rect.size.width, *height);
        
        ((UIView*)info[@"view"]).tag = 9999;
        
        ((UIView*)info[@"view"]).alpha = 0;
        
        ((UIView*)info[@"view"]).accessibilityLabel = [NSString stringWithFormat:@"%f",rect.origin.y];
        
        CGRect btn = rect;
        
        self.layer.masksToBounds = NO;

        float heightTemp = *height;
        
        direction = (heightTemp + _rect.origin.y + _rect.size.height) > screenHeight ? @"up" : @"down";
        
        if ([direction isEqualToString:@"up"])
        {
            self.frame = CGRectMake(btn.origin.x, btn.origin.y, btn.size.width, 0);
            
            self.layer.shadowOffset = CGSizeMake(-5, -5);
        }
        else if ([direction isEqualToString:@"down"])
        {
            self.frame = CGRectMake(btn.origin.x, btn.origin.y+btn.size.height, btn.size.width, 0);
            
            self.layer.shadowOffset = CGSizeMake(-5, 5);
        }
        
        [UIView animateWithDuration:0.5 animations:^{
            
            if ([direction isEqualToString:@"up"])
            {
                self.frame = CGRectMake(btn.origin.x, btn.origin.y - heightTemp, btn.size.width, heightTemp);
            }
            else if([direction isEqualToString:@"down"])
            {
                self.frame = CGRectMake(btn.origin.x, btn.origin.y + btn.size.height, btn.size.width, heightTemp);
            }
            
            ((UIView*)info[@"view"]).frame = CGRectMake(0, 0, btn.size.width, heightTemp);
            
            ((UIView*)info[@"view"]).alpha = 1;
            
            ((UIView*)[self withView:((UIView*)info[@"view"]) tag:![direction isEqualToString:@"up"] ? 1 : 2]).alpha = 1;
            
        } completion:^(BOOL finish){}];
        
        [self addSubview:((UIView*)info[@"view"])];
        
        cover = [UIButton buttonWithType:UIButtonTypeCustom];
        
        cover.backgroundColor = [UIColor blackColor];
        
        cover.alpha = 0.4;
        
        cover.frame = CGRectMake(0, 0, screenWidth, screenHeight);
        
        [cover addTarget:self action:@selector(didPressCoverButton) forControlEvents:UIControlEventTouchUpInside];
        
        [[[UIApplication sharedApplication] keyWindow] addSubview:cover];
        
        [[[UIApplication sharedApplication] keyWindow] addSubview:self];
    }
    
    return self;
}

- (id)showDropDownWithRect:(CGRect)_rect andHeight:(CGFloat *)height andData:(NSArray *)data andDirection:(NSString *)_direction
{
    rect = _rect;
    
    if(![_template responseForKey:@"cellheight"])
    {
        cellHeight = 40;
    }
    else
    {
        cellHeight = [_template[@"cellheight"] floatValue];
    }

    direction = _direction;
    
    
    if(![_direction isEqualToString:@"up"] || ![_direction isEqualToString:@"down"])
    {
        direction = @"down";
    }
    
    tableView = (UITableView *)[super init];
    
    if (self)
    {
        CGRect btn = rect;
        
        self.datalist = [NSArray arrayWithArray:data];
        
        self.layer.masksToBounds = NO;

        tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, btn.size.width, 0)];
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.separatorColor = [UIColor clearColor];
        tableView.delegate = self;
        tableView.dataSource = self;
        
        if([_template responseForKey:@"background"] && ((NSString*)_template[@"background"]).length != 0)
        {
            tableView.backgroundColor = [AVHexColor colorWithHexString:_template[@"background"]];
        }
        else
        {
            tableView.backgroundColor = [UIColor clearColor];
        }
        
        if([_template responseForKey:@"round"])
        {
            [tableView withBorder:@{@"Bcorner":_template[@"round"]}];
        }
        
        
        float heightTemp = data.count < 5 ? data.count * cellHeight : *height;
        
        direction = (heightTemp + _rect.origin.y + _rect.size.height) > screenHeight ? @"up" : @"down";
        
        if ([direction isEqualToString:@"up"])
        {
            self.frame = CGRectMake(btn.origin.x, btn.origin.y, btn.size.width, 0);
            self.layer.shadowOffset = CGSizeMake(-5, -5);
        }
        else if ([direction isEqualToString:@"down"])
        {
            self.frame = CGRectMake(btn.origin.x, btn.origin.y+btn.size.height, btn.size.width, 0);
            self.layer.shadowOffset = CGSizeMake(-5, 5);
        }
        
        [UIView animateWithDuration:0.5 animations:^{
            
            if ([direction isEqualToString:@"up"])
            {
                self.frame = CGRectMake(btn.origin.x, btn.origin.y- heightTemp, btn.size.width, heightTemp);
            }
            else if([direction isEqualToString:@"down"])
            {
                self.frame = CGRectMake(btn.origin.x, btn.origin.y + btn.size.height, btn.size.width, heightTemp);
            }
            tableView.frame = CGRectMake(0, 0, btn.size.width, heightTemp);
            
        } completion:^(BOOL finish){}];
        
        [self addSubview:tableView];

        cover = [UIButton buttonWithType:UIButtonTypeCustom];
        
        cover.backgroundColor = [UIColor blackColor];
        
        cover.alpha = 0.4;
        
        cover.frame = CGRectMake(0, 0, screenWidth, screenHeight);
        
        [cover addTarget:self action:@selector(didPressCoverButton) forControlEvents:UIControlEventTouchUpInside];
        
        [[[UIApplication sharedApplication] keyWindow] addSubview:cover];
        
        [[[UIApplication sharedApplication] keyWindow] addSubview:self];
        
        if([_template responseForKey:@"active"])
        {
            [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[_template[@"active"] intValue] inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
    return self;
}

- (void)didPressCoverButton
{
    [self hideDropDown];
    
    [cover removeFromSuperview];
    
    [self.delegate niDropDownDelegateMethod:self];
}

- (void)hideDropDown
{
    CGRect btn = rect;

    [UIView animateWithDuration:0.5 animations:^{
    
        if(![self.subviews containsObject:((UIView*)[self withView:self tag:9999])])
        {
            if ([direction isEqualToString:@"up"])
            {
                self.frame = CGRectMake(btn.origin.x, btn.origin.y, btn.size.width, 0);
            }
            else if ([direction isEqualToString:@"down"])
            {
                self.frame = CGRectMake(btn.origin.x, btn.origin.y+btn.size.height, btn.size.width, 0);
            }
            
            tableView.frame = CGRectMake(0, 0, btn.size.width, 0);
        }
        else
        {
            ((UIView*)[self withView:self tag:9999]).alpha = 0;
        }
        
    } completion:^(BOOL finished) {
        
        if(finished)
        {
            [self removeFromSuperview];
        }
        
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return cellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.datalist count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:_template[@"identifier"]];
    
    if (cell == nil)
    {
        cell = [[NSBundle mainBundle] loadNibNamed:_template[@"nib"] owner:self options:nil][0];
    }
    
    if([_template responseForKey:@"items"])
    {
        for(NSString * tag in ((NSDictionary*)_template[@"items"]).allKeys)
        {
            ((UILabel*)[self withView:cell tag:[tag intValue]]).text = self.datalist[indexPath.row][_template[@"items"][tag]];
        }
    }
    
    if([_template responseForKey:@"images"])
    {
        for(NSString * tag in ((NSDictionary*)_template[@"images"]).allKeys)
        {
            if([self.datalist[indexPath.row][_template[@"images"][tag]] myContainsString:@"http"])
            {
                [((UIImageView*)[self withView:cell tag:[tag intValue]]) sd_setImageWithURL:[NSURL URLWithString:self.datalist[indexPath.row][_template[@"images"][tag]]] placeholderImage:nil];
            }
            else
            {
                ((UIImageView*)[self withView:cell tag:[tag intValue]]).image = [UIImage imageNamed:self.datalist[indexPath.row][_template[@"images"][tag]]];
            }
        }
    }
    
    if([_template responseForKey:@"hilight"])
    {
        UIView *bgColorView = [[UIView alloc] init];
        
        bgColorView.backgroundColor = [AVHexColor colorWithHexString:_template[@"hilight"]];
        
        [cell setSelectedBackgroundView:bgColorView];
    }
    
    if([_template responseForKey:@"cellbackground"] && ((NSArray*)_template[@"cellbackground"]).count > 1)
    {
        cell.backgroundColor = [AVHexColor colorWithHexString:((NSString*)_template[@"cellbackground"][indexPath.row % 2 == 0 ? 0 : 1]).length == 0 ? @"#FFFFFF" : _template[@"cellbackground"][indexPath.row % 2 == 0 ? 0 : 1]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self hideDropDown];

    if([self.subviews containsObject:((UIView*)[self withView:self tag:9999])])
    {
        selectedDetails = @{@"data":self.datalist[indexPath.row], @"index":@(indexPath.row), @"object":self, @"view":((UIView*)[self withView:self tag:9999])};
    }
    else
    {
        selectedDetails = @{@"data":self.datalist[indexPath.row], @"index":@(indexPath.row), @"object":self};
    }
    
    [self myDelegate];
}

- (void)myDelegate
{
    [self.delegate niDropDownDelegateMethod:self];
    
    [cover removeFromSuperview];
}


@end


@implementation DropButton (pList)

- (void)setPListName:(NSString *)pListName
{
    self.pList = pListName;
}

- (NSString*)pListName
{
    return self.pList;
}

@end

