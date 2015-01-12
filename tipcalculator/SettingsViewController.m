//
//  SettingsViewController.m
//  tipcalculator
//
//  Created by Florian Jourda on 12/11/14.
//  Copyright (c) 2014 Box. All rights reserved.
//

#import "SettingsViewController.h"
#import "PrefsHelper.h"
#import "ColorThemeHelper.h"

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *themeLabel;
@property (weak, nonatomic) IBOutlet UITextField *defaultPercentTipTextField;
@property (weak, nonatomic) IBOutlet UIPickerView *currencyPicker;
@property (weak, nonatomic) IBOutlet UISegmentedControl *colorThemeSegmentedControl;
@property (strong, nonatomic) NSArray *currencyCodes;
@property (strong, nonatomic) NSMutableArray *currencyTitles;
@property NSArray *colorSchemeIds;

- (IBAction)onTap:(id)sender;
- (IBAction)onColorThemeValueChanged:(id)sender;
- (void) initDefaultTipAmount;
- (void) saveDefaultTipAmount;

@end

@implementation SettingsViewController


- (void)viewDidLoad {
  [super viewDidLoad];
  self.colorSchemeIds = @[@"dark", @"light"];
  self.defaultPercentTipTextField.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {
  [ColorThemeHelper applySavedColorTheme:self.view];
  [self initView];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self saveDefaultTipAmount];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)onTap:(id)sender {
  [self.view endEditing:YES];
  [self saveDefaultTipAmount];
  [[UILabel appearanceWhenContainedIn:[UIPickerView class], nil] setTextColor:[UIColor orangeColor]];
}

- (IBAction)onColorThemeValueChanged:(id)sender {
  NSInteger selectedColorThemeIndex = [self.colorThemeSegmentedControl selectedSegmentIndex];
  NSString *colorSchemeId = self.colorSchemeIds[selectedColorThemeIndex];
  [ColorThemeHelper saveColorTheme:colorSchemeId];
  [ColorThemeHelper applySavedColorTheme:self.view];
}

- (void)initView {
  [self initDefaultTipAmount];
  [self initCurrencyPicker];
  [self initColorSchemeSegementedControl];
}

- (void)initDefaultTipAmount {
  float defaultPercentTipAmount = [[PrefsHelper readPref:@"default_percent_tip_amount"] floatValue];
  self.defaultPercentTipTextField.text = [NSString stringWithFormat:@"%0.0f", defaultPercentTipAmount];
}

- (void)saveDefaultTipAmount {
  float defaultPercentTipAmount = [self.defaultPercentTipTextField.text floatValue];
  [PrefsHelper writePref:@"default_percent_tip_amount" withObject:[NSNumber numberWithFloat:defaultPercentTipAmount]];
}

- (void)initCurrencyPicker {
  // Prepare the currency data source
  NSLocale *locale = [NSLocale currentLocale];

  // @TODO: Understand this Xcode bug
  // This is a fix for some weird bug in Xcode: the default local en_US is not working properly
  // and we need to get a working reference
  if ([[locale localeIdentifier] isEqual:@"en_US"]) {
    locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
  }

  // We duplicate the top currencies at the top for better UX
  NSArray *topCurrencyCodes = @[@"USD", @"EUR", @"GBP", @"JPY"];
  self.currencyCodes = [topCurrencyCodes arrayByAddingObjectsFromArray:[NSLocale ISOCurrencyCodes]];
  self.currencyTitles = [[NSMutableArray alloc] initWithCapacity:self.currencyCodes.count];

  // Populate self.currencyTitles
  for (int i = 0; i < self.currencyCodes.count; i++) {
    NSString *currencyCode = [self.currencyCodes objectAtIndex:i];
    NSString *currencyTitle = [locale displayNameForKey:NSLocaleCurrencySymbol value:currencyCode];
    NSLog(@"%@: %@: %@", [locale localeIdentifier], currencyCode, currencyTitle);
    // Some arcane currencies may not be known in the user locale
    if (currencyTitle == nil) {
      currencyTitle = currencyCode;
    }
    [self.currencyTitles insertObject:currencyTitle atIndex:i];
  }

  // Select current currency
  NSString *currentCurrencyCode = [PrefsHelper readPref:@"currency_code"];
  NSUInteger currentIndex = [self.currencyCodes indexOfObject:currentCurrencyCode];
  [self.currencyPicker selectRow:currentIndex inComponent:0 animated:false];
}

- (void)saveCurrencyCode:(NSString*)currencyCode {
  [PrefsHelper writePref:@"currency_code" withObject:currencyCode];
}

- (void)initColorSchemeSegementedControl {
  NSString *currentColorSchemeId = [ColorThemeHelper getSavedColorSchemeId];
  NSInteger currentSegmentIndex = [self.colorSchemeIds indexOfObject:currentColorSchemeId];
  [self.colorThemeSegmentedControl setSelectedSegmentIndex:currentSegmentIndex];
}

#pragma mark -
#pragma mark PickerView DataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return self.currencyTitles.count;
}

/**
 * We need to create the label manually like this, otherwise the UILabel text color is not respected
 */
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {

  UILabel *pickerLabel = (UILabel *)view;

  if (pickerLabel == nil) {
    CGRect frame = CGRectMake(0.0, 0.0, 70, 32);
    pickerLabel = [[UILabel alloc] initWithFrame:frame];
    [pickerLabel setTextAlignment:NSTextAlignmentRight];
    [pickerLabel setBackgroundColor:[UIColor clearColor]];
    [pickerLabel setTextColor:UILabel.appearance.textColor];
    [pickerLabel setFont:[UIFont boldSystemFontOfSize:17]];
  }

  pickerLabel.text = self.currencyTitles[row];
  
  return pickerLabel;
  
}

#pragma mark -
#pragma mark PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
  NSString *currencyCode = self.currencyCodes[row];
  [self saveCurrencyCode:currencyCode];
}

@end
