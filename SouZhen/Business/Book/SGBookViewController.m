//
//  SGBookViewController.m
//  SouZhen
//
//  Created by chenwang on 13-8-17.
//  Copyright (c) 2013年 songguo. All rights reserved.
//

#import "SGBookViewController.h"
#import "SGOrderViewController.h"
#import "SGAppDelegate.h"
#import "SGDisclaimerViewController.h"

@interface SGBookViewController () <UITextFieldDelegate, ASIHTTPRequestDelegate>

@property (weak, atomic) IBOutlet UIImageView *bgTitleImageView;
@property (weak, atomic) IBOutlet UIImageView *bgTitleTopImageView;
@property (weak, nonatomic) IBOutlet UITextField *dateTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;

@property (strong, nonatomic) IBOutlet UIView *datePickerView;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *discountLabel;


- (IBAction)doneDatePickerAction:(id)sender;

@end

@implementation SGBookViewController
{
    UIActionSheet *_datePickerActionSheet;
    NSDate *_bookDate;
    
    ASIHTTPRequest *_getBookingInfoRequest;
    ASIHTTPRequest *_createOrderRequest;
    
    UIButton *doneButton;
}

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)registerKeywordNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keywordWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keywordWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keywordDidShow:) name:UIKeyboardDidShowNotification object:nil];
}

- (void)removeKeywordNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

- (void)keywordWillShow:(NSNotification *)no
{
    NSDictionary *userInfo = [no userInfo];
	CGRect keyboardFrame;
	[[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
	UIViewAnimationCurve curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
	NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:curve];
	[UIView setAnimationDuration:duration];
	self.view.transform = CGAffineTransformMakeTranslation(0, -100);
	[UIView commitAnimations];
}

- (void)keywordDidShow:(NSNotification *)no
{
    if ([self.phoneTextField isFirstResponder]) {
        [self addDoneButton];
    }
}

- (void)keywordWillHide:(NSNotification *)no
{
    
    NSDictionary *userInfo = [no userInfo];
	CGRect keyboardFrame;
	[[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
	UIViewAnimationCurve curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
	NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:curve];
	[UIView setAnimationDuration:duration];
	self.view.transform = CGAffineTransformIdentity;
	[UIView commitAnimations];
}

- (void)doneButton:(id)sender
{
    [self.phoneTextField resignFirstResponder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"订票";
    
    doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    doneButton.frame = CGRectMake(0, 163, 106, 53);
    doneButton.adjustsImageWhenHighlighted = NO;
    [doneButton setImage:[UIImage imageNamed:@"DoneUp.png"] forState:UIControlStateNormal];
    [doneButton setImage:[UIImage imageNamed:@"DoneDown.png"] forState:UIControlStateHighlighted];
    [doneButton addTarget:self action:@selector(doneButton:) forControlEvents:UIControlEventTouchUpInside];

    
    self.bgTitleImageView.image = [[UIImage imageNamed:@"bar_b"] stretchableImageWithLeftCapWidth:20 topCapHeight:20];
    self.bgTitleTopImageView.image = [[UIImage imageNamed:@"bg_title"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
    self.dateTextField.background = [[UIImage imageNamed:@"input-box"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
    self.nameTextField.background = [[UIImage imageNamed:@"input-box"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
    self.phoneTextField.background = [[UIImage imageNamed:@"input-box"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
    
    self.dateTextField.delegate = self;
    self.nameTextField.delegate = self;
    self.phoneTextField.delegate = self;
    
    self.datePicker.minimumDate = [[NSDate date] dateByAddingTimeInterval:24*3600];
    
    UIImage *orderImage = [UIImage imageNamed:@"button_xiadan.png"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 50, 32);
    [button setBackgroundImage:orderImage forState:UIControlStateNormal];
    [button setTitle:@"下单" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    button.titleLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f];
    button.titleLabel.shadowOffset = CGSizeMake(0, 1);
    [button addTarget:self action:@selector(orderAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction)]];
    

    [self requestBookInfo];
}

- (void)requestBookInfo
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.xitang.com.cn/dingpiao/Api.ashx?apikey=v1.00000001&method=getprice"]];
    request.delegate = self;
    _getBookingInfoRequest = request;
    [request startAsynchronous];
}

- (void)requestStarted:(ASIHTTPRequest *)request
{
    if (request == _getBookingInfoRequest) {
        [self showLoading:YES];
    } else if (request == _createOrderRequest) {
        [self showWaiting:@"正在加载..."];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    dlog(@"url: %@", request.url);
    NSDictionary *dict = [request.responseString JSONValue];
    NSInteger errorCode = [[dict objectForKey:@"errorcode"] integerValue];
    if (errorCode < 0) {
        NSString *errMsg = [dict objectForKey:@"errormsg"];
        [self showAlert:errMsg];
        if (request == _getBookingInfoRequest) {
            [self showLoading:NO];
            [self showErroView:YES];
        } else {
            [self hideWaiting];
        }
        return;
    }

    if (request == _getBookingInfoRequest) {
        [self showLoading:NO];
        [self showErroView:NO];
        self.navigationItem.rightBarButtonItem.enabled = YES;
        NSNumber *_price = [dict objectForKey:@"price"];
        NSNumber *_discount = [dict objectForKey:@"discount"];
        if (_price) {
            self.priceLabel.text = [NSString stringWithFormat:@"%g", [_price doubleValue]];
        }
        if (_discount) {
            self.discountLabel.text = [NSString stringWithFormat:@"%g", [_discount doubleValue]];
        }
    } else if (request == _createOrderRequest) {
        [self hideWaiting];
        NSString *orderId = [dict objectForKey:@"orderid"];
        if (orderId.length == 0) {
            [self showAlert:@"创建订单失败"];
            return;
        }
        SGOrderViewController *viewController = [[SGOrderViewController alloc] init];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyyMMdd";
        viewController.date = [dateFormatter stringFromDate:_bookDate];
        viewController.name = self.nameTextField.text;
        viewController.phone = self.phoneTextField.text;
        viewController.price = [self.priceLabel.text doubleValue];
        viewController.discount = [self.discountLabel.text doubleValue];
        viewController.orderId = orderId;
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    dlog(@"url: %@", request.url);
    if (request.responseString.length > 0) {
        NSDictionary *dict = [request.responseString JSONValue];
        NSInteger errorCode = [[dict objectForKey:@"errorcode"] integerValue];
        if (errorCode < 0) {
            if (errorCode == -2) {
                [self showAlert:@"请输入合法11位手机号码"];
            } else {
                NSString *errMsg = [dict objectForKey:@"errormsg"];
                [self showAlert:errMsg];
            }
        }
    } else {
        [self showAlert:@"网络异常，请确认已打开无线局域网或蜂窝移动数据设置"];
    }

    if (request == _getBookingInfoRequest) {
        [self showLoading:NO];
        [self showErroView:YES];
    } else if (request == _createOrderRequest) {
        [self hideWaiting];
    }
}

- (void)retryAction
{
    [self requestBookInfo];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self removeKeywordNotification];
    [self registerKeywordNotification];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeKeywordNotification];
}

- (void)orderAction
{
    if (_bookDate == nil) {
        [self showAlert:@"您还未选择预订日期"];
        return;
    }
    NSString *name = [self.nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (name.length == 0) {
        [self showAlert:@"您还未输入取票人姓名"];
        return;
    }
    NSString *phone = self.phoneTextField.text;
    if (phone.length != 11) {
        if (phone.length == 0) {
            [self showAlert:@"您还未输入手机号码"];
        } else {
            [self showAlert:@"请输入合法11位手机号码"];
        }
        return;
    } else if (!([phone hasPrefix:@"13"] || [phone hasPrefix:@"14"] || [phone hasPrefix:@"15"] || [phone hasPrefix:@"18"])) {
        [self showAlert:@"请输入合法11位手机号码"];
        return;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd";
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    _createOrderRequest = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.xitang.com.cn/dingpiao/Api.ashx?apikey=v1.00000001&method=createorder&date=%@&name=%@&phone=%@", [dateFormatter stringFromDate:_bookDate], [name stringByAddingPercentEscapesUsingEncoding:enc], phone]]];
    _createOrderRequest.delegate = self;
    [_createOrderRequest startAsynchronous];
}

- (void)tapGestureAction
{
    [self.dateTextField resignFirstResponder];
    [self.nameTextField resignFirstResponder];
    [self.phoneTextField resignFirstResponder];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == self.dateTextField) {
        _datePickerActionSheet = [[UIActionSheet alloc] initWithTitle:@"\n\n\n\n\n\n\n\n\n\n\n\n\n" delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [_datePickerActionSheet insertSubview:self.datePickerView atIndex:0];
        [_datePickerActionSheet showInView:[self view]];
        
        self.datePickerView.frame = _datePickerActionSheet.bounds;
        return NO;
    }
    return YES;
}

- (void)addDoneButton
{
    if ([[[UIApplication sharedApplication] windows] count] < 2) {
        return;
    }
    UIWindow* tempWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:1];
    UIView* keyboard;
    for(int i=0; i<[tempWindow.subviews count]; i++) {
        keyboard = [tempWindow.subviews objectAtIndex:i];
        // keyboard view found; add the custom button to it
        if(([[keyboard description] hasPrefix:@"<UIPeripheralHostView"] == YES) ||(([[keyboard description] hasPrefix:@"<UIKeyboard"] == YES)))
            [keyboard addSubview:doneButton];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.phoneTextField == textField) {
        // locate keyboard view
        [self addDoneButton];
    } else {
        [doneButton removeFromSuperview];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.nameTextField) {
        [self.phoneTextField becomeFirstResponder];
    } else {
        [self tapGestureAction];
    }
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setDateTextField:nil];
    [self setNameTextField:nil];
    [self setPhoneTextField:nil];
    [self setDatePicker:nil];
    [super viewDidUnload];
}

- (IBAction)doneDatePickerAction:(id)sender {
    NSDate *date = self.datePicker.date;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy年MM月dd日"];
    self.dateTextField.text = [formatter stringFromDate:date];
    _bookDate = date;
    [_datePickerActionSheet dismissWithClickedButtonIndex:[_datePickerActionSheet cancelButtonIndex] animated:YES];
}

- (IBAction)cancelDatePickerAction:(id)sender {
    [_datePickerActionSheet dismissWithClickedButtonIndex:[_datePickerActionSheet cancelButtonIndex] animated:YES];
}

- (IBAction)todayAction:(id)sender {
    self.datePicker.date = [NSDate date];
}

- (IBAction)disclaimerClicked:(id)sender {
    SGDisclaimerViewController *viewController = [[SGDisclaimerViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}



@end
