//
//  ProfileViewController.m
//  Request Video
//
//  Created by NTechnosoft on 24/07/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import "ProfileViewController.h"

@interface ProfileViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic,weak) IBOutlet UIButton *profile_pic, *name, *phone;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"User :: %@",[AppDelegate shared].user);
    
    [self.phone setTitle:[[AppDelegate shared].user objectForKey:@"phone"] forState:UIControlStateNormal];
    
    [self.name setTitle:([[[AppDelegate shared].user objectForKey:@"name"] isEqualToString:@""] ? @"N/A" : [[AppDelegate shared].user objectForKey:@"name"]) forState:UIControlStateNormal];
    if(![[[AppDelegate shared].user objectForKey:@"profile_pic"] isEqualToString:@""]){
        [self.profile_pic sd_setImageWithURL:[NSURL URLWithString:[PROFILE_PIC_PATH stringByAppendingString:[[AppDelegate shared].user objectForKey:@"profile_pic"]]] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"no_profile_pic.png"] options:SDWebImageHighPriority];
    }
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

- (IBAction)ChangeProfilePic:(id)sender{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSelector:@selector(ShowImagePicker:) withObject:[NSNumber numberWithInteger:UIImagePickerControllerSourceTypeCamera] afterDelay:0.6];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Photo Gallery" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSelector:@selector(ShowImagePicker:) withObject:[NSNumber numberWithInteger:UIImagePickerControllerSourceTypePhotoLibrary] afterDelay:0.6];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)ChangeName:(id)sender{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Name" message:nil preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Enter name";
        textField.text = [self.name titleForState:UIControlStateNormal];
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"Change" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self EditProfile:alert.textFields[0].text];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)Logout:(id)sender{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Logout" message:@"Are you sure you want to logout?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self LogoutFromApp];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIImagePicker

- (void)ShowImagePicker:(NSNumber *)source{
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = sourceType;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:^{
        [self UpdateProfilePic:[self imageWithImage:info[UIImagePickerControllerOriginalImage] scaledToHeight:250.0]];
    }];
}

- (UIImage *)fixrotation:(UIImage *)image{
    
    
    if (image.imageOrientation == UIImageOrientationUp) return image;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
    
}

-(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToHeight: (float) i_height
{
    sourceImage = [self fixrotation:sourceImage];
    float oldHeight = sourceImage.size.height;
    float scaleFactor = i_height / oldHeight;
    
    float newWidth = sourceImage.size.width* scaleFactor;
    float newHeight = oldHeight * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark  - Webservice

- (void)UpdateProfilePic:(UIImage *)image{

    [ProgressHUD show:@"Loading"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager.requestSerializer setValue:[[AppDelegate shared].user objectForKey:@"Authentication"] forHTTPHeaderField:@"Authentication"];
    [manager POST:UPDATE_PROFILE_PIC parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:UIImageJPEGRepresentation(image, 1.0) name:@"profile_pic" fileName:@"pic.jpg" mimeType:@"image/jpeg"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if([[responseObject objectForKey:@"status"] integerValue] == 1){
            NSLog(@"%@",responseObject);
            [ProgressHUD dismiss];
            NSDictionary *d = [[responseObject objectForKey:@"Get_data"] objectAtIndex:0];
            [[AppDelegate shared].user setObject:[d objectForKey:@"profile_pic"] forKey:@"profile_pic"];
            [[NSUserDefaults standardUserDefaults] setObject:[AppDelegate shared].user forKey:@"user"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self.profile_pic setImage:image forState:UIControlStateNormal];
            
            [[SDWebImageManager sharedManager] saveImageToCache:image forURL:[NSURL URLWithString:[PROFILE_PIC_PATH stringByAppendingPathComponent:[d objectForKey:@"profile_pic"]]]];
            
        }else{
            [ProgressHUD showError:[responseObject objectForKey:@"message"]];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [ProgressHUD showError:error.localizedFailureReason];
    }];
}

- (void)EditProfile:(NSString *)name{
    [ProgressHUD show:@"Loading"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager.requestSerializer setValue:[[AppDelegate shared].user objectForKey:@"Authentication"] forHTTPHeaderField:@"Authentication"];
    [manager POST:EDIT_PROFILE parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {

        [formData appendPartWithFormData:[name dataUsingEncoding:NSUTF8StringEncoding] name:@"name"];
        [formData appendPartWithFormData:[[self.phone titleForState:UIControlStateNormal] dataUsingEncoding:NSUTF8StringEncoding] name:@"phone"];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if([[responseObject objectForKey:@"status"] integerValue] == 1){
            NSLog(@"%@",responseObject);
            [ProgressHUD dismiss];
            [self.name setTitle:name forState:UIControlStateNormal];
            NSDictionary *d = [[responseObject objectForKey:@"Get_data"] objectAtIndex:0];
            [[AppDelegate shared].user setObject:[d objectForKey:@"name"] forKey:@"name"];
            [[NSUserDefaults standardUserDefaults] setObject:[AppDelegate shared].user forKey:@"user"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        }else{
            [ProgressHUD showError:[responseObject objectForKey:@"message"]];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [ProgressHUD showError:error.localizedFailureReason];
    }];
}

- (void)LogoutFromApp{
    [ProgressHUD show:@"Logging Out" Interaction:NO];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager.requestSerializer setValue:[[AppDelegate shared].user objectForKey:@"Authentication"] forHTTPHeaderField:@"Authentication"];
    [manager POST:LOGOUT parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if([[responseObject objectForKey:@"status"] integerValue] == 1){
            NSLog(@"%@",responseObject);
            [ProgressHUD dismiss];
            [[AppDelegate shared] setUser:nil];
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"user"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self.tabBarController.navigationController popToRootViewControllerAnimated:YES];
            
        }else{
            [ProgressHUD showError:[responseObject objectForKey:@"message"]];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [ProgressHUD showError:error.localizedFailureReason];
    }];
}

@end
