//
//  LoginViewController.h
//  tipsi
//
//  Created by Kow Ai Woon on 1/28/13.
//  Copyright (c) 2013 tipsi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomAlertView.h"

@interface LoginViewController: UIViewController  <UITextFieldDelegate,UIActionSheetDelegate> 

- (IBAction)logIn:(id)sender;
- (IBAction)resetPassword:(id)sender;
- (void) confirmPassword:(NSString*)email :(NSString*)message;

@property (nonatomic) BOOL isReportingError;

@property (nonatomic, strong) NSArray *twitterAccounts;


- (IBAction)closeLoadingView:(id)sender;
- (IBAction)cancelPressed:(id)sender;
- (IBAction)facebookLogin:(id)sender;

- (IBAction)twitterLogin:(id)sender;

- (IBAction)emailLogin:(id)sender;

@end
