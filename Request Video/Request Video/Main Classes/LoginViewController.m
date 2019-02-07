//
//  LoginViewController.m
//  Request Video
//
//  Created by NTechnosoft on 24/07/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import "LoginViewController.h"
#import "CountriesViewController.h"
#import "ConfirmViewController.h"

@interface LoginViewController ()<UITextFieldDelegate,CountriesDelegate>{
    
}
@property(nonatomic, strong)IBOutlet UITextField *phone;
@property(nonatomic, strong)IBOutlet UIButton *countryBTN;
@property(nonatomic, strong)IBOutlet UILabel *countryCode;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.phone becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"Confirm"]){
        ConfirmViewController *confirm = [segue destinationViewController];
        confirm.user = (NSDictionary *)sender;
        confirm.phone_number = [NSString stringWithFormat:@"%@%@",self.countryCode.text,self.phone.text];
    }
}

- (IBAction)Back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)LogIn:(id)sender{
    
    if([self.phone.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length != 10){
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Required" message:@"Enter 10 digits phone number" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }]];
        [self presentViewController:alert animated:YES completion:nil];

    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Number Confirmation\n%@%@",self.countryCode.text,self.phone.text] message:@"is your phone number above correct?" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Edit" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self Login];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }

}

- (IBAction)ChooseCountry:(id)sender{
    CountriesViewController *CountryPicker = [self.storyboard instantiateViewControllerWithIdentifier:@"Countries"];
    CountryPicker.Delegate = self;
    [self presentViewController:CountryPicker animated:YES completion:nil];
}

#pragma mark - Webservice

- (void)Login{
    [ProgressHUD show:@"Loging In"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager POST:LOGIN parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFormData:[[NSString stringWithFormat:@"%@%@",self.countryCode.text,self.phone.text] dataUsingEncoding:NSUTF8StringEncoding] name:@"phone"];
        [formData appendPartWithFormData:[@"1234567890" dataUsingEncoding:NSUTF8StringEncoding] name:@"device_token"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@",responseObject);
        if([[responseObject objectForKey:@"status"] integerValue] == 1){
            [ProgressHUD dismiss];
            [self performSegueWithIdentifier:@"Confirm" sender:[[responseObject objectForKey:@"Get_data"] objectAtIndex:0]];
        }else{
            [ProgressHUD showError:[responseObject objectForKey:@"message"]];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [ProgressHUD showError:error.localizedFailureReason];
    }];
}

#pragma mark - UITextField

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    NSCharacterSet *nonNumberSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    
    if ([string rangeOfCharacterFromSet:nonNumberSet].location != NSNotFound)
    {
        return NO;
    }
    
    NSString *resultText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    return resultText.length <= 10;
}

#pragma mark - Countries

- (void)CountriesViewControllerDismissed:(NSDictionary *)country{
    if(country != nil){
        [self.countryBTN setTitle:[country objectForKey:@"name"] forState:UIControlStateNormal];
        self.countryCode.text = [NSString stringWithFormat:@"+%ld",(long)[[country objectForKey:@"dial_code"] integerValue]];
    }
}

@end
