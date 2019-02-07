//
//  MyViewController.m
//  Request Video
//
//  Created by NTechnosoft on 24/07/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import "MyViewController.h"
#import "MyVideoCell.h"
#import "NSDate+TimeAgo.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MyViewController ()<UITableViewDelegate, UITableViewDataSource>{
    NSArray *requests, *responses;
    AVPlayerViewController *playerController;
    NSURLSessionDataTask *task;
}
@property(nonatomic,weak)IBOutlet UITableView *aTableView;
@property(nonatomic, strong)IBOutlet UISegmentedControl *aSegment;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [self GetVideos:(self.aSegment.selectedSegmentIndex == 0?MY_VIDEO:VIDEO_FOR_ME)];
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

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return (self.aSegment.selectedSegmentIndex == 0?requests.count:responses.count);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 110;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *Identifier = @"MyVideoCell";
    
    MyVideoCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    
    NSDictionary *d;
    if(self.aSegment.selectedSegmentIndex == 0){
        d =  [requests objectAtIndex:indexPath.row];
        cell.name.text = ([[d objectForKey:@"name"] isEqualToString:@""]?@"Me":[d objectForKey:@"name"]);
        cell.report.hidden = YES;
    }else{
        d =  [responses objectAtIndex:indexPath.row];
        cell.name.text = ([[d objectForKey:@"name"] isEqualToString:@""]?@"Unknown":[d objectForKey:@"name"]);
        cell.report.tag = indexPath.row;
        [cell.report addTarget:self action:@selector(reportVideo:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [cell.videoThumb sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",VIDEO_THUMB_PATH,[[d objectForKey:@"video"] stringByReplacingOccurrencesOfString:@".mp4" withString:@".jpg"]]] placeholderImage:[UIImage imageNamed:@"video.png"]];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [df dateFromString:[self ServerDateToLocalDate:[d objectForKey:@"created_at"] serverTimeZone:@"America/Phoenix"]];
    cell.time.text = [date timeAgo];
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *d;
    if(self.aSegment.selectedSegmentIndex == 0){
        d =  [requests objectAtIndex:indexPath.row];
    }else{
        d =  [responses objectAtIndex:indexPath.row];
    }
    AVPlayer *player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:[VIDEO_PATH stringByAppendingPathComponent:[d objectForKey:@"video"]]]];
    playerController = [[AVPlayerViewController alloc] init];
    playerController.player = player;
    playerController.showsPlaybackControls = YES;
    [self presentViewController:playerController animated:YES completion:nil];
}

#pragma mark - IBActions

- (IBAction)ToggleOptions:(UISegmentedControl *)sender{
    [self GetVideos:(self.aSegment.selectedSegmentIndex == 0?MY_VIDEO:VIDEO_FOR_ME)];
    [self.aTableView reloadData];
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

#pragma mark - WebService

- (void)GetVideos:(NSString *)webservice{
    
    if(task){
        [task cancel];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager.requestSerializer setValue:[[AppDelegate shared].user objectForKey:@"Authentication"] forHTTPHeaderField:@"Authentication"];
    task = [manager POST:webservice parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {

    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@",responseObject);
        if([[responseObject objectForKey:@"status"] integerValue] == 1){
            if(self.aSegment.selectedSegmentIndex == 0){
                requests = [responseObject objectForKey:@"Get_data"];
            }else{
                responses = [responseObject objectForKey:@"Get_data"];
            }
            [self.aTableView reloadData];
        }else{
            [ProgressHUD showError:[responseObject objectForKey:@"message"]];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
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


#pragma mark  - Utility

- (NSString *)ServerDateToLocalDate:(NSString *)serverDate serverTimeZone:(NSString *)serverTimezone{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [df setTimeZone:[NSTimeZone timeZoneWithName:serverTimezone]]; // Can be set to @"UTC"
    
    NSDate *date = [df dateFromString:serverDate];
    
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [df setTimeZone:[NSTimeZone systemTimeZone]]; //// Can be set to [NSTimeZone localTimeZone]
    
    return [df stringFromDate:date];
}

- (NSString *)LocalDateToServerDate:(NSString *)localDate serverTimeZone:(NSString *)serverTimezone{
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [df setTimeZone:[NSTimeZone systemTimeZone]]; // Can be set to @"UTC"
    
    NSDate *date = [df dateFromString:localDate];
    
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [df setTimeZone:[NSTimeZone timeZoneWithName:serverTimezone]];
    
    return [df stringFromDate:date];
}

@end
