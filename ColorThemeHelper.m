//
//  ColorThemeHelper.m
//  tipcalculator
//
//  Created by Florian Jourda on 12/23/14.
//  Copyright (c) 2014 Box. All rights reserved.
//

#import "ColorThemeHelper.h"
#import "PrefsHelper.h"
#import "UIKit/UIColor.h"
#import "UIKit/UIWindow.h"
#import "UIKit/UILabel.h"

static NSMutableDictionary *colorSchemes;

@interface ColorThemeHelper ()

@end

@implementation ColorThemeHelper

/**
 * Define what colors a color scheme will use
 */
+ (void)defineColorScheme:(NSString*)colorSchemeId withTextColor:(UIColor*)textColor withBackgrounColor:(UIColor*)backgroundColor {
 // struct ColorScheme colorscheme;
  NSDictionary *colorScheme = [NSDictionary dictionaryWithObjectsAndKeys:
    textColor, @"textColor",
    backgroundColor, @"backgroundColor",
    nil
  ];
  if (colorSchemes == nil) {
    colorSchemes = [NSMutableDictionary dictionary];
  }
  [colorSchemes setValue:colorScheme forKey:colorSchemeId];
}

/**
 * Persist which color theme is currently used
 */
+ (void)saveColorTheme:(NSString*)colorSchemeId {
  [PrefsHelper writePref:@"color_scheme_id" withObject:colorSchemeId];
}

/**
 * Return saved color scheme
 */
+ (NSString*)getSavedColorSchemeId {
  return [PrefsHelper readPref:@"color_scheme_id"];
}

/**
 * Apply saved color theme
 */
+ (void)applySavedColorTheme:(UIView*)view {
  // Retrieve color theme from preferences
  NSString *colorSchemeId = [self getSavedColorSchemeId];
  NSDictionary *colorScheme = colorSchemes[colorSchemeId];
  UIColor *textColor = colorScheme[@"textColor"];
  UIColor *backgroundColor = colorScheme[@"backgroundColor"];

  UIWindow *window = [[UIApplication sharedApplication] keyWindow];
  [window setTintColor:textColor];
  [view setTintColor:textColor];
  [window setBackgroundColor:backgroundColor];
  [view setBackgroundColor:backgroundColor];
  [[UILabel appearance] setTintColor:textColor];
  [[UILabel appearance] setTextColor:textColor];
  [[UITextField appearance] setTextColor:textColor];
  [[UITextField appearance] setTintColor:textColor];
  [[UITextField appearance] setBackgroundColor:backgroundColor];
  [window setNeedsDisplay];
  [view setNeedsLayout];
}

@end
