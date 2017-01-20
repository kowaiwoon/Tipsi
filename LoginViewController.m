//
//  LoginViewController.m
//  tipsi
//
//  Created by Kow Ai Woon on 1/28/13. Edited by Todd on 10/31/2014
//  Copyright (c) 2013-14 tipsi. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"

#import "TipsiAPI.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import <Accounts/ACAccountStore.h>
#import <Accounts/ACAccountType.h>

#import "AppConstants.h"


@interface LoginViewController ()

@property (nonatomic,strong) FBSession *fbSession;

@property (nonatomic,assign)    BOOL bShowKeyboard;
@property (nonatomic,assign)    BOOL isEmailLoginPanelActive;
@property (nonatomic,assign)    BOOL isLoadingViewActive;
// UI
@property (weak, nonatomic) IBOutlet UIView *greyView;
@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *logInButton;
@property (nonatomic, strong) UITapGestureRecognizer* tapGesture;
@property (weak, nonatomic) IBOutlet UIButton *btnResetPassword;
@property (weak, nonatomic) IBOutlet UIView *emailLoginView;
@property (weak, nonatomic) IBOutlet UIView *mainText;
@property (weak, nonatomic) IBOutlet UIImageView *twitterButton;
@property (weak, nonatomic) IBOutlet UIImageView *facebookButton;

@property (weak, nonatomic) IBOutlet UIButton *goToEmailLogin;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIButton *closeButtonInLoadView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

- (void) login;

@end


@implementation LoginViewController

@synthesize isReportingError = _isReportingError;

#pragma mark -
#pragma mark View Methods

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
   [self.loadingView setHidden:YES];
    
   
    self.isEmailLoginPanelActive = NO;
    
    NSUserDefaults* pref = [NSUserDefaults standardUserDefaults];
    
    self.email.text = [pref valueForKey:@"users_email_address"];
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.loadingView setHidden:YES];
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideLoadingView) name:@"HideLoadingView" object:nil];
    
    //Facebook notification : add
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookSuccessfulDeviceAuthorization) name:@"FacebookSuccessfulDeviceAuthorization" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookFailedDeviceAuthorization) name:@"FacebookFailedDeviceAuthorization" object:nil];
    //Twitter notification : add
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twitterSuccessfulDeviceAuthorizationWithMultipleAccounts) name:@"TwitterSuccessfulDeviceAuthorizationWithMultipleAccounts" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twitterSuccessfulDeviceAuthorization) name:@"TwitterSuccessfulDeviceAuthorization" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twitterFailedDeviceAuthorization) name:@"TwitterFailedDeviceAuthorization" object:nil];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"HideLoadingView" object:nil];
    
    //Facebook notification : remove
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FacebookSuccessfulDeviceAuthorization" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FacebookFailedDeviceAuthorization" object:nil];
    //Twitter notification : remove
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TwitterSuccessfulDeviceAuthorizationWithMultipleAccounts" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TwitterSuccessfulDeviceAuthorization" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TwitterFailedDeviceAuthorization" object:nil];
}


#pragma mark -
#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    if ( !self.tapGesture ) {
        
        self.bShowKeyboard = YES;
        
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if ( textField == self.email ){
        [_password becomeFirstResponder];
    } else if ( textField == _password ){
        [_password resignFirstResponder];
        [self logIn:self.logInButton];
    }
    
    return YES;
}

#pragma mark -
#pragma mark Login
- (IBAction)logIn:(id)sender {
    
    NSString* strEmail = self.email.text;
    NSString* strPassword = self.password.text;
    
    if ( [strEmail isEqualToString:@""]){
        TipsiAlert(@"Error", @"Input email address", @"Ok", nil, nil);
        return;
    }
    
    if ( ![globalInstance validateEmail:strEmail] ){
        TipsiAlert(@"Error", @"Please input a valid email address", @"Ok", nil, nil);
        return;
    }
    
    if ( [strPassword isEqualToString:@""]){
        TipsiAlert(@"Error", @"Input password", @"Ok", nil, nil);
        return;
    }
    
    [self.view endEditing:YES]; // dismiss keyboard
    
    
    
    [self login];
}

- (void) login {
    
   AppDelegate* appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    [self.loadingView setHidden:NO];
    [self.loadingIndicator startAnimating];
    @weakify(self);
    [TipsiAPI  loginWithUsername:self.email.text andPassword:self.password.text andCallback:^(id result, NSError *error) {
        @strongify(self);
        if (error) {
            if (result[@"error_message"]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[result valueForKey:@"error_message"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                alert.tag = 33;
                [alert show];
            }
            TipsiEventError(@"Email Login", [result valueForKey:@"error_message"], error);
            [globalInstance parseError:@"emailLogin/"
                                params:@{@"username": self.email.text?:@"nil", @"password": self.password.text?:@"nil"}
                            returnData:result];
        }
        else {
            [globalInstance saveValue:@"email" forKey:LOGIN_TYPE];
            NSString* strEmailAddress = self.email.text;
            NSUserDefaults* pref = [NSUserDefaults standardUserDefaults];
            [pref setValue:strEmailAddress forKey:@"users_email_address"];
            [pref synchronize];
            TipsiEvent(@"Email Login", result, @"email_login")
            if ([result valueForKey:@"tw_access_token"]) {
                [[NSUserDefaults standardUserDefaults] setObject:[result valueForKey:@"tw_access_token"] forKey:@"tw_access_token"];
            }
            if ([result valueForKey:@"tw_account_identifier"]){
                [[NSUserDefaults standardUserDefaults] setObject:[result valueForKey:@"tw_account_identifier"] forKey:@"tw_account_identifier"];
                [[globalInstance userInfo] setTw_access_token:[result valueForKey:@"tw_access_token"]];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"tw_post"];
            } else {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"tw_post"];
            }
            if ([result valueForKey:@"fb_access_token"] != NULL){
                [[NSUserDefaults standardUserDefaults] setObject:[result valueForKey:@"fb_access_token"] forKey:@"fb_access_token"];
                [[globalInstance userInfo] setFb_access_token:[result valueForKey:@"fb_access_token"]];
                //need to clear the session info
                if (FBSession.activeSession.isOpen) {
                    [FBSession.activeSession closeAndClearTokenInformation];
                }
                if (!FBSession.activeSession.isOpen) {
                    self.fbSession = [[FBSession alloc] initWithPermissions:@[@"email", @"public_profile", @"publish_actions", @"user_friends"]];
                    FBAccessTokenData* tokenData =
                    [FBAccessTokenData createTokenFromString:[result valueForKey:@"fb_access_token"]
                                                 permissions:@[@"email",
                                                               @"public_profile",
                                                               @"publish_actions",
                                                               @"user_friends"]
                                              expirationDate:nil
                                                   loginType:FBSessionLoginTypeWebView
                                                 refreshDate:nil];
                    
                    
                    [self.fbSession openFromAccessTokenData:tokenData completionHandler:^(FBSession *session, FBSessionState status, NSError *errorFb) {
#ifdef DEBUG
                        NSLog(@"sees: %@",session);
                        NSLog(@"status: %lu",(unsigned long)status);
                        NSLog(@"error: %@",errorFb);
#endif
                        [appDelegate sessionStateChanged:session state:status error:errorFb];
                        [FBSession setActiveSession:self.fbSession];
                    }];
                }
            } else {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"fb_post"];
            }
            [[NSUserDefaults standardUserDefaults] setObject:[result valueForKey:@"user_id"] forKey:@"user_id"];
            [[globalInstance userInfo] setUser_id:[result valueForKey:@"user_id"]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [appDelegate checkTwitterSession];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
        [self.loadingIndicator stopAnimating];
        [self.loadingView setHidden:YES];
    }];
}


#pragma mark -
#pragma mark AlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 2){
        switch (buttonIndex) {
            case 1: {
                [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(resetUserPassword) userInfo:nil repeats:NO];
            }
                break;
            case 2: {
                [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(inputCode) userInfo:nil repeats:NO];
            }
                break;
        }
	}
    else if (alertView.tag == 33) {
        [self.password becomeFirstResponder];
    }
}


#pragma mark -
#pragma mark ActionSheet Delegate

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    for (UIView *subview in actionSheet.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            [button setTitleColor:RGBA(62.0f, 0.0f, 42.0f, 0.7f) forState:UIControlStateNormal];
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    AppDelegate* appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (buttonIndex == actionSheet.numberOfButtons-1) {
        [self hideLoadingView];
        return;
    }
    if (buttonIndex < [appDelegate.twitterAccounts count]) {
        [appDelegate reverseOauth:[appDelegate.twitterAccounts objectAtIndex:buttonIndex]];
    }
}

#pragma mark -
#pragma mark Email Login
// ** begin of Email Login methods

- (IBAction)emailLogin:(id)sender {
    [self toggleEmailLoginPanel];
}


- (IBAction)pushGreyView:(id)sender {
    [self toggleEmailLoginPanel];
}


- (void)toggleEmailLoginPanel {
    
    if (self.isEmailLoginPanelActive) {
        @weakify(self);
        [UIView animateWithDuration:0.30
                              delay:0.00
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             @strongify(self);
                             self.emailLoginView.frame = CGRectOffset(self.emailLoginView.frame, 0,
                                                                      -CGRectGetHeight(self.emailLoginView.frame));
                             self.mainText.alpha = 1.0;
                             self.greyView.alpha = 0.0;
                         }
                         completion:^(BOOL finished){
                             
                         }];
        [self.email resignFirstResponder];
        [self.password resignFirstResponder];
        
        self.isEmailLoginPanelActive = NO;
        
    }
    else {
        
        self.isEmailLoginPanelActive = YES;
        
        [UIView beginAnimations:@"animateTextOn" context:NULL];
        self.mainText.alpha = 0.0;
        self.greyView.alpha = 1.0;
        [UIView commitAnimations];
        
        [UIView animateWithDuration:0.30
                              delay:0.00
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.emailLoginView.frame = CGRectOffset(self.emailLoginView.frame, 0,
                                                                      CGRectGetHeight(self.emailLoginView.frame));
                         }
                         completion:nil];
        [self.email becomeFirstResponder];
    }
}


- (void)inputCode {
    NSString* strEmailAddress = self.email.text;
    if (![self.email.text isEqualToString:@""]) {
        // not empty
        if ( ![globalInstance validateEmail:strEmailAddress] ){
            TipsiAlert(@"Error", @"Please input a valid email address", @"Ok", nil, nil);
        }
        else {
            [self confirmPassword:strEmailAddress:@"Use the code that we sent to your email address."];
        }
    }
    else {
        //empty
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Input your email and then try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}


- (void) resetUserPassword{
    NSString* strEmailAddress = self.email.text;
    if (![self.email.text isEqualToString:@""]) {
        // not empty
        if ( ![globalInstance validateEmail:strEmailAddress] ){
            TipsiAlert(@"Error", @"Please input a valid email address", @"Ok", nil, nil);
        }
        else {
            [self.loadingView setHidden:NO];
            [self.loadingIndicator startAnimating];
            @weakify(self);
            [TipsiAPI  requestResetPasswordWithEmail:strEmailAddress andCallback:^(id result, NSError *error) {
                @strongify(self);
                if (!error) {
                    [self confirmPassword:strEmailAddress:@"Email sent. Please check your email for the code and use it below.\n(Please check spam folder for email)"];
                }
                else {
                    [globalInstance parseError:@"/password/request/code/"
                                        params:@{@"email" : strEmailAddress?:@"nil"}
                                    returnData:result];
                }
                [self.loadingIndicator stopAnimating];
                [self.loadingView setHidden:YES];
            }];
        }
    }
    else {
        //empty
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Input your email and then try again."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction) resetPassword:(id)sender {
    
    NSString* strEmailAddress = self.email.text;
    
    if (![strEmailAddress isEqualToString:@""]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reset Password" message:@"We need to verify your identity first. We will send a Confirmation Code to the email address you entered." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send Me A Code Via Email",@"Enter A Code", nil];
        alert.tag = 2;
        [alert show];
        
    } else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Input your email and try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    
    
}

- (void) confirmPassword:(NSString*)email :(NSString*)message {
    CustomAlertView* alert = [[CustomAlertView alloc] init];
    UIView* vwSub = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 206)];
    
    UILabel* lbCaption = [[UILabel alloc] initWithFrame:CGRectMake(15, 4, 240, 40)];
    lbCaption.text = @"Confirmation Code";
    lbCaption.font = [UIFont boldSystemFontOfSize:16];
    lbCaption.textAlignment = NSTextAlignmentCenter;
    [vwSub addSubview:lbCaption];

    UILabel* lbMessage = [[UILabel alloc] initWithFrame:CGRectMake(15, 36, 240, 40)];
    lbMessage.text = message;
    lbMessage.font = [UIFont systemFontOfSize:14];
    lbMessage.numberOfLines = 2;
    lbMessage.textAlignment = NSTextAlignmentCenter;
    [vwSub addSubview:lbMessage];
    
    UITextField* codeField = [[UITextField alloc] initWithFrame:CGRectMake(15, 82, 240, 36)];
    codeField.placeholder = @"Confirmation Code";
    codeField.font = [UIFont systemFontOfSize:16];
    codeField.borderStyle = UITextBorderStyleRoundedRect;
    codeField.keyboardType = UIKeyboardTypeNumberPad;
    codeField.autocorrectionType = UITextAutocorrectionTypeNo;
    [vwSub addSubview:codeField];
    
    UITextField* pwdField0 = [[UITextField alloc] initWithFrame:CGRectMake(15, 122, 240, 36)];
    pwdField0.placeholder = @"New Password";
    pwdField0.font = [UIFont systemFontOfSize:16];
    pwdField0.borderStyle = UITextBorderStyleRoundedRect;
    pwdField0.keyboardType = UIKeyboardTypeDefault;
    pwdField0.autocorrectionType = UITextAutocorrectionTypeNo;
    pwdField0.secureTextEntry = YES;
    [vwSub addSubview:pwdField0];
    
    UITextField* pwdField1 = [[UITextField alloc] initWithFrame:CGRectMake(15, 162, 240, 36)];
    pwdField1.placeholder = @"Confirm New Password";
    pwdField1.font = [UIFont systemFontOfSize:16];
    pwdField1.borderStyle = UITextBorderStyleRoundedRect;
    pwdField1.keyboardType = UIKeyboardTypeDefault;
    pwdField1.autocorrectionType = UITextAutocorrectionTypeNo;
    pwdField1.secureTextEntry = YES;
    [vwSub addSubview:pwdField1];
    
    [alert setContainerView:vwSub];
    [alert setButtonTitles:@[@"Confirm", @"Cancel"]];
    
    [alert setOnButtonTouchUpInside:^(CustomAlertView *alertView, int buttonIndex) {
        [alertView close];
        
        if ( buttonIndex == 0 ) {
            [self.loadingView setHidden:NO];
            [self.loadingIndicator startAnimating];
            @weakify(self);
            [TipsiAPI  resetPasswordWithEmail:email
                                    password:pwdField0.text
                                     confirm:pwdField1.text
                                        code:codeField.text
                                 andCallback:^(id result, NSError *error) {
                                     @strongify(self);
                                     [self.loadingIndicator stopAnimating];
                                     self.loadingView.hidden = YES;
                                     if ( !error ) {
                                         self.email.text = email;
                                         self.password.text = pwdField0.text;
                                         [self login];
                                     } else {
                                         [self.loadingIndicator stopAnimating];
                                         self.loadingView.hidden = YES;
                                         [globalInstance parseError:@"/password/request/code/"
                                                             params:@{@"email" : email?:@"nil",
                                                                      @"password" : pwdField0.text?:@"nil",
                                                                      @"confirm" : pwdField1.text?:@"nil",
                                                                      @"code" : codeField.text?:@"nil"}
                                                         returnData:result];
                                     }
                                 }];
        }
    }];
    [alert show:self.bShowKeyboard];
}

// ** end of Email Login methods





- (IBAction)cancelPressed:(id)sender {
    if (self.isReportingError)
       [self dismissViewControllerAnimated:YES completion:nil];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Loading View
- (IBAction)closeLoadingView:(id)sender{
    
    [self hideLoadingView];
}

- (void)showLoadingView{

    if (self.isLoadingViewActive == NO){
        
        self.isLoadingViewActive = YES;
        [self.loadingView setHidden:NO];
        [self.closeButtonInLoadView setHidden:YES];
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(showCloseButton) userInfo:nil repeats:NO];
    }
}

- (void)hideLoadingView{
    
    self.isLoadingViewActive = NO;
    [self.loadingView setHidden:YES];
    [self.closeButtonInLoadView setHidden:YES];
}

- (void)showCloseButton{
    
    [self.closeButtonInLoadView setHidden:NO];
    
}

#pragma mark -
#pragma mark Facebook

- (IBAction)facebookLogin:(id)sender {
 
    if (self.isEmailLoginPanelActive) {
        [self toggleEmailLoginPanel];
        [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(openFacebookSession) userInfo:nil repeats:NO];
    } else {
        [self openFacebookSession];
    }
    
}

- (void)openFacebookSession {
    [self showLoadingView];
    AppDelegate* appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate openFacebookSession];
}


#pragma mark -
#pragma mark Twitter

- (IBAction)twitterLogin:(id)sender {
    
    if (self.isEmailLoginPanelActive) {
        [self toggleEmailLoginPanel];
        [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(openTwitterSession) userInfo:nil repeats:NO];
    } else {
        [self openTwitterSession];
    }
    
}

- (void)openTwitterSession {
    [self showLoadingView];
    AppDelegate* appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    // checking for Twitter device authorization
    [appDelegate openTwitterSession];
}


-(void)showTwitterSheet{
    
    AppDelegate* appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    UIActionSheet *twitterSheet = [[UIActionSheet alloc]
                                    initWithTitle:@"Select a Twitter account"
                                    delegate:self
                                    cancelButtonTitle:nil
                                    destructiveButtonTitle:nil
                                    otherButtonTitles:nil];
    
    
    int i;
    for (i = 0; i < [appDelegate.twitterAccounts count]; i++) {
        
        ACAccount *twitterAccount = [appDelegate.twitterAccounts objectAtIndex:i];
        
        [twitterSheet addButtonWithTitle:[NSString stringWithFormat:@"%@",[twitterAccount valueForKey:@"accountDescription"]]];
    }
    
    [twitterSheet addButtonWithTitle:@"Cancel"];
    
    
    [twitterSheet showInView:self.view];
    
}


#pragma mark -
#pragma mark Social Login Methods


- (void) performTwitterLogin{
    AppDelegate* appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSString* twitterToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"tw_access_token"];
    NSString* twitterTokenSecret = [[NSUserDefaults standardUserDefaults] objectForKey:@"tw_access_token_secret"];
    NSString* twitterUserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"tw_uid"];
    NSString* accountIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:@"tw_account_identifier"];
    
    if (twitterToken != NULL && twitterTokenSecret != NULL && twitterUserId != NULL){
        @weakify(self);
        [TipsiAPI  loginTwitterWithToken:twitterToken tokenSecret:twitterTokenSecret andUserId:twitterUserId accountIdentifier:accountIdentifier andCallback:^(id result, NSError *error) {
            @strongify(self);
            if (!error) {
                [globalInstance saveValue:@"twitter" forKey:LOGIN_TYPE];
                TipsiLog(@"Result of tw login: %@", result);
                TipsiEvent(@"Hooking up Twitter", result, @"twitter_login");
                if ( [[result allKeys] containsObject:@"fb_access_token"] ){
                    [[NSUserDefaults standardUserDefaults] setObject:[result valueForKey:@"fb_access_token"] forKey:@"fb_access_token"];
                    if (!FBSession.activeSession.isOpen) {
                        [appDelegate openFacebookSession];
                    }
                }
                [[NSUserDefaults standardUserDefaults] setObject:[result valueForKey:@"user_id"] forKey:@"user_id"];
                [[globalInstance userInfo] setUser_id:[result valueForKey:@"user_id"]];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self hideLoadingView];
                [appDelegate checkTwitterSession];
                if (self.isReportingError) {
                    [self dismissViewControllerAnimated:YES completion:nil];
                } else {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            } else {
                [self hideLoadingView];
                //error handling
                if ([[result valueForKey:@"error_message"] isEqualToString:@"User not authenticated"]) {
                    TipsiAlert(@"Error", @"User not authenticated. This Twitter user does not have a Tipsi account.", @"OK", nil, nil);
                } else {
                    TipsiAlert(@"Error", @"Failed to authenticate user", @"OK", nil, nil);
                }
                TipsiEventError(@"Hooking up Twitter", [result valueForKey:@"error_message"], error);
                [globalInstance parseError:@"twitterLogin/"
                                    params:@{@"twitterToken" : twitterToken?:@"nil",
                                             @"twitterTokenSecret" : twitterTokenSecret?:@"nil",
                                             @"twitterUserId" : twitterUserId?:@"nil",
                                             @"accountIdentifier" : accountIdentifier?:@"nil"}
                                returnData:result];
            }
        }];
    } else {
        [self hideLoadingView];
        TipsiAlert(@"Error", @"Something went wrong with Twitter Authentication and the Tipsi Server", @"OK", nil, nil);
    }
}


- (void) performFacebookLogin{
    //NSString *fb_username = [[NSUserDefaults standardUserDefaults] objectForKey:@"fb_username"]; //unused
    NSString *fb_access_token = [[NSUserDefaults standardUserDefaults] objectForKey:@"fb_access_token"];
    NSString *fb_expires = [[NSUserDefaults standardUserDefaults] objectForKey:@"fb_expires"];
    //BOOL *fb_post = [[NSUserDefaults standardUserDefaults] boolForKey:@"fb_post"]; //unused
    NSString *fb_uid = [[NSUserDefaults standardUserDefaults] objectForKey:@"fb_uid"];
    
    if (fb_access_token != NULL && fb_expires != NULL && fb_uid != NULL){
        @weakify(self);
        [TipsiAPI  loginFacebookWithToken:fb_access_token expirationDate:fb_expires andUserId:fb_uid  toServerWithCallback:^(id result, NSError *error){
            @strongify(self);
            if (!error){
                [globalInstance saveValue:@"facebook" forKey:LOGIN_TYPE];
                TipsiLog(@"Result of fb login: %@", result);
                TipsiEvent(@"Hooking up Facebook", result, @"facebook_login");
                if ( [[result allKeys] containsObject:@"tw_access_token"] ){
                    [[NSUserDefaults standardUserDefaults] setObject:[result valueForKey:@"tw_access_token"] forKey:@"tw_access_token"];
                }
                if ( [[result allKeys] containsObject:@"tw_account_identifier"] ){
                    [[NSUserDefaults standardUserDefaults] setObject:[result valueForKey:@"tw_account_identifier"] forKey:@"tw_account_identifier"];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"tw_post"];
                }
                [[NSUserDefaults standardUserDefaults] setObject:result[@"user_id"] forKey:@"user_id"];
                [[globalInstance userInfo] setUser_id:result[@"user_id"]];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"fb_post"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self hideLoadingView];
                AppDelegate* appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                [appDelegate checkTwitterSession];
                if (self.isReportingError) {
                    [self dismissViewControllerAnimated:YES completion:nil];
                } else {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            } else {
                [self hideLoadingView];
                //error handling
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"fb_post"];
                if ([[result valueForKey:@"error_message"] isEqualToString:@"Failed to authenticate user"]) {
                    TipsiAlert(@"Error", @"User not authenticated. This Facebook user does not have a Tipsi account.", @"OK", nil, nil);
                } else {
                    TipsiAlert(@"Error", @"Failed to authenticate user", @"OK", nil, nil);
                }
                TipsiEventError(@"Hooking up Facebook", [result valueForKey:@"error_message"], error);
                [globalInstance parseError:@"facebookLogin/"
                                    params:@{@"access_token" : fb_access_token?:@"nil",
                                             @"expires" : fb_expires?:@"nil",
                                             @"uid" : fb_uid?:@"nil"}
                                returnData:result];
            }
        }];
    } else {
        [self hideLoadingView];
        TipsiAlert(@"Error", @"Something went wrong with Facebook Authentication and the Tipsi Server", @"OK", nil, nil);
    }
}

#pragma mark -
#pragma mark Notification Methods
- (void)facebookSuccessfulDeviceAuthorization{
    
    [self performSelectorOnMainThread:@selector(performFacebookLogin) withObject:nil waitUntilDone:NO];
}

- (void)facebookFailedDeviceAuthorization{
    
    [self performSelectorOnMainThread:@selector(hideLoadingView) withObject:nil waitUntilDone:NO];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook Error" message:@"Unfortunatley Facebook can not authenticate you." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)twitterSuccessfulDeviceAuthorization{
    
    
    //NSLog(@"twitterSuccessfulDeviceAuthorization");
    [self performSelectorOnMainThread:@selector(performTwitterLogin) withObject:nil waitUntilDone:NO];
    
}

- (void)twitterFailedDeviceAuthorization{
    
    [self performSelectorOnMainThread:@selector(hideLoadingView) withObject:nil waitUntilDone:NO];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Twitter Error" message:@"Unfortunatley Twitter can not authenticate you." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)twitterSuccessfulDeviceAuthorizationWithMultipleAccounts{
    
    //NSLog(@"twitterSuccessfulDeviceAuthorizationWithMultipleAccounts");
    
    //AppDelegate* appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate; //unused
    //NSLog(@"twitterAccounts: %@",appDelegate.twitterAccounts);
    
    [self performSelectorOnMainThread:@selector(showTwitterSheet) withObject:nil waitUntilDone:NO];
    
    // after item in Actionsheet is chosen, reverseOauth is made, and then twitterSuccessfulDeviceAuthorization called via Notification
    
}

#pragma mark -
#pragma mark ShadeView

- (void)stopShadeView{
    
    //[self.loadingView setHidden:YES];
    
    //[self.loadingIndicator stopAnimating];
    
}




#pragma mark -
#pragma mark Segue
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
   /* if ([segue.identifier isEqualToString:@"loginTwitterAccountList"]) {
        [segue.destinationViewController setLoginView:self];
        [segue.destinationViewController setTwitterAccounts:self.twitterAccounts];
    }*/
}

- (void) performTransitionToAccountsList{
    /*
    [self.loadingView setHidden:YES];
    [self.loadingIndicator stopAnimating];
    [self performSegueWithIdentifier:@"loginTwitterAccountList" sender:nil];
     */
}


@end
