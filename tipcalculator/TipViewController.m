//
//  TipViewController.m
//  tipcalculator
//
//  Created by Florian Jourda on 12/11/14.
//  Copyright (c) 2014 Box. All rights reserved.
//

#import "TipViewController.h"
#import "SettingsViewController.h"
#import "PrefsHelper.h"
#import "ColorThemeHelper.h"

typedef enum UIMode {
  Undefined,
  Normal,
  FullScreen
} UIMode;

@interface TipViewController ()
@property (weak, nonatomic) IBOutlet UIView *labelsView;
@property (weak, nonatomic) UITextField *billTextField;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *tipControl;
@property float billAmount;
@property NSArray *tipValues;
@property NSNumberFormatter *amountFormatter;
@property (nonatomic, assign) UIMode uiMode;

- (IBAction)onTap:(id)sender;

@end

@implementation TipViewController
// TODO
// - add animation
// - fix text color for currency picker

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.title = @"Tip Calculator";
  }
  return self;
}

// ********* View Events *********

- (void)viewDidLoad {
  NSLog(@"viewDidLoad");
  [super viewDidLoad];

  [ColorThemeHelper defineColorScheme:@"dark" withTextColor:[UIColor orangeColor] withBackgrounColor:[UIColor blackColor]];
  [ColorThemeHelper defineColorScheme:@"light" withTextColor:[UIColor orangeColor] withBackgrounColor:[UIColor whiteColor]];

  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(onSettingsButton)];

  float billAmountFromPreviousSession = [[PrefsHelper readPref:@"bill_amount"] floatValue];
  self.billAmount = billAmountFromPreviousSession;

  NSString *currencyCode = [PrefsHelper readPref:@"currency_code"];
  [self setCurrencyCode:currencyCode];

  [self createBillAmountTextField];
  if (self.billAmount == 0) {
    // If no billAmount at start, then enter directly in the full screen mode to ask to enter a billAmount
    self.billTextField.text = @"";
  } else {
    [self updateBillAmountTextFieldForDisplaying];
  }
  [self placeBillAmountTextField];
}

- (void)viewWillAppear:(BOOL)animated {
  NSLog(@"view will appear");
  [ColorThemeHelper applySavedColorTheme:self.view];
}

- (void)viewDidAppear:(BOOL)animated {
  NSLog(@"view did appear");

  // Update in case changes happened in Settings
  NSString *currencyCode = [PrefsHelper readPref:@"currency_code"];
  [self setCurrencyCode:currencyCode];
  [self updateDefautPercentTipAmountView];
  [self updateTipAndTotalAmountViews];

  if (self.uiMode == Normal) {
    [self updateBillAmountTextFieldForDisplaying];
  } else {
    [self.billTextField becomeFirstResponder];
    [self updateBillAmountTextFieldForStartingEditing];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  if (self.uiMode == Normal) {
    [self.view endEditing:YES];
  }
  NSLog(@"view will disappear");
}

- (void)viewDidDisappear:(BOOL)animated {
  NSLog(@"view did disappear");
}

- (void)onSettingsButton {
  [self.navigationController pushViewController:[[SettingsViewController alloc] init] animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onTap:(id)sender {
  if (self.uiMode == FullScreen) {
    // We want to keep the focus on the billAmountTextField when we put it on fullscreen mode
    return;
  }
  [self.view endEditing:YES];
  [self updateTipAndTotalAmountViews];
}

// ********* billAmountTextField delegate *********

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
  NSLog(@"textField:shouldChangeCharactersInRange:replacementString:");
  // textField can only be self.billTextField in the current setup

  NSString *newBillAmountString = [self.billTextField.text stringByReplacingCharactersInRange:range withString:string];
  // Remove currency symbol that we show when the input is empty
  newBillAmountString = [newBillAmountString stringByReplacingOccurrencesOfString:self.amountFormatter.currencySymbol withString:@""];
  self.billTextField.text = newBillAmountString;

  float newBillAmount = [self.billTextField.text floatValue];
  [self saveNewBillAmount:newBillAmount];
  [self updateTipAndTotalAmountViews];
  [UIView animateWithDuration:0.5 animations:^{
    [self placeBillAmountTextField];
  } completion:^(BOOL finished) {
    // Do something here when the animation finishes.
  }];
  return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  [self updateBillAmountTextFieldForEditing];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  [self updateBillAmountTextFieldForDisplaying];
}


// ********* State Updates *********

- (void)saveNewBillAmount:(float)billAmount {
  self.billAmount = billAmount;
  NSTimeInterval billAmountExpiration = 600; // Forget bill amount after 10 min (600 s)
  [PrefsHelper writePref:@"bill_amount" withObject:[NSNumber numberWithFloat:self.billAmount] withExpiration:billAmountExpiration];
}

- (void)setCurrencyCode:(NSString *)currencyCode {
  NSNumberFormatter *amountFormatter = [[NSNumberFormatter alloc] init];
  [amountFormatter setFormatterBehavior: NSNumberFormatterBehavior10_4];
  [amountFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
  [amountFormatter setCurrencyCode:currencyCode];

  // Hacky way to get the currencySymbol
  NSString *symbolString = [amountFormatter stringFromNumber:[NSNumber numberWithFloat:0]];
  symbolString = [symbolString stringByReplacingOccurrencesOfString:@"0" withString:@""];
  symbolString = [symbolString stringByReplacingOccurrencesOfString:@"," withString:@""];
  symbolString = [symbolString stringByReplacingOccurrencesOfString:@"." withString:@""];
  [amountFormatter setCurrencySymbol:symbolString];

  self.amountFormatter = amountFormatter;
}

// ********* View Updates ***********

/**
 * Create billTextField programmatically as changing the position of an IB created UITextField is buggy
 * TODO: understand why billTextField could not be moved when created through IB
 * UPDATE: actually it was an issue with Auto Layout, so we could get back to IB if we wanted
 */
- (void)createBillAmountTextField {
  CGRect frame = CGRectMake(0, 300, 200, 80);
  UITextField* textField = [[UITextField alloc] initWithFrame:frame];
  self.billTextField = textField;
  self.billTextField.borderStyle = UITextBorderStyleNone;
  self.billTextField.textAlignment = NSTextAlignmentRight;
  self.billTextField.font = [UIFont systemFontOfSize:40.0];
  self.billTextField.keyboardType = UIKeyboardTypeDecimalPad;
  self.billTextField.delegate = self;
  [self.view addSubview:self.billTextField];
}


- (void)placeBillAmountTextField {
  if (self.billTextField.text.length == 0) {
    [self updateBillAmountTextFieldForStartingEditing];
    if (self.uiMode != FullScreen) {
      [self placeBillAmountTextFieldInFullScreenMode];
      self.uiMode = FullScreen;
    }
  } else {
    if (self.uiMode != Normal) {
      [self placeBillAmountTextFieldInNormalMode];
      self.uiMode = Normal;
    }
  }
}

- (void)placeBillAmountTextFieldInNormalMode {
  [self.billTextField setFrame:CGRectMake(16.0, 80.0, 280.0, 60.0)];

  [self.tipControl setFrame:CGRectMake(self.tipControl.frame.origin.x, 160.0, self.tipControl.frame.size.width, self.tipControl.frame.size.height)];
  self.tipControl.alpha = 1.0;

  [self.tipLabel setFrame:CGRectMake(self.tipLabel.frame.origin.x, 220.0, self.tipLabel.frame.size.width, self.tipLabel.frame.size.height)];
  self.tipLabel.alpha = 1.0;

  [self.totalLabel setFrame:CGRectMake(self.totalLabel.frame.origin.x, 260.0, self.totalLabel.frame.size.width, self.totalLabel.frame.size.height)];
  self.totalLabel.alpha = 1.0;

}

- (void)placeBillAmountTextFieldInFullScreenMode {
  [self.billTextField setFrame:CGRectMake(16.0, 200.0, 280.0, 60.0)];

  // y = +200
  [self.tipControl setFrame:CGRectMake(self.tipControl.frame.origin.x, 360.0, self.tipControl.frame.size.width, self.tipControl.frame.size.height)];
  self.tipControl.alpha = 0.0;

  // y = +250 to give different speed than tipControl
  [self.tipLabel setFrame:CGRectMake(self.tipLabel.frame.origin.x, 450.0, self.tipLabel.frame.size.width, self.tipLabel.frame.size.height)];
  self.tipLabel.alpha = 0.0;

  // y = +300 to give different speed than tipLabel
  [self.totalLabel setFrame:CGRectMake(self.totalLabel.frame.origin.x, 560.0, self.totalLabel.frame.size.width, self.totalLabel.frame.size.height)];
  self.totalLabel.alpha = 0.0;
}

- (void)updateBillAmountTextFieldForDisplaying {
  self.billTextField.text = [self formatAmount:self.billAmount];
}

- (void)updateBillAmountTextFieldForStartingEditing {
  self.billTextField.text = self.amountFormatter.currencySymbol;
}

- (void)updateBillAmountTextFieldForEditing {
  NSString *stringBillAmountForEditing = [NSString stringWithFormat:@"%0.2f", self.billAmount];
  // Remove .00 as it cumbersome when editing
  if ([stringBillAmountForEditing hasSuffix:@".00"]) {
    stringBillAmountForEditing = [stringBillAmountForEditing substringToIndex:stringBillAmountForEditing.length-3];
  }
  if ([stringBillAmountForEditing isEqualToString:@"0"]) {
    // Do not display "0" but "", since the user will need to delete it right away
    stringBillAmountForEditing = @"";
  }
  self.billTextField.text = stringBillAmountForEditing;
}

- (void)updateTipAndTotalAmountViews {
  float tipAmount = self.billAmount * [self.tipValues[self.tipControl.selectedSegmentIndex] floatValue];
  float totalAmount = self.billAmount + tipAmount;
  self.tipLabel.text = [self formatAmount:tipAmount];
  self.totalLabel.text = [self formatAmount:totalAmount];
}

- (void)updateDefautPercentTipAmountView {
  float defaultPercentTipAmount = [[PrefsHelper readPref:@"default_percent_tip_amount"] floatValue];
  float defaultTipAmount = defaultPercentTipAmount / 100;
  // Create the array of the different tip values
  self.tipValues = [NSArray arrayWithObjects:
    [NSNumber numberWithFloat:0.10], // 10%
    [NSNumber numberWithFloat:0.20], // 20%
    [NSNumber numberWithFloat:defaultTipAmount], // custom%
    nil
  ];
  // Order the tipValues by increasing order
  self.tipValues = [self.tipValues sortedArrayUsingSelector:@selector(compare:)];
  // Update the control
  for (int i = 0; i < self.tipValues.count; i++) {
    NSNumber *tipValue = self.tipValues[i];
    [self.tipControl setTitle:[NSString stringWithFormat:@"%0.0f%%", 100 * [tipValue floatValue]] forSegmentAtIndex:i];
  }
}

// ********* View Helpers ***********

/**
 * Format amount with currency format
 * @example
 * 15.6 => $15.60
 * 10 => 10.00€
 */
- (NSString *)formatAmount:(float)amount {
  NSString *formattedAmount = [self.amountFormatter stringFromNumber:[NSNumber numberWithFloat:amount]];
  return formattedAmount;
}

@end
