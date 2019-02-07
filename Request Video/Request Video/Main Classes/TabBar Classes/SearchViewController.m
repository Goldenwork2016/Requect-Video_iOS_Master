//
//  SearchViewController.m
//  Request Video
//
//  Created by MEHUL on 22/11/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import "SearchViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface SearchViewController ()<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>{
    NSMutableArray *display;
    NSURLSessionDataTask *task;
}
@property(nonatomic, weak)IBOutlet UITableView *aTableView;
@property(nonatomic, weak)IBOutlet UISearchBar *aSearchBar;
@end

@implementation SearchViewController

@synthesize Delegate = _Delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    display = [[NSMutableArray alloc] init];
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

- (IBAction)Cancel:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - UISearchBar

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    [searchBar setShowsCancelButton:YES];
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [searchBar setShowsCancelButton:NO];
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    
    if (searchText.length > 0){
        [self GetSearch:searchText];
    }else{
        [display removeAllObjects];
        [self.aTableView reloadData];
    }
}

- (void)GetSearch:(NSString *)keyword{
    
    if (task != nil){
        [task cancel];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager.requestSerializer setValue:[[AppDelegate shared].user objectForKey:@"Authentication"] forHTTPHeaderField:@"Authentication"];
    task = [manager POST:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/textsearch/json?query=%@&language=en&key=%@",[keyword stringByReplacingOccurrencesOfString:@" " withString:@"+"],Google_Api_Key] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        //[formData appendPartWithFormData:[keyword dataUsingEncoding:NSUTF8StringEncoding] name:@"query"];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [display removeAllObjects];
        NSLog(@"%@",responseObject);
        
        for (NSDictionary *d in [responseObject objectForKey:@"results"]){
            [display addObject:@{@"name":[d objectForKey:@"name"],@"vicinity":[d objectForKey:@"formatted_address"],@"lat":[[[d objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"],@"lng": [[[d objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"]}];
        }
        [self.aTableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error : %@",error.localizedFailureReason);
    }];
}


#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return display.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *Identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if(cell  == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:Identifier];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = [[display objectAtIndex:indexPath.row] objectForKey:@"name"];
    cell.detailTextLabel.text = [[display objectAtIndex:indexPath.row] objectForKey:@"vicinity"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self dismissViewControllerAnimated:YES completion:^{
        if([self.Delegate respondsToSelector:@selector(SearchViewControllerDismissed:)]){
            [self.Delegate SearchViewControllerDismissed:[display objectAtIndex:indexPath.row]];
        }
    }];
}


@end
