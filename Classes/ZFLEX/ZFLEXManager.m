//
//  Copyright © 2019 Zalo Group. All rights reserved.
//  Created on 7/2019
//

#import "ZFLEXManager.h"
#import "FLEXExplorerViewController.h"
#import "FLEXWindow.h"

@interface ZFLEXView : UIView

@property (nonatomic, weak) id <FLEXWindowEventDelegate> eventDelegate;

@end

@implementation ZFLEXView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL pointInside = NO;
    if ([self.eventDelegate shouldHandleTouchAtPoint:point]) {
        pointInside = [super pointInside:point withEvent:event];
    }
    
    return pointInside;
}

- (void)layoutSubviews {
    UIView *v = [self viewWithTag:123];
    [self bringSubviewToFront:v];
    [super layoutSubviews];
}

@end

// MARK: -

@interface FLEXExplorerViewController ()

- (NSArray<UIView *> *)allRecursiveSubviewsInView:(UIView *)view;
- (NSArray<UIView *> *)recursiveSubviewsAtPoint:(CGPoint)pointInView inView:(UIView *)view skipHiddenViews:(BOOL)skipHidden;

@end

// MARK: -

@interface ZFLEXExplorerViewController : FLEXExplorerViewController

@property (weak) UIWindow *cacheWindow;

@end

@implementation ZFLEXExplorerViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        UIView *view = self.view;
        ZFLEXView *v = [[ZFLEXView alloc] initWithFrame:view.frame];
        [view removeFromSuperview];
        [v addSubview:view];
        self.view = v;
        view.tag = 123;
    }
    
    return self;
}

- (NSArray<UIView *> *)allViewsInHierarchy {
    NSMutableArray<UIView *> *allViews = [NSMutableArray array];
    NSArray<UIView *> *windows = [self allViews];
    for (UIView *window in windows) {
        [allViews addObject:window];
        [allViews addObjectsFromArray:[self allRecursiveSubviewsInView:window]];
    }
    
    return allViews;
}

- (UIView *)viewForSelectionAtPoint:(CGPoint)tapPointInWindow {
    // Select in the window that would handle the touch, but don't just use the result of hitTest:withEvent: so we can still select views with interaction disabled.
    // Default to the the application's key window if none of the windows want the touch.
    UIView *windowForSelection = [[UIApplication sharedApplication] keyWindow];
    for (UIView *window in [[self allViews] reverseObjectEnumerator]) {
        if ([window hitTest:tapPointInWindow withEvent:nil]) {
            windowForSelection = window;
            break;
        }
    }
    
    // Select the deepest visible view at the tap point. This generally corresponds to what the user wants to select.
    return [[self recursiveSubviewsAtPoint:tapPointInWindow inView:windowForSelection skipHiddenViews:YES] lastObject];
}

- (NSArray<UIView *> *)viewsAtPoint:(CGPoint)tapPointInWindow skipHiddenViews:(BOOL)skipHidden {
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    for (UIView *window in [self allViews]) {
        if ([window pointInside:tapPointInWindow withEvent:nil]) {
            [views addObject:window];
            [views addObjectsFromArray:[self recursiveSubviewsAtPoint:tapPointInWindow inView:window skipHiddenViews:skipHidden]];
        }
    }
    return views;
}

- (NSArray *)allViews {
    UIWindow *w = self.cacheWindow;
    if (w) {
        NSMutableArray *a = [NSMutableArray new];
        for (UIView *v in w.subviews) {
            if (![v isKindOfClass:ZFLEXView.class]) {
                [a addObject:v];
            }
        }
        return a;
    }
    return @[];
}

@end

// MARK: -

@interface FLEXManager () <FLEXWindowEventDelegate, FLEXExplorerViewControllerDelegate>
@end

@interface ZFLEXManager ()
@property (nonatomic, strong) ZFLEXExplorerViewController *explorerViewController;
@end

@implementation ZFLEXManager

+ (instancetype)sharedManager {
    static ZFLEXManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}

- (ZFLEXExplorerViewController *)explorerViewController {
    if (!_explorerViewController) {
        _explorerViewController = [[ZFLEXExplorerViewController alloc] init];
        _explorerViewController.delegate = self;
        ZFLEXView *v = (ZFLEXView *)_explorerViewController.view;
        v.eventDelegate = self;
    }
    return _explorerViewController;
}

- (void)showExplorer {
    UIView *view = self.explorerViewController.view;
    UIView *parentView = self.cacheWindow;
    view.hidden = NO;
    if (view.superview != parentView) {
        [view removeFromSuperview];
        [parentView addSubview:view];
        self.explorerViewController.cacheWindow = self.cacheWindow;
    }
    
    [parentView bringSubviewToFront:view];
}

- (void)hideExplorer {
    self.explorerViewController.view.hidden = YES;
}

- (void)toggleExplorer {
    if (self.isHidden) {
        [self showExplorer];
    } else {
        [self hideExplorer];
    }
}

- (BOOL)isHidden {
    UIView *view = self.explorerViewController.view;
    UIView *parentView = self.cacheWindow;
    return view.isHidden || parentView.subviews.lastObject != view;
}

- (void)enableInAppActive {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidActive)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)appDidActive {
    if (self.isHidden) {
        [self showExplorer];
    }
}

@end
