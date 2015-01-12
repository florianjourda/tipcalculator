//
//  PrefsHelper.m
//  tipcalculator
//
//  This helper deals with saving/retrieving values for app preferences.
//  It provides support for default preferences values, and allow preferences to be saved with an expiration (TTL).
//
//  Created by Florian Jourda on 12/14/14.
//  Copyright (c) 2014 Box. All rights reserved.
//

#import "PrefsHelper.h"
#import "NSDateAdditions.h"

static NSDictionary *defaultPrefs = nil;

@implementation PrefsHelper


/**
 * Set which plist file to use to get the default values of the app preferences
 */
+ (void)useDefaultPrefsFile:(NSString *)defaultPrefsFileName {
  NSString *defaultPrefsFile = [[NSBundle mainBundle] pathForResource:defaultPrefsFileName ofType:@"plist"];
  defaultPrefs = [NSDictionary dictionaryWithContentsOfFile:defaultPrefsFile];
}

/**
 * Get the value of an app preference.
 * 
 * First return the saved value from previous sessions if it has not expired
 * Otherwise return the default value indicated in the plist prefs file.
 */
+ (id)readPref:(NSString *)prefKey {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  id prefObject = [defaults objectForKey:prefKey];
  if (prefObject != nil) {
    // Use saved value only if there is no expiration date or if the expiration date has not passed yet
    NSString *prefExpirationKey = [self generatePrefExpirationKey:prefKey];
    NSDate *expirationDate = [defaults objectForKey:prefExpirationKey];
    NSDate *now = [NSDate date];
    if ([now isEarlierThanOrEqualTo:expirationDate]) {
      return prefObject;
    }
  }
  id defaultPrefValue = defaultPrefs[prefKey];
  return defaultPrefValue;
}

/**
 * Save an app preference, so that it will be available in future app sessions
 */
+ (void)writePref:(NSString *)prefKey withObject:(id)prefObject {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:prefObject forKey:prefKey];
  [defaults synchronize];
}

/**
 * Save an app preference, so that it will be available in future app sessions that happen before a certain expiration time interval
 */
+ (void)writePref:(NSString *)prefKey withObject:(id)prefValue withExpiration:(NSTimeInterval)expirationTimeInterval{
  NSDate *now = [NSDate date];
  NSDate *expirationDate = [NSDate dateWithTimeInterval:expirationTimeInterval sinceDate:now];
  NSString *prefExpirationKey = [self generatePrefExpirationKey:prefKey];
  [self writePref:prefExpirationKey withObject:expirationDate];
  [self writePref:prefKey withObject:prefValue];
}

/**
 * Create a key to store information about when a preference saved value should expire
 */
+ (NSString *)generatePrefExpirationKey:(NSString *)prefKey {
  // Use double '__' to avoid collision with other keys, which are supposed to use only simpe '_'
  return [prefKey stringByAppendingString:@"__expiration__"];
}

@end
