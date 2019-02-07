//
//  StreamViewController.m
//  Request Video
//
//  Created by NTechnosoft on 24/07/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import "StreamViewController.h"
#import <MapKit/MapKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import "MyVideoCell.h"
#import "MyCustomAnnotation.h"
#import "NSDate+TimeAgo.h"
#import "SearchViewController.h"
#import "TYPlaceSearchViewController.h"

@interface StreamViewController ()<MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource,UINavigationControllerDelegate, UIImagePickerControllerDelegate,CLLocationManagerDelegate, SearchDelegate,TYPlaceSearchViewControllerDelegate>{
    MyCustomAnnotation *selected;
    CLLocationManager *locationManager;
    CLLocation *last_location;
    NSArray *requests, *responses;
    AVPlayerViewController *playerController;
    NSURLSessionDataTask *task;
}
@property(nonatomic, strong)IBOutlet MKMapView *aMapView;
@property(nonatomic,weak)IBOutlet UITableView *aTableView;

@property(nonatomic, strong)IBOutlet UISegmentedControl *aSegment;
@property(nonatomic, strong)IBOutlet UISearchBar *aSearchBar;
@property(nonatomic, strong)IBOutlet UIView *requestPopup;
@property(nonatomic, strong)IBOutlet UIView *addRquestPopup, *addRequestForm;
@property(nonatomic, strong)IBOutlet UIView *responsePopup, *responseList;
@property(nonatomic, strong)IBOutlet UIActivityIndicatorView *Loading;
@property(nonatomic, strong)IBOutlet UIView *hintView;
@property(nonatomic, strong)IBOutlet UILabel *pin_address;
@property(nonatomic, strong)IBOutlet UITextField *place_name, *place_address;
@property(nonatomic, strong)IBOutlet UILabel *response_place_name, *response_place_address;
@property(nonatomic, strong)IBOutlet UITextView *addMessage, *pinMessage;

@end

@implementation StreamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    requests = [[NSArray alloc] init];
    responses = [[NSArray alloc] init];
    
    // Do any additional setup after loading the view.
    [AppDelegate shared].user = [[[NSUserDefaults standardUserDefaults] objectForKey:@"user"] mutableCopy];
    
    // Request Info Popup
    [self HidePopup:self];
    [self.tabBarController.navigationController.view addSubview:self.requestPopup];
    self.requestPopup.frame = [UIScreen mainScreen].bounds;

    // Add Request Popup
    [self HideRequestPopup:self];
    [self.tabBarController.navigationController.view addSubview:self.addRquestPopup];
    self.addRquestPopup.frame = [UIScreen mainScreen].bounds;
    [self addShadowToView:self.addRequestForm withRadius:10.0];
    
    // Response Videos Popup
    [self HideResponsePopup:self];
    [self.tabBarController.navigationController.view addSubview:self.responsePopup];
    self.responsePopup.frame = [UIScreen mainScreen].bounds;
    [self addShadowToView:self.responseList withRadius:10.0];
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0; //user needs to press for 2 seconds
    [self.aMapView addGestureRecognizer:lpgr];
    
    [self addShadowToView:self.hintView withRadius:5.0];
    
    [self HideView:self.hintView Animated:YES];
    
    locationManager = [[CLLocationManager alloc] init];
    [locationManager requestWhenInUseAuthorization];
    
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationManager startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [locationManager startUpdatingLocation];
    }];
    
}

- (void)viewDidAppear:(BOOL)animated{

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

#pragma mark - IBActions

- (IBAction)ToggleOptions:(UISegmentedControl *)sender{
    
    if(sender.selectedSegmentIndex == 0){
        self.tabBarItem.title = @"Streams";
        self.tabBarItem.image = [UIImage imageNamed:@"tab_streams.png"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"tab_streams.png"];
    }else{
        self.tabBarItem.title = @"Map";
        self.tabBarItem.image = [UIImage imageNamed:@"tab_replays.png"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"tab_replays.png"];
        [self HideView:self.hintView Animated:NO];
    }
    
    [self AddPins];
    
}

- (IBAction)AcceptRequest:(id)sender{
    [self HidePopup:sender];
    [self ShowVideoPicker];
}

- (IBAction)HidePopup:(id)sender{
    [self.requestPopup setHidden:YES];
}

- (IBAction)SendRequest:(id)sender{
    [self AddRequest];
}

- (IBAction)HideRequestPopup:(id)sender{
    [self.aMapView removeAnnotation:self.aMapView.annotations.lastObject];
    [self.addRquestPopup setHidden:YES];
}

- (IBAction)HideResponsePopup:(id)sender{
    responses = nil;
    [self.aTableView reloadData];
    [self.responsePopup setHidden:YES];
}

- (IBAction)reportVideo:(id)sender{
    NSDictionary *d = [responses objectAtIndex:[sender tag]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Report Abuse" message:@"Are you sure you want to report this video as inapproprate?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self ReportAbuse:[d objectForKey:@"response_id"]];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)showSearchBar:(id)sender{
    /*SearchViewController *search = [self.storyboard instantiateViewControllerWithIdentifier:@"Search_id"];
    search.Delegate = self;
    [self presentViewController:search animated:true completion:nil];
     */
    TYPlaceSearchViewController *searchViewController = [[TYPlaceSearchViewController alloc] init];
    searchViewController.location = last_location;
    [searchViewController setDelegate:self];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:searchViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
    
}

#pragma mark - MapView

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    if(self.aSegment.selectedSegmentIndex != 0)
        return;
    
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.aMapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [self.aMapView convertPoint:touchPoint toCoordinateFromView:self.aMapView];
    [self FindLocation:touchMapCoordinate];
}

- (void)FindLocation:(CLLocationCoordinate2D)coordinates{
    [ProgressHUD show:@"Loading Place"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%f,%f&radius=100&types=establishment&key=%@",coordinates.latitude,coordinates.longitude,Google_Api_Key] parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if([[responseObject objectForKey:@"results"] count] > 0){
            NSDictionary *d = [[responseObject objectForKey:@"results"] objectAtIndex:0];
            self.place_name.text = [d objectForKey:@"name"];
            self.place_address.text = [d objectForKey:@"vicinity"];
            selected = [[MyCustomAnnotation alloc] initWithTitle:[d objectForKey:@"name"] Location:coordinates Dictionary:@{@"name":@"hello"}];
            [ProgressHUD dismiss];
        }else{
            selected = [[MyCustomAnnotation alloc] initWithTitle:@"" Location:coordinates Dictionary:@{@"name":@"hello"}];
            [ProgressHUD showError:@"No places found. Please enter place name and address manually."];
        }
        [self.addRquestPopup setHidden:NO];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [ProgressHUD showError:error.localizedFailureReason];
    }];
}

- (void)AddPins{
    [self.aMapView removeAnnotations:self.aMapView.annotations];
    
    for(NSDictionary *request in requests){
        MyCustomAnnotation *annotation = [[MyCustomAnnotation alloc] initWithTitle:[request objectForKey:@"place_name"] Location:CLLocationCoordinate2DMake([[request objectForKey:@"latitude"] floatValue], [[request objectForKey:@"longitude"] floatValue]) Dictionary:request];
        [self.aMapView addAnnotation:annotation];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    if ([annotation isKindOfClass:[MyCustomAnnotation class]]) {
        
        MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"MyCustomAnnotation"];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MyCustomAnnotation"];
        } else {
            annotationView.annotation = annotation;
        }
        
        annotationView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",[self.aSegment titleForSegmentAtIndex:self.aSegment.selectedSegmentIndex].lowercaseString]];
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        
        return annotationView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    [mapView deselectAnnotation:view.annotation animated:NO];
    NSLog(@"Pin selected");
    
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        return;
    }
    
    selected = (MyCustomAnnotation *)view.annotation;
    
    if(self.aSegment.selectedSegmentIndex == 0){
        self.pin_address.text = [@"Request coming from\n" stringByAppendingString:[selected.dict objectForKey:@"user_location"]];
        self.pinMessage.text = [selected.dict objectForKey:@"message"];
        [self.requestPopup setHidden:NO];
    }else{
        [self.responsePopup setHidden:NO];
        self.response_place_name.text = [selected.dict objectForKey:@"place_name"];
        self.response_place_address.text = [selected.dict objectForKey:@"user_location"];
        [self GetResponses];
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    last_location = [locations lastObject];
    [manager stopUpdatingLocation];
    [self GetStreams];
    self.aMapView.region  = MKCoordinateRegionMakeWithDistance(last_location.coordinate, 10000, 10000);
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return responses.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 110;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *Identifier = @"MyVideoCell";
    
    MyVideoCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    
    NSDictionary *d = [responses objectAtIndex:indexPath.row];
    
    [cell.videoThumb sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",VIDEO_THUMB_PATH,[[d objectForKey:@"video"] stringByReplacingOccurrencesOfString:@".mp4" withString:@".jpg"]]] placeholderImage:[UIImage imageNamed:@"video.png"]];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [df dateFromString:[self ServerDateToLocalDate:[d objectForKey:@"created_at"] serverTimeZone:@"America/Phoenix"]];
    cell.time.text = [date timeAgo];
    cell.name.text = ([[d objectForKey:@"name"] isEqualToString:@""]?@"Unknown":[d objectForKey:@"name"]);
    
    cell.report.tag = indexPath.row;
    [cell.report addTarget:self action:@selector(reportVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *d = [responses objectAtIndex:indexPath.row];
    AVPlayer *player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:[VIDEO_PATH stringByAppendingPathComponent:[d objectForKey:@"video"]]]];
    playerController = [[AVPlayerViewController alloc] init];
    playerController.player = player;
    playerController.showsPlaybackControls = YES;
    [self presentViewController:playerController animated:YES completion:^{
        [player play];
    }];
}

#pragma mark - Utility

- (void)HideView:(UIView *)view Animated:(BOOL)animated{
    if(animated == YES){
        [UIView animateWithDuration:0.6 delay:6.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [view setAlpha:0.0];
        } completion:nil];
    }else{
        [view setAlpha:0.0];
    }
}

- (void)addShadowToView:(UIView *)viewCheck withRadius:(CGFloat)radius{
    viewCheck.layer.shadowRadius  = 1.5f;
    viewCheck.layer.shadowColor   = [UIColor lightGrayColor].CGColor;
    viewCheck.layer.shadowOffset  = CGSizeMake(0.0f, 1.0f);
    viewCheck.layer.shadowOpacity = 0.5f;
    viewCheck.layer.cornerRadius  = radius;
    viewCheck.layer.masksToBounds = NO;
}

- (NSString *)ServerDateToLocalDate:(NSString *)serverDate serverTimeZone:(NSString *)serverTimezone{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [df setTimeZone:[NSTimeZone timeZoneWithName:serverTimezone]]; // Can be set to @"UTC"
    
    NSDate *date = [df dateFromString:serverDate];
    
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [df setTimeZone:[NSTimeZone systemTimeZone]]; //// Can be set to [NSTimeZone localTimeZone]
    
    return [df stringFromDate:date];
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

- (void)ShowAlertWithTitle:(NSString *)title Message:(NSString *)message{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIImagePicker

- (void)ShowVideoPicker{
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.mediaTypes = [NSArray arrayWithObjects:(NSString *) kUTTypeMovie,nil];
    picker.sourceType = sourceType;
    picker.videoMaximumDuration = 15;
    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:^{
        NSURL *movieURL = (NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
        [self saveVideoToLocal:movieURL];
    }];
}

- (void) saveVideoToLocal:(NSURL *)videoURL {
    [ProgressHUD show:@"Processing"];
    @try {
        NSArray *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docPath = [documentsDirectory objectAtIndex:0];
        
        NSString *videoName = [NSString stringWithFormat:@"sampleVideo.mp4"];
        NSString *videoPath = [docPath stringByAppendingPathComponent:videoName];
        
        NSURL *outputURL = [NSURL fileURLWithPath:videoPath];
        
        NSLog(@"Loading video");
        
        [self convertVideoToLowQuailtyWithInputURL:videoURL outputURL:outputURL handler:^(AVAssetExportSession *exportSession) {
            
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                NSLog(@"Compression is done");
                [self performSelectorOnMainThread:@selector(AddResponseVideo:) withObject:exportSession.outputURL waitUntilDone:YES];
            }else{
                [ProgressHUD showError:exportSession.error.localizedFailureReason];
            }
        }];
    }
    @catch (NSException *exception) {
        [ProgressHUD showError:exception.reason];
    }
}

- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL outputURL:(NSURL*)outputURL handler:(void (^)(AVAssetExportSession*))handler {
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        handler(exportSession);
    }];
}

#pragma mark - SearchViewController

- (void)SearchViewControllerDismissed:(NSDictionary *)d{
   
    self.place_name.text = [d objectForKey:@"name"];
    self.place_address.text = [d objectForKey:@"vicinity"];
    selected = [[MyCustomAnnotation alloc] initWithTitle:[d objectForKey:@"name"] Location:CLLocationCoordinate2DMake([[d objectForKey:@"lat"] floatValue], [[d objectForKey:@"lng"] floatValue]) Dictionary:d];
    [self.addRquestPopup setHidden:NO];
    MKCoordinateRegion region;
    region.center=CLLocationCoordinate2DMake([[d objectForKey:@"lat"] floatValue], [[d objectForKey:@"lng"] floatValue]);
    MKCoordinateSpan span;
    span.latitudeDelta=10.015; // Vary as you need the View for
    span.longitudeDelta=10.015;
    region.span=span;
    [self.aMapView setRegion:region];
}

- (void)searchViewController:(TYPlaceSearchViewController *)controller didReturnPlace:(TYGooglePlace *)place{
    NSDictionary *d = @{@"name":place.name,@"vicinity":place.formatted_address,@"lat":[NSNumber numberWithFloat:place.location.coordinate.latitude],@"lng": [NSNumber numberWithFloat:place.location.coordinate.longitude]};
    
    self.place_name.text = [d objectForKey:@"name"];
    self.place_address.text = [d objectForKey:@"vicinity"];
    
    selected = [[MyCustomAnnotation alloc] initWithTitle:[d objectForKey:@"name"] Location:CLLocationCoordinate2DMake([[d objectForKey:@"lat"] floatValue], [[d objectForKey:@"lng"] floatValue]) Dictionary:d];
    [self.addRquestPopup setHidden:NO];
    MKCoordinateRegion region;
    region.center=CLLocationCoordinate2DMake([[d objectForKey:@"lat"] floatValue], [[d objectForKey:@"lng"] floatValue]);
    MKCoordinateSpan span;
    span.latitudeDelta=10.015; // Vary as you need the View for
    span.longitudeDelta=10.015;
    region.span=span;
    [self.aMapView setRegion:region];
    //NSLog(@"%@",place);
}

#pragma mark - SearchBar

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    [searchBar setShowsCancelButton:YES];
}
    
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [searchBar setShowsCancelButton:NO];
    [searchBar resignFirstResponder];
    searchBar.text = nil;
    [self GetStreams];
    self.aMapView.region  = MKCoordinateRegionMakeWithDistance(last_location.coordinate, 10000, 10000);
}
    
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self GetSearch:searchBar.text];
    [searchBar resignFirstResponder];
}

#pragma mark  - Webservice

- (void)AddRequest{
    
    if([self.place_name.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0){
        [self ShowAlertWithTitle:@"Required" Message:@"Please enter place name"];
    }else if([self.place_address.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0){
        [self ShowAlertWithTitle:@"Required" Message:@"Please enter place address"];
    }else{
        //NSLog(@"%@",ADD_REQUEST);
        [ProgressHUD show:@"Loading"];
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
        [manager.requestSerializer setValue:[[AppDelegate shared].user objectForKey:@"Authentication"] forHTTPHeaderField:@"Authentication"];
        [manager POST:ADD_REQUEST parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            
            [formData appendPartWithFormData:[[NSString stringWithFormat:@"%f",selected.coordinate.latitude] dataUsingEncoding:NSUTF8StringEncoding] name:@"latitude"];
            [formData appendPartWithFormData:[[NSString stringWithFormat:@"%f",selected.coordinate.longitude] dataUsingEncoding:NSUTF8StringEncoding] name:@"longitude"];
            [formData appendPartWithFormData:[self.place_name.text dataUsingEncoding:NSUTF8StringEncoding] name:@"place_name"];
            [formData appendPartWithFormData:[self.place_address.text dataUsingEncoding:NSUTF8StringEncoding] name:@"user_location"];
            [formData appendPartWithFormData:[self.addMessage.text dataUsingEncoding:NSUTF8StringEncoding] name:@"message"];
            
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"%@",responseObject);
            if([[responseObject objectForKey:@"status"] integerValue] == 1){
                [ProgressHUD dismiss];
                [self.addRquestPopup setHidden:YES];
                [self GetStreams];
            }else{
                [ProgressHUD showError:[responseObject objectForKey:@"message"]];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [ProgressHUD showError:error.localizedFailureReason];
        }];
    }
}

- (void)AddResponseVideo:(NSURL *)movieURL{
    
    [ProgressHUD show:@"Uploading"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager.requestSerializer setValue:[[AppDelegate shared].user objectForKey:@"Authentication"] forHTTPHeaderField:@"Authentication"];
    [manager POST:ADD_RESPONSE parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        AVAsset *asset = [AVAsset assetWithURL:movieURL];
        AVAssetImageGenerator *assetImageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        assetImageGenerator.appliesPreferredTrackTransform = YES;
        CMTime time = asset.duration;
        time.value = MIN(time.value, 2);
        CGImageRef ref = [assetImageGenerator copyCGImageAtTime:time actualTime:nil error:nil];
        UIImage *thumb = [self fixrotation:[UIImage imageWithCGImage:ref]];
        
        [formData appendPartWithFormData:[[selected.dict objectForKey:@"request_id"] dataUsingEncoding:NSUTF8StringEncoding] name:@"request_id"];
        
        [formData appendPartWithFileData:UIImageJPEGRepresentation(thumb, 1.0) name:@"thumb" fileName:@"pic.jpg" mimeType:@"image/jpeg"];
        
        [formData appendPartWithFileURL:movieURL name:@"attachment" error:nil];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [ProgressHUD show:[NSString stringWithFormat:@"Uploading\n%.0f%%",uploadProgress.fractionCompleted*100]];
            //Run UI Updates
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if([[responseObject objectForKey:@"status"] integerValue] == 1){
            NSLog(@"%@",responseObject);
            [ProgressHUD dismiss];
        }else{
            [ProgressHUD showError:[responseObject objectForKey:@"message"]];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [ProgressHUD showError:error.localizedFailureReason];
    }];
}

- (void)GetStreams{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager.requestSerializer setValue:[[AppDelegate shared].user objectForKey:@"Authentication"] forHTTPHeaderField:@"Authentication"];
    [manager POST:GET_STREAMS parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [formData appendPartWithFormData:[[NSString stringWithFormat:@"%f",last_location.coordinate.latitude] dataUsingEncoding:NSUTF8StringEncoding] name:@"lat"];
        [formData appendPartWithFormData:[[NSString stringWithFormat:@"%f",last_location.coordinate.longitude] dataUsingEncoding:NSUTF8StringEncoding] name:@"lng"];
        [formData appendPartWithFormData:[@"10" dataUsingEncoding:NSUTF8StringEncoding] name:@"range"];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@",responseObject);
        if([[responseObject objectForKey:@"status"] integerValue] == 1){
            requests = [responseObject objectForKey:@"Get_data"];
            [self AddPins];
        }else{
            [ProgressHUD showError:[responseObject objectForKey:@"message"]];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [ProgressHUD showError:error.localizedFailureReason];
    }];
}

- (void)GetSearch:(NSString *)keyword{
    
    if (task != nil){
        [task cancel];
    }
    
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
        [manager.requestSerializer setValue:[[AppDelegate shared].user objectForKey:@"Authentication"] forHTTPHeaderField:@"Authentication"];
        task = [manager POST:GET_SEARCH     parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            
            [formData appendPartWithFormData:[keyword dataUsingEncoding:NSUTF8StringEncoding] name:@"keyword"];
            
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"%@",responseObject);
            if([[responseObject objectForKey:@"status"] integerValue] == 1){
                requests = [responseObject objectForKey:@"Get_data"];
                if (requests.count > 0){
                    NSDictionary *d = [requests objectAtIndex:0];
                    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([[d objectForKey:@"latitude"] floatValue], [[d objectForKey:@"longitude"] floatValue]);
                    MKCoordinateRegion region;
                    region.center=coordinate;
                    MKCoordinateSpan span;
                    span.latitudeDelta=10.015; // Vary as you need the View for
                    span.longitudeDelta=10.015;
                    region.span=span;
                    [self.aMapView setRegion:region];
                    [self AddPins];
                }
            }else{
                [ProgressHUD showError:[responseObject objectForKey:@"message"]];
                [self.aMapView removeOverlays:self.aMapView.overlays];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"Error : %@",error.localizedFailureReason);
           // [ProgressHUD showError:error.localizedFailureReason];
        }];
}
    
    
- (void)GetResponses{
    [self.Loading startAnimating];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager.requestSerializer setValue:[[AppDelegate shared].user objectForKey:@"Authentication"] forHTTPHeaderField:@"Authentication"];
    [manager POST:GET_RESPONSES parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [formData appendPartWithFormData:[[selected.dict objectForKey:@"request_id"] dataUsingEncoding:NSUTF8StringEncoding] name:@"request_id"];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@",responseObject);
        [self.Loading stopAnimating];
        if([[responseObject objectForKey:@"status"] integerValue] == 1){
            responses = [responseObject objectForKey:@"Get_data"];
            [self.aTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }else{
            [ProgressHUD showError:[responseObject objectForKey:@"message"]];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.Loading stopAnimating];
        [ProgressHUD showError:error.localizedFailureReason];
    }];
}

- (void)ReportAbuse:(NSString *)response_id
{
    [ProgressHUD show:@"Loading"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager.requestSerializer setValue:[[AppDelegate shared].user objectForKey:@"Authentication"] forHTTPHeaderField:@"Authentication"];
    [manager POST:REPORT_ABUSE parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [formData appendPartWithFormData:[response_id dataUsingEncoding:NSUTF8StringEncoding] name:@"response_id"];
        [formData appendPartWithFormData:[@"This video contains explicit content." dataUsingEncoding:NSUTF8StringEncoding] name:@"details"];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@",responseObject);
        if([[responseObject objectForKey:@"status"] integerValue] == 1){
            [ProgressHUD showSuccess:@"Thank you for your feedback. We will check the video and take necessary action within 48 hours."];
        }else{
            [ProgressHUD showError:[responseObject objectForKey:@"message"]];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [ProgressHUD showError:error.localizedFailureReason];
    }];
}

@end
