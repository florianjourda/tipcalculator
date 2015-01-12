//
//  PrefsHelper.h
//  tipcalculator
//
//  This helper deals with saving/retrieving values for app preferences.
//  It provides support for default preferences values, and allow preferences to be saved with an expiration (TTL).
//
//  Created by Florian Jourda on 12/14/14.
//  Copyright (c) 2014 Box. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PrefsHelper : NSObject

+ (void)useDefaultPrefsFile:(NSString *)defaultPrefsFileName;
+ (id)readPref:(NSString *)prefKey;
+ (void)writePref:(NSString *)prefKey withObject:(id)prefObject;
+ (void)writePref:(NSString *)prefKey withObject:(id)prefObject withExpiration:(NSTimeInterval)expirationTimeInterval;

@end
