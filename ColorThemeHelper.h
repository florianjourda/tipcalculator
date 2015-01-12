//
//  ColorThemeHelper.h
//  tipcalculator
//
//  Created by Florian Jourda on 12/23/14.
//  Copyright (c) 2014 Box. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIColor.h"
#import "UIKit/UIView.h"

@interface ColorThemeHelper : NSObject

+ (void)defineColorScheme:(NSString*)colorSchemeId withTextColor:(UIColor*)textColor withBackgrounColor:(UIColor*)backgroundColor;
+ (void)saveColorTheme:(NSString*)colorSchemeId;
+ (NSString*)getSavedColorSchemeId;
+ (void)applySavedColorTheme:(UIView*)view;

@end
