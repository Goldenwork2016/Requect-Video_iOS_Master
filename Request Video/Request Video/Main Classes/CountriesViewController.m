//
//  CountriesViewController.m
//  Request Video
//
//  Created by NTechnosoft on 28/07/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import "CountriesViewController.h"

@interface CountriesViewController ()<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>{
    NSArray *countries;
    NSMutableArray *display;
    NSDictionary *selected;
}
@property(nonatomic, weak)IBOutlet UITableView *aTableView;
@property(nonatomic, weak)IBOutlet UISearchBar *aSearchBar;
@end

@implementation CountriesViewController

@synthesize Delegate = _Delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    countries = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"country" ofType:@"plist"]];
    display = [[NSMutableArray alloc] init];
    [self filter];
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

- (void)filter{
    [display removeAllObjects];
    if([self.aSearchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0){
        [display addObjectsFromArray:countries];
    }else{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[c] %@",self.aSearchBar.text];
        [display removeAllObjects];
        [display addObjectsFromArray:[countries filteredArrayUsingPredicate:predicate]];
    }
    [self.aTableView reloadData];
}

- (IBAction)Done:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^{
        if([self.Delegate respondsToSelector:@selector(CountriesViewControllerDismissed:)]){
            [self.Delegate CountriesViewControllerDismissed:selected];
        }
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

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    [self performSelector:@selector(filter) withObject:nil afterDelay:0.2];
    return YES;
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = [[display objectAtIndex:indexPath.row] objectForKey:@"name"];
    if([[display objectAtIndex:indexPath.row] isEqual:selected]){
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    selected = [display objectAtIndex:indexPath.row];
    [tableView reloadData];
}

@end
