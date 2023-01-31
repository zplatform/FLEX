//
//  Copyright © 2019 Zalo Group. All rights reserved.
//  Created on 7/2019
//

#import "FLEXManager.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Support for share extension.
 */
@interface ZFLEXManager : FLEXManager

+ (instancetype)sharedManager;

@property (weak) UIWindow *cacheWindow;

- (void)enableInAppActive;

@end

NS_ASSUME_NONNULL_END
