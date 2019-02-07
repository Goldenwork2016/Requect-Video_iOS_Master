//
//  ConfirmViewController.m
//  Request Video
//
//  Created by NTechnosoft on 24/07/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import "ConfirmViewController.h"

@interface ConfirmViewController ()<UITextFieldDelegate>
@property(nonatomic, strong)IBOutlet UILabel *phone;
@property(nonatomic, strong)IBOutlet UITextField *code;
@end

@implementation ConfirmViewController

@synthesize phone_number = _phone_number, user = _user;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.phone.text = self.phone_number;
    NSLog(@"User :: %@",self.user);
    self.code.text = [self.user objectForKey:@"password"];
    //[self sendSMS];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)Back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)Done:(id)sender{
    if([self.code.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length != 4){
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Required" message:@"Enter 4 digits verification code" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        
    }else{
        [self Verify];
    }
}

#pragma mark - UITextField

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    NSCharacterSet *nonNumberSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    
    if ([string rangeOfCharacterFromSet:nonNumberSet].location != NSNotFound)
    {
        return NO;
    }
    
    NSString *resultText = [textField.text stringByReplacingCharactersInRange:range
                                                                   withString:string];
    return resultText.length <= 4;
}

#pragma mark - Webservice

- (void)sendSMS{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    NSString *Authorization = [[[NSString stringWithFormat:@"%@:%@",ACOOUNT_SID,AUTH_TOKEN] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Basic %@",Authorization] forHTTPHeaderField:@"Authorization"];
    [manager POST:SEND_SMS parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFormData:[self.phone_number dataUsingEncoding:NSUTF8StringEncoding] name:@"To"];
        [formData appendPartWithFormData:[FROM_PHONE dataUsingEncoding:NSUTF8StringEncoding] name:@"From"];
        [formData appendPartWithFormData:[[NSString stringWithFormat:@"Your verification code is %@",[self.user objectForKey:@"password"]] dataUsingEncoding:NSUTF8StringEncoding] name:@"Body"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //NSLog(@"Response :: %@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //NSLog(@"Response :: %@",error.userInfo);
    }];
}

- (void)Verify{
    [ProgressHUD show:@"Verifying"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager.requestSerializer setValue:[self.user objectForKey:@"Authentication"] forHTTPHeaderField:@"Authentication"];
    [manager POST:VERIFICATION parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFormData:[self.code.text dataUsingEncoding:NSUTF8StringEncoding] name:@"varification_no"];
        [formData appendPartWithFormData:[@"1234567890" dataUsingEncoding:NSUTF8StringEncoding] name:@"device_token"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@",responseObject);
        NSInteger status = [[responseObject objectForKey:@"status"] integerValue];
        if(status == 1){
            [[NSUserDefaults standardUserDefaults] setObject:self.user forKey:@"user"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [ProgressHUD dismiss];
            [self performSegueWithIdentifier:@"Main" sender:self];
        }else{
            [ProgressHUD showError:[responseObject objectForKey:@"message"]];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [ProgressHUD showError:error.localizedFailureReason];
    }];
}

@end
